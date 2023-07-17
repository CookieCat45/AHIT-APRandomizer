class Archipelago_TcpLink extends TcpLink
	dependson(Archipelago_ItemInfo);

`include(APRandomizer\Classes\Globals.uci);

var transient string CurrentMessage;
var transient int BracketCounter;
var transient bool ParsingMessage;
var transient bool ConnectingToAP;
var transient bool FullyConnected;
var transient bool Refused;

const MaxSentMessageLength = 246;

event PostBeginPlay()
{
	Super.PostBeginPlay();
	
	if (`AP.SlotData.ConnectedOnce)
	{
		Connect();
	}
	else
	{
		`AP.OpenSlotNameBubble(1.0);
	}
}

function Connect()
{
	if (FullyConnected || ConnectingToAP || LinkState == STATE_Connecting)
		return;
	
	ReceiveMode = RMODE_Event;
	LinkMode = MODE_Line;
	`AP.ScreenMessage("Connecting to host: " $`AP.SlotData.Host$":"$`AP.SlotData.Port);
    Resolve(`AP.SlotData.Host);
	
	ClearTimer(NameOf(TimedOut));
	SetTimer(10.0, false, NameOf(TimedOut));
}

event Resolved(IpAddr Addr)
{
    Addr.Port = `AP.SlotData.Port;
    BindPort();
	
	`AP.DebugMessage("Opening connection...");
    if (!Open(Addr))
    {
        `AP.ScreenMessage("Failed to open connection to "$`AP.SlotData.Host $":"$`AP.SlotData.Port);
		ClearTimer(NameOf(Connect));
		ClearTimer(NameOf(TimedOut));
		Close();
    }
}

function TimedOut()
{
	if (!FullyConnected && !ConnectingToAP)
	{
		`AP.ScreenMessage("Connection attempt to " $`AP.SlotData.Host$":" $`AP.SlotData.Port $" timed out");
		ClearTimer(NameOf(Connect));
		Close();
	}
}

event ResolveFailed()
{
    `AP.ScreenMessage("Unable to resolve " $`AP.SlotData.Host $":"$`AP.SlotData.Port);
	ClearTimer(NameOf(Connect));
	ClearTimer(NameOf(TimedOut));
	Close();
}

event Opened()
{
	local string crlf;
	
	ClearTimer(NameOf(TimedOut));
	ClearTimer(NameOf(Connect));
	
	crlf = chr(13)$chr(10);
	
	`AP.DebugMessage("Opened connection, sending HTTP request...");
	// send HTTP request to server to upgrade to websocket connection
	SendText("GET / HTTP/1.1" $crlf
	$"Host: " $`AP.SlotData.Host $crlf
	$"Connection: keep-alive, Upgrade" $crlf
	$"Upgrade: websocket" $crlf
	$"Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" $crlf
	$"Sec-WebSocket-Version: 13" $crlf
	$"Accept: /" $crlf);
}

// this should be our HTTP response from the server
event ReceivedLine(string message)
{
	ReceiveMode = RMODE_Manual; // event mode seems to cause problems
	LinkMode = MODE_Binary;
	
	if (!FullyConnected && !ConnectingToAP)
	{
		`AP.DebugMessage("Received HTTP response, sending Connect packet...");
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
	json.SetStringValue("name", `AP.SlotData.SlotName);
	json.SetStringValue("password", `AP.SlotData.Password);
	json.SetStringValue("uuid", "");
	
	json.SetIntValue("items_handling", 7);
	json.SetBoolValue("slot_data", !`AP.SlotData.Initialized);
	
	jsonVersion = new class'JsonObject';
	jsonVersion.SetStringValue("major", "0");
	jsonVersion.SetStringValue("minor", "4");
	jsonVersion.SetStringValue("build", "1");
	jsonVersion.SetStringValue("class", "Version");
	json.SetObject("version", jsonVersion);
	
	if (`AP.SlotData.DeathLink)
	{
		json.SetStringValue("tags", "[\"DeathLink\"]");
	}
	else
	{
		json.SetStringValue("tags", "");
	}
	
	// remove "" from tags array
	message = `AP.EncodeJson2(json);
	message = Repl(message, "\"[", "[");
	message = Repl(message, "]\"", "]");
	
	SendBinaryMessage(message);
	json = None;
	jsonVersion = None;
}

event Tick(float d)
{
	local byte byteMessage[255];
	local int count, i;
	local string character, pong, msg;
	local Archipelago_GameMod m;
	
	Super.Tick(d);
	
	if (LinkState != STATE_Connected || ReceiveMode == RMODE_Event || LinkMode != MODE_Binary)
		return;
	
	// Messages from the AP server are not null-terminated, so it must be done this way.
	// We can only read 255 bytes from the socket at a time.
	// Also Unrealscript doesn't like [] in JSON.
	if (IsDataPending())
	{
		count = ReadBinary(255, byteMessage);
		if (count <= 0)
			return;
		
		// Check for a ping first
		if (!ParsingMessage && count <= 10)
		{
			for (i = 0; i < count; i++)
			{
				CurrentMessage $= Chr(byteMessage[i]);
			}
			
			for (i = 0; i < Len(CurrentMessage); i++)
			{
				if (Asc(Mid("a"$CurrentMessage, i, 1)) == `CODE_PING)
				{
					// Need to send the same data back as a pong
					// This is a dumb way to do it, but whatever works.
					pong = Mid(CurrentMessage, InStr(CurrentMessage, Chr(`CODE_PING), false, true));
					pong = Mid(pong, 2);
					SendBinaryMessage(pong, false, true);
					break;
				}
			}
			
			CurrentMessage = "";
			if (pong != "")
				return;
		}
		
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
					CurrentMessage = "";
					ParsingMessage = true;
				}
			}
			else if (ParsingMessage && character == "]")
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
	else if (!ParsingMessage)
	{
		m = `AP;
		for (i = 0; i < m.SlotData.PendingMessages.Length; i++)
		{
			msg = m.SlotData.PendingMessages[i];
			SendBinaryMessage(msg, false, len(msg) <= 10 && InStr(msg, Chr(`CODE_PONG), false, true) != -1);
		}
	}
}

// ALL JsonObjects MUST be set to None after use!!!!!!!
// The engine will never garbage collect them on its own if they are referenced, even locally!
function ParseJSON(string json)
{
	local bool b;
	local int i, count, split;
	local string s, text;
	local JsonObject jsonObj, jsonChild;
	local Archipelago_GameMod m;
	
	m = `AP;
	if (Len(json) <= 10) // this is probably garbage that we thought was a json
		return;
	
	m.DebugMessage("[ParseJSON] Received command: " $json);
	
	// UnrealScript's JSON parser does not like []
	json = Repl(json, "[{", "{");
	json = Repl(json, "}]", "}");
	
	// Dumb, but fixes the incorrect player slot being assigned
	if (InStr(json, "Connected") != -1)
		m.ReplOnce(json, "slot", "my_slot", json);
	
	m.DebugMessage("[ParseJSON] Reformatted command: " $json);
	
	jsonObj = new class'JsonObject';
	jsonObj = class'JsonObject'.static.DecodeJson(json);
	if (jsonObj == None)
	{
		m.DebugMessage("[ParseJSON] Failed to parse JSON: " $json);
		return;
	}
	
	switch (jsonObj.GetStringValue("cmd"))
	{
		case "Connected":
			m.OnPreConnected();
			m.ScreenMessage("Successfully connected to " $m.SlotData.Host $":"$m.SlotData.Port);
			m.SlotData.PlayerSlot = jsonObj.GetIntValue("my_slot");
			FullyConnected = true;
			ConnectingToAP = false;
			
			if (!m.SlotData.Initialized)
			{
				jsonChild = jsonObj.GetObject("slot_data");
				m.LoadSlotData(jsonChild);
			}
			
			// sometimes this command will be paired with ReceivedItems
			split = InStr(json, "{\"cmd\":\"ReceivedItems\"");
			if (split != -1)
			{
				OnReceivedItemsCommand(Mid(json, split), true);
			}
			
			// Initialize our player's names
			m.ReplOnce(json, "players", "players_0", json, true);
			b = true;
			count = 0;
			
			while (b)
			{
				if (m.ReplOnce(json, ",{", ",\"players_"$count+1 $"\":{", s, false))
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
					
				m.SlotData.PlayerNames[jsonChild.GetIntValue("slot")] = jsonChild.GetStringValue("alias");
			}
			
			// Fully connected
			m.OnFullyConnected();
			break;
			
			
		case "PrintJSON":
			jsonChild = jsonObj.GetObject("data");
			
			if (jsonChild != None)
			{
				if (IsValidMessageType(jsonChild.GetStringValue("type")))
				{
					text = jsonChild.GetStringValue("text");
					if (InStr(text, "[Hint]:") == -1)
					{
						m.ScreenMessage(text);
					}
				}
			}
			
			break;
			
			
		case "ConnectionRefused":
			ConnectingToAP = false;
			m.ScreenMessage("Connection refused by server. Check to make sure your slot name, password, etc. are correct.");
			Refused = true;
			Close();
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

	jsonObj = None;
	jsonChild = None;
}

function bool IsValidMessageType(string msgType)
{
	return (msgType != "ItemSend" && msgType != "Hint" && msgType != "player_id");
}

function OnLocationInfoCommand(string json)
{
	local LocationInfo locInfo;
	local bool b, isItem;
	local int i, locId, count, itemId, flags;
	local string s, mapName;
	local JsonObject jsonObj, jsonChild;
	local Archipelago_RandomizedItem_Base item;
	local Hat_Collectible_Important collectible;
	local class<Archipelago_ShopItem_Base> shopItemClass;
	local Actor container;
	local Archipelago_GameMod m;
	
	mapName = class'Hat_SaveBitHelper'.static.GetCorrectedMapFilename();
	
	m = `AP;
	m.ReplOnce(json, "locations", "locations_0", json, true);
	b = true;
	count = 0;
	
	while (b)
	{
		if (m.ReplOnce(json, ",{", ",\"locations_" $count+1 $"\":{", s, false))
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
		
		if (m.GetShopItemClassFromLocation(jsonChild.GetIntValue("location"), shopItemClass))
		{
			if (!m.GetShopItemInfo(shopItemClass))
			{
				m.CreateShopItemInfo(shopItemClass, 
					jsonChild.GetIntValue("item"),
					jsonChild.GetIntValue("flags"));
			}
		}
		else
		{
			isItem = false;
			
			foreach DynamicActors(class'Hat_Collectible_Important', collectible)
			{
				if (collectible.IsA('Hat_Collectible_VaultCode_Base') || collectible.IsA('Hat_Collectible_InstantCamera'))
					continue;
				
				locId = m.ObjectToLocationId(collectible);
				if (locId == jsonChild.GetIntValue("location"))
				{
					m.DebugMessage("Replacing item: "$collectible $", Location ID: "$locId);
					
					m.CreateItem(locId, 
						jsonChild.GetIntValue("item"),
						jsonChild.GetIntValue("flags"),
						jsonChild.GetIntValue("player"),
						collectible);
					
					isItem = true;
					collectible.Destroy();
					break;
				}
			}
			
			locId = jsonChild.GetIntValue("location");
			if (!isItem && m.IsLocationIDContainer(locId, container))
			{
				itemId = jsonChild.GetIntValue("item");
				flags = jsonChild.GetIntValue("flags");
				
				locInfo.ID = locId;
				locInfo.ItemID = itemId;
				locInfo.Player = jsonChild.GetIntValue("player");
				locInfo.Flags = flags;
				locInfo.MapName = mapName;
				locInfo.ContainerClass = container.class;
				
				if (!class'Archipelago_ItemInfo'.static.GetNativeItemData(itemId, locInfo.ItemName, locInfo.ItemClass))
				{
					switch (flags)
					{
						case ItemFlag_Important:
							locInfo.ItemName = "AP Item - Important"; 
							break;
							
						case ItemFlag_ImportantSkipBalancing:
							locInfo.ItemName = "AP Item - Important"; 
							break;
						
						case ItemFlag_Useful: 
							locInfo.ItemName = "AP Item - Useful"; 
							break;
						
						default: 
							locInfo.ItemName = "AP Item"; 
							break;
					}
				}
				
				m.SlotData.LocationInfoArray.AddItem(locInfo);
				continue;
			}
			
			if (locId == m.CameraBadgeCheck1 || locId == m.CameraBadgeCheck2)
			{
				item = m.CreateItem(locId, 
					jsonChild.GetIntValue("item"),
					jsonChild.GetIntValue("flags"),
					jsonChild.GetIntValue("player"),
					,
					locId == m.CameraBadgeCheck1 ? m.Camera1Loc : m.Camera2Loc);
				
				if (item != None)
				{
					item.OriginalCollectibleName = locId == m.CameraBadgeCheck1 ? "AP_Camera1Check" : "AP_Camera2Check";
					item.Init();
				}
			}
		}
	}
	
	if (!m.IsMapScouted(mapName))
	{
		m.SetAPBits("MapScouted_"$Locs(mapName), 1);
		m.SaveGame();
	}
	
	jsonObj = None;
	jsonChild = None;
}

function OnReceivedItemsCommand(string json, optional bool connection)
{
	local int count, index, total, i, id, isAct, start;
	local string timePieceId, timePieceName, s;
	local JsonObject jsonObj, jsonChild;
	local bool b;
	local Archipelago_GameMod m;
	
	m = `AP;
	m.ReplOnce(json, "items", "items_0", json, true);
	b = true;
	count = 0;
	
	while (b)
	{
		if (m.ReplOnce(json, ",{", ",\"items_"$count+1 $"\":{", s, false))
		{
			json = s;
			count++;
		}
		else
		{
			b = false;
		}
	}
	
	m.DebugMessage("Receiving items... "$json);
	jsonObj = class'JsonObject'.static.DecodeJson(json);
	index = m.GetAPBits("LastItemIndex");
	
	// This means we are reconnecting to a previous session, and the server is giving us our entire list of items,
	// so we need to begin from the next new item in our list or don't give anything otherwise
	if (connection)
	{
		if (index > count)
		{
			jsonObj = None;
			return;
		}
		else
		{
			start = index;
		}	
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
				GrantTimePiece(timePieceId, bool(isAct), timePieceName, jsonChild.GetIntValue("player"));
			}	
			else
			{
				// regular item
				GrantItem(id, jsonChild.GetIntValue("player"));
			}
				
			total++;
		}
	}
	
	jsonObj = None;
	jsonChild = None;
	m.SetAPBits("LastItemIndex", index+total);
	m.SaveGame();
}

function GrantTimePiece(string timePieceId, bool IsAct, string itemName, int playerId)
{
	local Archipelago_RandomizedItem_Base item;
	local Pawn player;
	
	player = GetALocalPlayerController().Pawn;
	
	item = Spawn(class'Archipelago_RandomizedItem_TimeObject', , , player.Location, , , true);
	item.PickupActor = player;
	item.OnCollected(player);
	
	if (playerId != `AP.SlotData.PlayerSlot)
	{
		`AP.ScreenMessage("Got " $itemName $" (from " $`AP.PlayerIdToName(playerId)$")", 'Warning');
	}
	else
	{
		`AP.ScreenMessage("Got " $itemName, 'Warning');
	}
	
	// Tell AP to stop removing this Time Piece in OnTimePieceCollected()
	`AP.SetAPBits(timePieceId, 1);
	
	`AP.IsItemTimePiece = true;
	`SaveManager.GetCurrentSaveData().GiveTimePiece(timePieceId, IsAct);
	`AP.IsItemTimePiece = false;
	
	if (`AP.IsInSpaceship() && `AP.SlotData.Initialized)
	{
		`AP.UpdateActUnlocks();
		`AP.UpdatePowerPanels();
	}
}

function GrantItem(int itemId, int playerId)
{
	local class<Actor> worldClass, invOverride;
	local class<Hat_SnatcherContract_Act> contract;
	local string itemName;
	local Archipelago_RandomizedItem_Base item;
	local Pawn player;
	local ESpecialItemType special;
	local ETrapType trap;
	local Hat_SaveGame save;
	
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
			if (playerId != `AP.SlotData.PlayerSlot)
			{
				`AP.ScreenMessage("Got " $itemName $" (from "$`AP.PlayerIdToName(playerId)$")");
			}
			else
			{
				`AP.ScreenMessage("Got " $itemName);
			}
		}
	}
	else
	{
		// screen message so players report problems
		`AP.ScreenMessage("[GrantItem] Unknown item ID: " $itemId);
	}
	
	if (class'Archipelago_ItemInfo'.static.GetContractFromID(itemId) != None)
	{
		contract = class'Archipelago_ItemInfo'.static.GetContractFromID(itemId);
		if (`AP.SlotData.ObtainedContracts.Find(contract) == -1)
			`AP.SlotData.ObtainedContracts.AddItem(contract); // now we know we should actually have this contract
		
		save = `SaveManager.GetCurrentSaveData();
		if (save.SnatcherContracts.Find(contract) == -1)
			save.SnatcherContracts.AddItem(contract);
		
		contract.static.UnlockActs(save);
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
				`AP.LaserCount += 15;
			}
			else
			{
				`AP.LaserCount = 15;
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
	local JsonObject jsonObj, jsonChild;
	local Hat_Player player;
	
	Repl(json, "[", "");
	Repl(json, "]", "");
	
	jsonObj = class'JsonObject'.static.DecodeJson(json);
	if (jsonObj == None)
		return;
	
	jsonChild = jsonObj.GetObject("data");
	if (jsonChild != None && `AP.IsDeathLinkEnabled() && jsonObj.GetStringValue("tags") == "DeathLink")
	{
		// commit myurder
		foreach DynamicActors(class'Hat_Player', player)
			player.Suicide();
		
		if (jsonChild != None)
			`AP.ScreenMessage("You were myurrderrred by: " $jsonChild.GetStringValue("source"));
	}

	jsonObj = None;
	jsonChild = None;
}

// the optional boolean is for recursion, do not use it
function SendBinaryMessage(string message, optional bool continuation, optional bool pong)
{
	local byte byteMessage[255];
	local string buffer;
	local int length, offset, keyIndex, i, totalSent;
	local int maskKey[4];
	local bool found;
	
	if (!continuation)
	{
		// wait until this is finished
		if (ParsingMessage)
		{
			for (i = 0; i < `AP.SlotData.PendingMessages.Length; i++)
			{
				if (`AP.SlotData.PendingMessages[i] == message)
				{
					found = true;
					break;
				}
			}
			
			if (!found)
			{
				`AP.SlotData.PendingMessages.AddItem(message);
			}
		}
		else
		{
			`AP.SlotData.PendingMessages.RemoveItem(message);
			`AP.DebugMessage("Sending message: "$message);
		}
	}
	
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
		}
		else // continue our message
		{
			byteMessage[0] = `CODE_CONTINUATION;
		}
	}
	else
	{
		buffer = message;
		totalSent = length;
		
		if (pong)
		{
			byteMessage[0] = `CODE_PONG;
		}
		else if (continuation) // End our continuation message
		{
			byteMessage[0] = `CODE_CONTINUATION_FIN;
		}
		else
		{
			byteMessage[0] = `CODE_TEXT_FIN;
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
	if (!Refused)
	{
		`AP.ScreenMessage("Connection was closed. Reconnecting in 5 seconds...");
	}
	
	CurrentMessage = "";
	BracketCounter = 0;
	ParsingMessage = false;
	FullyConnected = false;
	ConnectingToAP = false;
	
	if (`AP.SlotData.ConnectedOnce)
	{
		SetTimer(5.0, false, NameOf(Connect));
	}
	else
	{
		`AP.OpenSlotNameBubble(1.0);
	}
}

event Destroyed()
{
	Close();
	Super.Destroyed();
}

defaultproperties
{
	bAlwaysTick = true;
}