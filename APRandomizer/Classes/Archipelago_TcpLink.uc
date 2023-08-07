class Archipelago_TcpLink extends TcpLink
	dependson(Archipelago_ItemInfo);

`include(APRandomizer\Classes\Globals.uci);

var transient array<string> CurrentMessage;
var transient bool ParsingMessage;
var transient bool ConnectingToAP;
var transient bool FullyConnected;
var transient bool Refused;
var transient int EmptyCount;
var transient bool FirstReceivedItems;

const MaxSentMessageLength = 246;

event PostBeginPlay()
{
	Super.PostBeginPlay();
	
	if (bool(`AP.DisableAutoConnect))
		return;

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
	CurrentMessage.Length = 0;
	
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
	local int count, i, a, k;
	local string character, pong, msg, nullChar, cmd;
	local Archipelago_GameMod m;
	local bool b;
	
	Super.Tick(d);
	
	if (LinkState != STATE_Connected || ReceiveMode == RMODE_Event || LinkMode != MODE_Binary)
		return;
	
	// Messages from the AP server are not null-terminated, so it must be done this way.
	// We can only read 255 bytes from the socket at a time.
	// Also Unrealscript doesn't like [] in JSON.
	if (IsDataPending())
	{
		// IsDataPending seems to almost always return true even if no data is pending after a msg is sent, 
		// so to check for the end of a message, 
		// we simply count how many times we've read 0 bytes of data
		count = ReadBinary(255, byteMessage);
		if (count <= 0)
		{
			if (ParsingMessage)
				EmptyCount++;
		}
		else
		{
			EmptyCount = 0;
			
			// Check for a ping
			if (!ParsingMessage && count <= 10)
			{
				for (i = 0; i < count; i++)
				{
					// UnrealScript doesn't allow null characters in strings, so we need to do this crap
					if (byteMessage[i] == byte(0))
					{
						`AP.DebugMessage("Null character in pong");
						if (nullChar != "")
						{
							msg $= nullChar;
							continue;
						}

						for (a = 33; a <= 255; a++)
						{
							b = false;
							
							for (k = 0; k < count; k++)
							{
								if (byteMessage[k] == byte(a))
								{
									b = true;
									break;
								}
							}
							
							if (!b)
							{
								nullChar = Chr(a);
								msg $= nullChar;
								break;
							}
						}
						
						continue;
					}
					
					msg $= Chr(byteMessage[i]);
				}
				
				for (i = 0; i < Len(msg); i++)
				{
					if (Asc(Mid("a"$msg, i, 1)) == `CODE_PING)
					{
						// Need to send the same data back as a pong
						// This is a dumb way to do it, but whatever works.
						pong = Mid(msg, InStr(msg, Chr(`CODE_PING), false, true));
						pong = Mid(pong, 2);
						SendBinaryMessage(pong, false, true, nullChar);
						break;
					}
				}
				
				if (pong != "")
					return;
			}
			
			for (i = 0; i < count; i++)
			{
				character = Chr(byteMessage[i]);
				CurrentMessage.AddItem(character);
				
				if (character == "[")
				{
					if (!ParsingMessage)
					{
						CurrentMessage.Length = 0;
						ParsingMessage = true;
					}
				}
			}
		}
	}
	
	if (ParsingMessage)
	{
		if (EmptyCount >= 15)
		{
			// We've got a JSON message, parse it
			msg = "";

			for (i = 0; i < CurrentMessage.Length; i++)
			{
				if (CurrentMessage[i] == "}")
				{
					cmd = "";
					for (a = i+1; a < CurrentMessage.Length; a++)
					{
						cmd $= CurrentMessage[a];
						if (Len(cmd) >= 15)
							break;
					}
					
					if (a >= CurrentMessage.Length || InStr(cmd, "}") == -1 
					&& (FullyConnected && InStr(cmd, "{\"cmd\"") != -1 
					|| InStr(cmd, "{\"cmd\"") != -1 && InStr(msg, "{\"cmd\":\"Connected\"") != -1))
					{
						ParseJSON(msg$"}");
						msg = "";
					}
				}
				
				msg $= CurrentMessage[i];
			}
			
			//if (Len(msg) > 0)
			//	ParseJSON(msg);
			
			CurrentMessage.Length = 0;
			ParsingMessage = false;
			EmptyCount = 0;
		}
	}
	else if (FullyConnected)
	{
		m = `AP;
		for (i = 0; i < m.SlotData.PendingMessages.Length; i++)
		{
			msg = m.SlotData.PendingMessages[i];
			SendBinaryMessage(msg);
		}
	}
}

// ALL JsonObjects MUST be set to None after use!!!!!!!
// The engine will never garbage collect them on its own if they are referenced, even locally!
function ParseJSON(string json)
{
	local bool b;
	local int i, a, count, split, pos, locId;
	local array<int> missingLocs;
	local string s, text, num;
	local JsonObject jsonObj, jsonChild;
	local Archipelago_GameMod m;
	
	m = `AP;
	if (Len(json) <= 10) // this is probably garbage that we thought was a json
		return;
	
	// remove garbage at start of string
	for (i = 0; i < Len(json); i++)
	{
		if (Mid(json, i, 2) == "{\"")
		{
			json = Mid(json, i);
			break;
		}
	}
	
	m.DebugMessage("[ParseJSON] Received command: " $json);
	
	// UnrealScript's JSON parser does not like []
	json = Repl(json, "[{", "{");
	json = Repl(json, "}]", "}");
	
	// Dumb, but fixes the incorrect player slot being assigned
	if (InStr(json, "Connected") != -1)
	{
		m.ReplOnce(json, "slot", "my_slot", json);
		
		// Also dumb, but seems to fix crashing problems, hopefully.
		split = InStr(json, ",{\"cmd\":\"ReceivedItems\"");
		if (split != -1)
		{
			json = Repl(json, Mid(json, split), "", false);
		}
	}
	
	m.DebugMessage("[ParseJSON] Reformatted command: " $json);
	m.DebugMessage("a");
	
	jsonObj = new class'JsonObject';
	jsonObj = class'JsonObject'.static.DecodeJson(json);
	if (jsonObj == None)
	{
		m.DebugMessage("[ParseJSON] Failed to parse JSON: " $json, , true);
		return;
	}
	
	m.DebugMessage("b");
	
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

			m.DebugMessage("c");
			
			// Initialize our player's names
			m.ReplOnce(json, "players", "players_0", json, true);
			b = true;
			count = 0;
			
			// If we have checked locations that haven't been sent for some reason, send them now
			pos = InStr(json, "\"missing_locations\":[");
			pos += len("\"missing_locations\":[");
			
			if (pos != -1)
			{
				num = "";
				
				for (i = pos; i < len(json); i++)
				{
					s = Mid(json, i, 1);
					if (s == "]")
						break;
					
					if (len(num) > 0 && s == ",")
					{
						locId = int(num);
						for (a = 0; a < m.SlotData.LocationInfoArray.Length; a++)
						{
							if (m.SlotData.LocationInfoArray[a].ID == locId)
							{
								if (m.SlotData.LocationInfoArray[a].Checked)
								{
									missingLocs.AddItem(locId);
								}
								
								break;
							}
						}
						
						num = "";
					}
					else if (s != "," && s != "[")
					{
						num $= s;
					}
				}
			}
			
			if (missingLocs.Length > 0)
			{
				m.DebugMessage("Sending missing locations");
				m.SendMultipleLocationChecks(missingLocs);
			}
			
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
			
			m.DebugMessage("d");
			
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
			OnReceivedItemsCommand(json, !FirstReceivedItems);
			FirstReceivedItems = true;
			break;
		
		
		case "LocationInfo":
			OnLocationInfoCommand(json);
			break;
		
		
		case "Bounced":
			OnBouncedCommand(json);
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
	local bool isItem;
	local int i, locId, count, itemId, flags;
	local string s, mapName;
	local JsonObject jsonObj, jsonChild;
	local Archipelago_RandomizedItem_Base item;
	local Hat_Collectible_Important collectible;
	local class<Archipelago_ShopItem_Base> shopItemClass;
	local Actor container;
	local Archipelago_GameMod m;
	
	mapName = class'Hat_SaveBitHelper'.static.GetCorrectedMapFilename();
	
	// Fix for Rock the Boat
	if (`GameManager.GetCurrentMapFilename() ~= "ship_sinking")
		mapName = "ship_sinking";
	
	m = `AP;
	m.ReplOnce(json, "locations", "locations_0", json, true);
	count = 0;
	
	while (m.ReplOnce(json, ",{", ",\"locations_" $count+1 $"\":{", s, false))
	{
		json = s;
		count++;
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
				if (m.IsLocationCached(locId))
					continue;

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
					if (class'Archipelago_ItemInfo'.static.GetTimePieceFromItemID(itemId, , locInfo.ItemName) != "")
					{
						locInfo.itemClass = class'Archipelago_RandomizedItem_TimeObject';
					}
					else
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
	local Archipelago_GameMod m;
	local Archipelago_RandomizedItem_Base item;
	local Pawn player;
	
	m = `AP;
	player = GetALocalPlayerController().Pawn;
	
	item = Spawn(class'Archipelago_RandomizedItem_TimeObject', , , player.Location, , , true);
	item.PickupActor = player;
	item.OnCollected(player);
	
	if (playerId != m.SlotData.PlayerSlot)
	{
		m.ScreenMessage("Got " $itemName $" (from " $m.PlayerIdToName(playerId)$")", 'Warning');
	}
	else
	{
		m.ScreenMessage("Got " $itemName, 'Warning');
	}
	
	// Tell AP to stop removing this Time Piece in OnTimePieceCollected()
	m.SetAPBits(timePieceId, 1);
	
	m.IsItemTimePiece = true;
	`SaveManager.GetCurrentSaveData().GiveTimePiece(timePieceId, IsAct);
	m.IsItemTimePiece = false;
	
	if (m.IsInSpaceship() && m.SlotData.Initialized)
	{
		m.UpdateActUnlocks();
		m.UpdatePowerPanels();
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
	else if (itemId == 300204 || itemId == 300205 || itemId == 300206 || itemId == 300207)
	{
		UnlockZipline(itemId);
	}
}

function UnlockZipline(int id)
{
	local string zipline;

	switch (id)
	{
		case 300204: // Birdhouse Path
			zipline = "Hat_HookPoint_Desert_2";
			break;

		case 300205: // Lava Cake Path
			zipline = "Hat_HookPoint_Desert_16";
			break;
		
		case 300206: // Windmill Path
			zipline = "Hat_HookPoint_Desert_1";
			break;
		
		case 300207: // Twilight Bell Path
			zipline = "Hat_HookPoint_Desert_24";
			break;
		
		default:
			return;
	}

	`AP.SetAPBits("ZiplineUnlock_"$zipline, 1);
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
	local Archipelago_GameMod m;
	m = `AP;
	
	switch (trap)
	{
		case TrapType_Baby:
			if (m.BabyCount > 0)
			{
				m.BabyCount += 10;
			}
			else
			{
				m.BabyCount = 10;
				m.SetTimer(0.5, true, NameOf(m.BabyTrapTimer));
			}
			break;
			
		case TrapType_Laser:
			if (m.LaserCount > 0)
			{
				m.LaserCount += 15;
			}
			else
			{
				m.LaserCount = 15;
				m.SetTimer(1.0, true, NameOf(m.LaserTrapTimer));
			}
			break;
			
		case TrapType_Parade:
			m.DoParadeTrap();
			break;
			
		default:
			break;
	}
}

function OnBouncedCommand(string json)
{
	local JsonObject jsonObj, jsonChild;
	local string cause, msg, source;
	local Hat_Player player;
	
	jsonObj = class'JsonObject'.static.DecodeJson(json);
	if (jsonObj == None)
		return;
	
	jsonChild = jsonObj.GetObject("data");
	if (jsonChild != None && `AP.IsDeathLinkEnabled())
	{
		source = jsonChild.GetStringValue("source");
		if (source != "" && source != `AP.SlotData.SlotName)
		{
			// commit myurder
			foreach DynamicActors(class'Hat_Player', player)
				player.Suicide();
			
			msg = "You were MYURRDERRRRED by: " $source;
			cause = jsonChild.GetStringValue("cause");
			if (cause != "")
				msg $= " (" $cause $")";
			
			`AP.ScreenMessage(msg);
		}
	}
	
	jsonObj = None;
	jsonChild = None;
}

// the optional boolean is for recursion, do not use it
function SendBinaryMessage(string message, optional bool continuation, optional bool pong, optional string nullChar="")
{
	local Archipelago_GameMod m;
	local byte byteMessage[255];
	local string buffer;
	local int length, offset, keyIndex, i, totalSent;
	local int maskKey[4];
	local bool found;
	
	m = `AP;
	
	if (!continuation && !pong)
	{
		// wait until this is finished
		if (ParsingMessage)
		{
			for (i = 0; i < m.SlotData.PendingMessages.Length; i++)
			{
				if (m.SlotData.PendingMessages[i] == message)
				{
					found = true;
					break;
				}
			}
			
			if (!found)
			{
				m.SlotData.PendingMessages.AddItem(message);
			}
		}
		else
		{
			m.SlotData.PendingMessages.RemoveItem(message);
			m.DebugMessage("Sending message: "$message);
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
		// null character
		if (pong && nullChar != "" && Mid(buffer, i-offset, 1) == nullChar)
		{
			m.DebugMessage("Adding null byte");
			byteMessage[i] = byte(0) ^ maskKey[keyIndex];
		}
		else
		{
			byteMessage[i] = Asc(Mid(buffer, i-offset, 1)) ^ maskKey[keyIndex];
		}
		
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
	
	CurrentMessage.Length = 0;
	EmptyCount = 0;
	ParsingMessage = false;
	FullyConnected = false;
	ConnectingToAP = false;
	FirstReceivedItems = false;
	
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