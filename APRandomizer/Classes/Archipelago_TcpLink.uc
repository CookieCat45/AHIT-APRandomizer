class Archipelago_TcpLink extends TcpLink
	dependson(Archipelago_ItemInfo);

`include(APRandomizer\Classes\Globals.uci);

var string TargetHost;
var int TargetPort;

var transient string CurrentMessage;
var transient int BracketCounter;
var transient bool ParsingMessage;
var transient bool ConnectingToAP;
var transient bool FullyConnected;

const MaxSentMessageLength = 246;

event PostBeginPlay()
{
	Super.PostBeginPlay();
	Connect();
}

function Connect()
{
	`AP.ScreenMessage("Connecting to host: "$TargetHost$":"$TargetPort);
    Resolve(TargetHost);
}

event Resolved(IpAddr Addr)
{
    Addr.Port = TargetPort;
    BindPort();
	
    if (!Open(Addr))
    {
        `AP.ScreenMessage("Failed to open connection to "$TargetHost$":"$TargetPort $", retrying...");
		SetTimer(5.0, false, NameOf(Connect));
    }
}

event ResolveFailed()
{
    `AP.ScreenMessage("Unable to resolve "$TargetHost$":"$TargetPort $". Retrying in 5 seconds...");
	SetTimer(5.0, false, NameOf(Connect));
}

event Opened()
{
	local string crlf;
	
	crlf = chr(13)$chr(10);
	LinkMode = MODE_Line;
	ReceiveMode = RMODE_Event;
	
	// send HTTP request to server to upgrade to websocket connection
	SendText("GET / HTTP/1.1" $crlf
	$"Host: " $TargetHost $crlf
	$"Connection: keep-alive, Upgrade" $crlf
	$"Upgrade: websocket" $crlf
	$"Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" $crlf
	$"Sec-WebSocket-Version: 13" $crlf
	$"Accept: /" $crlf);
}

// this should be our HTTP response from the server
event ReceivedLine(string message)
{
	ReceiveMode = RMODE_Manual;
	
	if (!FullyConnected && !ConnectingToAP)
	{
		ConnectToAP();
	}
}

function ConnectToAP()
{
	local JsonObject json;
	local JsonObject jsonVersion;
	local string message;
	
	ConnectingToAP = true;
	CurrentMessage = "";

	json = new class'JsonObject';
	json.SetStringValue("cmd", "Connect");
	json.SetStringValue("game", "A Hat in Time");
	json.SetStringValue("name", "CookieHat");
	json.SetStringValue("password", "");
	json.SetStringValue("uuid", "");
	json.SetStringValue("tags", "");
	json.SetIntValue("items_handling", 7);
	json.SetBoolValue("slot_data", true);
	
	jsonVersion = new class'JsonObject';
	jsonVersion.SetStringValue("major", "0");
	jsonVersion.SetStringValue("minor", "4");
	jsonVersion.SetStringValue("build", "0");
	jsonVersion.SetStringValue("class", "Version");
	json.SetObject("version", jsonVersion);
	
	message = class'JsonObject'.static.EncodeJson(json);
	message = "["$message$"]";
	SendBinaryMessage(message);
	
	ClearTimer(NameOf(TimedOut));
	SetTimer(5.0, false, NameOf(TimedOut));
}

function TimedOut()
{
	if (!FullyConnected && ConnectingToAP)
	{
		`AP.ScreenMessage("Connection attempt timed out. Closing connection...");
		ConnectingToAP = false;
		Close();
	}
}

event Tick(float d)
{
	local byte byteMessage[255];
	local int count;
	local int i;
	local string character;
	
	// Messages from the AP server are not null-terminated, so it must be done this way. 
	// We can only read 255 bytes from the socket at a time.
	if (IsDataPending())
	{
		count = ReadBinary(255, byteMessage);
		
		if (count > 0)
		{
			for (i = 0; i < count; i++)
			{
				character = Chr(byteMessage[i]);
				CurrentMessage $= character;
				
				if (character == "[")
				{
					if (ParsingMessage)
					{
						BracketCounter--;
					}
					else // This is the beginning of a JSON message
					{
						CurrentMessage = "[";
						ParsingMessage = true;
					}
				}
				else if (character == "]")
				{
					BracketCounter++;
					if (BracketCounter > 0)
					{
						// We've got a JSON message, parse it
						ParseJSON(CurrentMessage);
						
						CurrentMessage = "";
						BracketCounter = 0;
						ParsingMessage = false;
					}
				}
			}
		}
		else if (Len(CurrentMessage) > 0) // See if we can parse a message anyway
		{
			ParseJSON(CurrentMessage);
			ClearDataBuffer();
		}
	}
	
	Super.Tick(d);
}

// for clearing leftover unread data on the socket, usually on level change
function ClearDataBuffer()
{
	local int count;
	local byte byteArray[255];
	do
	{
		count = ReadBinary(255, byteArray);
	} until (count <= 1);
	
	CurrentMessage = "";
	BracketCounter = 0;
	ParsingMessage = false;
}

function ParseJSON(string json)
{
	local bool b;
	local int i;
	local int count;
	local string s, message;
	local JsonObject jsonObj;
	local JsonObject jsonChild;
	
	//`AP.DebugMessage("[ParseJSON] Received command: " $json);
		
	// UnrealScript's JSON parser does not like []
	json = Repl(json, "[{", "{");
	json = Repl(json, "}]", "}");
	
	//`AP.DebugMessage("[ParseJSON] Reformatted command: " $json);
	
	jsonObj = new class'JsonObject';
	jsonObj = class'JsonObject'.static.DecodeJson(json);
	if (jsonObj == None)
	{
		`AP.DebugMessage("[ParseJSON] Failed to parse JSON: " $json);
		return;
	}
	
	switch (jsonObj.GetStringValue("cmd"))
	{
		case "Connected":
			`AP.ScreenMessage("Successfully connected to "$TargetHost$":"$TargetPort);
			`AP.PlayerSlot = jsonObj.GetIntValue("slot");
			FullyConnected = true;
			ConnectingToAP = false;

			jsonChild = jsonObj.GetObject("slot_data");
			`AP.LoadSlotData(jsonChild);
			
			// sometimes this command will be paired with ReceivedItems
			if (InStr(json, "{\"cmd\":\"ReceivedItems\"") != -1)
			{
				OnReceivedItemsCommand(Split(json, "{\"cmd\":\"ReceivedItems\""), true);
			}
			
			// Initialize our player's names
			`AP.PlayerNames.Length = 0;
			`AP.ReplOnce(json, "players", "players_0", json, true);
			b = true;
			count = 0;
			
			while (b)
			{
				if (`AP.ReplOnce(json, ",{", ",\"players_"$count+1 $"\":{", s, false))
				{
					json = s;
					count++;
				}
				else
				{
					b = false;
				}
			}
			
			jsonObj = class'JsonObject'.static.DecodeJson(json);
			for (i = 0; i <= count; i++)
			{
				jsonChild = jsonObj.GetObject("players_"$i);
				if (jsonChild == None)
					continue;
					
				`AP.PlayerNames[jsonChild.GetIntValue("slot")] = jsonChild.GetStringValue("alias");
			}
			
			OnFullyConnected();
			break;
			
			
		case "PrintJSON":
			jsonChild = jsonObj.GetObject("data");
			
			if (jsonChild != None)
			{
				if (InStr(json, "\"type\":") != -1)
				{
					break;
				}
				else
				{
					message = jsonChild.GetStringValue("text");
				}
				
				`AP.ScreenMessage(message);
			}
			break;
			
			
		case "ConnectionRefused":
			ConnectingToAP = false;
			`AP.ScreenMessage("Connection refused by server. Check to make sure your slot name, password, etc. are correct.");
			break;
		
		
		case "ReceivedItems":
			OnReceivedItemsCommand(json);
			break;
		
		
		case "LocationInfo":
			OnLocationInfoCommand(json);
			break;
		

		case "Bounce":
			OnBounceCommand(json);
			break;
			
			
		default:
			break;
	}
}

function OnFullyConnected()
{
	local Hat_TreasureChest_Base chest;

	foreach DynamicActors(class'Hat_TreasureChest_Base', chest)
	{
		chest.DontSave = false;
	}
}

function OnLocationInfoCommand(string json)
{
	local bool b;
	local int count;
	local JsonObject jsonObj;
	local JsonObject jsonChild;
	local int i;
	local string s;
	local int itemId;
	local int locId;
	local Archipelago_RandomizedItem_Base item;
	local Hat_Collectible_Important collectible;
	local string itemName;
	local string timePieceId;
	local class worldClass;
	local class<Archipelago_BadgeSalesmanItem_Base> shopItemClass;
	
	`AP.ReplOnce(json, "locations", "locations_0", json, true);
	b = true;
	count = 0;
	
	while (b)
	{
		if (`AP.ReplOnce(json, ",{", ",\"locations_"$count+1 $"\":{", s, false))
		{
			json = s;
			count++;
		}
		else
		{
			b = false;
		}
	}
	
	jsonObj = class'JsonObject'.static.DecodeJson(json);
	
	for (i = 0; i <= count; i++)
	{
		jsonChild = jsonObj.GetObject("locations_"$i);
		if (jsonChild == None)
			continue;
		
		shopItemClass = `AP.GetShopItemClassFromLocation(jsonChild.GetIntValue("location"));
		if (shopItemClass != None)
		{
			if (!`AP.DoesShopItemInfoExist(shopItemClass))
			{
				`AP.CreateShopItemInfo(shopItemClass, jsonChild.GetIntValue("item"));
			}
		}
		else
		{
			foreach DynamicActors(class'Hat_Collectible_Important', collectible)
			{
				if (collectible.IsA('Hat_Collectible_VaultCode_Base') || collectible.IsA('Hat_Collectible_InstantCamera'))
					continue;
				
				locId = `AP.ObjectToLocationId(collectible);
				if (locId == jsonChild.GetIntValue("location"))
				{
					itemId = jsonChild.GetIntValue("item");
					b = class'Archipelago_ItemInfo'.static.GetNativeItemData(itemId, itemName, worldClass);
					
					if (!b) // not a regular item
					{
						timePieceId = class'Archipelago_ItemInfo'.static.GetTimePieceFromItemID(itemId, , itemName);
						
						if (timePieceId != "")
						{
							worldClass = class'Archipelago_RandomizedItem_TimeObject';
						}
						else
						{
							// belongs to another game that isn't A Hat in Time
							worldClass = class'Archipelago_RandomizedItem_Misc';
						}
					}
				
					item = Archipelago_RandomizedItem_Base(Spawn(class<Actor>(worldClass), , , collectible.Location, , , true));
					
					if (worldClass != class'Archipelago_RandomizedItem_Misc')
					{
						item.ItemDisplayName = itemName;
					}
					else
					{
						switch (jsonChild.GetIntValue("flags"))
						{
							case ItemFlag_Important:
								item.ItemDisplayName = "AP Item - Important"; 
								break;
								
							case ItemFlag_ImportantSkipBalancing:
								item.ItemDisplayName = "AP Item - Important"; 
								break;
							
							case ItemFlag_Useful: 
								item.ItemDisplayName = "AP Item - Useful"; 
								break;
							
							default: 
								item.ItemDisplayName = "AP Item"; 
								break;
						}
					}
					
					item.OriginalCollectibleName = class'Hat_SaveBitHelper'.static.GetCorrectedMapFilename(string(collectible.GetLevelName()))$"."$collectible.Name;
					collectible.Destroy(); // now we can get rid of this
					
					item.LocationId = locId;
					item.ItemId = itemId;
					item.ItemFlags = jsonChild.GetIntValue("flags");
					item.ItemOwner = jsonChild.GetIntValue("player");
					item.OwnItem = (`AP.PlayerSlot == item.ItemOwner);
					
					item.Init();
				}
			}
		}		
	}
}

function OnReceivedItemsCommand(string json, optional bool connection)
{
	local int count, index, total, i, id, isAct, start;
	local string timePieceId, timePieceName, s;
	local JsonObject jsonObj, jsonChild;
	local bool b;

	`AP.ReplOnce(json, "items", "items_0", json, true);
	b = true;
	count = 0;
	
	while (b)
	{
		if (`AP.ReplOnce(json, ",{", ",\"items_"$ count+1 $"\":{", s, false))
		{
			json = s;
			count++;
		}
		else
		{
			b = false;
		}
	}
	
	jsonObj = class'JsonObject'.static.DecodeJson(json);
	index = `AP.GetAPBits(`AP.LastItemBit);
	
	// This means we are reconnecting to a previous session, and the server is giving us our entire list of items,
	// so we need to begin from the next new item in our list or don't give anything otherwise
	if (connection)
	{
		if (index > count)
			return;
		else
			start = index;
	}
	else
	{
		start = 0;
	}
	
	for (i = start; i <= count; i++)
	{
		jsonChild = jsonObj.GetObject("items_"$i);
		if (jsonChild != None)
		{
			id = jsonChild.GetIntValue("item");
			timePieceId = class'Archipelago_ItemInfo'.static.GetTimePieceFromItemID(id, isAct, timePieceName);

			if (timePieceId != "") // Time Piece?
			{
				GrantTimePiece(timePieceId, bool(isAct), timePieceName);
			}	
			else
			{
				// regular item
				GrantItem(id);
			}
				
			total++;
		}
	}
	
	`AP.SetAPBits(`AP.LastItemBit, index+total);
}

function GrantTimePiece(string timePieceId, bool IsAct, string itemName)
{
	local Archipelago_RandomizedItem_Base item;
	local Pawn player;
	
	player = GetALocalPlayerController().Pawn;
	
	item = Spawn(class'Archipelago_RandomizedItem_TimeObject', , , player.Location, , , true);
	item.PickupActor = player;
	item.OnCollected(player);
	
	`AP.ScreenMessage("Got Time Piece: " $itemName);
	
	// Tell AP to stop removing this Time Piece in OnTimePieceCollected()
	`AP.SetAPBits(timePieceId, 1);
	`SaveManager.GetCurrentSaveData().GiveTimePiece(timePieceId, IsAct);
	
	if (`AP.IsInSpaceship() && `AP.SlotData.Initialized)
	{
		`AP.UpdateActUnlocks();
		`AP.UpdatePowerPanels();
	}
}

function GrantItem(int itemId)
{
	local class worldClass;
	local class invOverride;
	local string itemName;
	local Archipelago_RandomizedItem_Base item;
	local Pawn player;
	local ESpecialItemType special;
	local ETrapType trap;
	
	if (class'Archipelago_ItemInfo'.static.GetNativeItemData(itemId, itemName, worldClass, invOverride))
	{
		player = GetALocalPlayerController().Pawn;
		item = Spawn(class<Archipelago_RandomizedItem_Base>(worldClass), , , player.Location, , , true);
		if (item != None)
		{
			if (invOverride != None) // override? (probably a relic)
				item.InventoryClass = invOverride;
		
			item.PickupActor = player;
			item.OnCollected(player);
		}
		else
		{
			`AP.ScreenMessage("[GrantItem] Failed to create item class: " $worldClass);
		}
		
		// Special items/traps
		special = class'Archipelago_ItemInfo'.static.GetItemSpecialType(itemId);
		if (special != SpecialType_None)
		{
			DoSpecialItemEffects(special);
		}
		else
		{
			trap = class'Archipelago_ItemInfo'.static.GetItemTrapType(itemId);
			if (trap != TrapType_None)
				DoTrapItemEffects(trap);
		}
		
		// We already show a different message for yarn
		if (itemId != class'Archipelago_ItemInfo'.static.GetYarnItemID())
		{
			`AP.ScreenMessage("Got " $itemName);
		}
	}
	else
	{
		`AP.ScreenMessage("[GrantItem] Unknown item ID: " $itemId);
	}
}

function DoSpecialItemEffects(ESpecialItemType special)
{
	local Hat_Player player;

	switch (special)
	{
		case SpecialType_25Pons:
			`GameManager.AddEnergyBits(25);
			break;
			
		case SpecialType_50Pons:
			`GameManager.AddEnergyBits(50);
			break;
			
		case SpecialType_100Pons:
			`GameManager.AddEnergyBits(100);
			break;
			
		case SpecialType_HealthPon:
			foreach DynamicActors(class'Hat_Player', player)
			{
				if (player.Health > 0)
					player.HealDamage(1, None, None);
			}
			break;
			
		default:
			return;
	}
}

function DoTrapItemEffects(ETrapType trap)
{
	switch (trap)
	{
		case TrapType_Baby:
			if (`AP.BabyCount > 0)
			{
				`AP.BabyCount += 10;
			}
			else
			{
				`AP.BabyCount = 10;
				`AP.SetTimer(0.5, true, NameOf(`AP.BabyTrapTimer), `AP);
			}
			break;
			
		case TrapType_Laser:
			if (`AP.LaserCount > 0)
			{
				`AP.LaserCount += 5;
			}
			else
			{
				`AP.LaserCount = 5;
				`AP.SetTimer(1.0, true, NameOf(`AP.LaserTrapTimer), `AP);
			}
			break;
			
		case TrapType_Parade:
			`AP.DoParadeTrap();
			break;
			
		default:
			break;
	}
}

// this is currently just to check for DeathLink packets
function OnBounceCommand(string json)
{
	local JsonObject jsonObj;
	local JsonObject jsonChild;
	local Hat_Player player;

	Repl(json, "[", "");
	Repl(json, "]", "");
	
	jsonObj = class'JsonObject'.static.DecodeJson(json);
	jsonChild = jsonObj.GetObject("data");
	if (`AP.IsDeathLinkEnabled() && jsonObj.GetStringValue("tags") == "DeathLink")
	{
		// commit myurder
		foreach DynamicActors(class'Hat_Player', player)
			player.Suicide();
		
		if (jsonChild != None)
			`AP.ScreenMessage("You were myurrderrred by: " $jsonChild.GetStringValue("source"));
	}
}

// the optional boolean is for recursion, do not use it
function SendBinaryMessage(string message, optional bool continuation)
{
	local byte byteMessage[255];
	local string buffer;
	local int length;
	local int maskKey[4];
	local int keyIndex;
	local int offset;
	local int i;
	local int totalSent;
	
	for (i = 0; i < 4; i++)
	{
		maskKey[i] = class'Hat_Math'.static.SeededRandRangeInt(1, 2147483647);
	}
	
	length = Len(message);
	
	// If the length is bigger than this, we must split our message into multiple fragments, as SendBinary() can only send 255 bytes at a time.
	if (length > MaxSentMessageLength)
	{
		buffer = Mid(message, 0, MaxSentMessageLength);
		totalSent = MaxSentMessageLength;
		
		if (!continuation) // start our continuation message
		{
			byteMessage[0] = `CODE_TEXT;
			//`log("[DEBUG] Sending message (CODE_TEXT): "$buffer);
		}
		else // continue our message
		{
			byteMessage[0] = `CODE_CONTINUATION;
			//`log("[DEBUG] Sending message (CODE_CONTINUATION): "$buffer);
		}
	}
	else
	{
		buffer = message;
		totalSent = length;
		
		if (continuation) // End our continuation message
		{
			byteMessage[0] = `CODE_CONTINUATION_FIN;
			//`log("[DEBUG] Sending message (CODE_CONTINUATION_FIN): "$buffer);
		}
		else
		{
			byteMessage[0] = `CODE_TEXT_FIN;
			//`log("[DEBUG] Sending message (CODE_TEXT_FIN): "$buffer);
		}
	}
	
	offset = 0;
	
	if (totalSent <= 125)
	{
		byteMessage[1] = 128+totalSent;
	}
	else
	{
		offset = 2;
		byteMessage[1] = 128+126;
		byteMessage[2] = (totalSent >> 8) & 255;
		byteMessage[3] = totalSent & 255;
	}
	
	byteMessage[2+offset] = maskKey[0];
	byteMessage[3+offset] = maskKey[1];
	byteMessage[4+offset] = maskKey[2];
	byteMessage[5+offset] = maskKey[3];
	
	offset = offset+6;
	for (i = offset; i < totalSent+offset; i++)
	{
		byteMessage[i] = Asc(Mid(buffer, i-offset, 1)) ^ maskKey[keyIndex];
		
		keyIndex++;
		if (keyIndex > 3)
			keyIndex = 0;
	}
	
	SendBinary(offset+totalSent, byteMessage);
	
	if (byteMessage[0] == `CODE_TEXT || byteMessage[0] == `CODE_CONTINUATION)
	{
		SendBinaryMessage(Mid(message, Len(buffer)), true);
	}
}

event Closed()
{
	local Hat_TreasureChest_Base chest;
	
	foreach DynamicActors(class'Hat_TreasureChest_Base', chest)
		chest.DontSave = true;
	
	if (!`AP.DebugMode)
		`AP.WaitingToShuffle = true;
	
	// Destroy ourselves and create a new client. 
	// Reconnecting with the same client object after closing a connection does not work (for some reason).
    `AP.ScreenMessage("Connection was closed. Reconnecting...");
	Destroy();
}

event Destroyed()
{
	// Notify AP
	`AP.CreateClient();
	Super.Destroyed();
}

defaultproperties
{
    TargetHost="127.0.0.1";
    TargetPort=1453;
	bAlwaysTick = true;
}