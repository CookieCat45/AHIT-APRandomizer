class Archipelago_TcpLink extends TcpLink
	dependson(Archipelago_ItemInfo);

`include(APRandomizer\Classes\Globals.uci);

var transient array<string> CurrentMessage;
var transient bool ParsingMessage;
var transient bool ConnectingToAP;
var transient bool FullyConnected;
var transient bool Refused;
var transient bool Reconnecting;
var transient int EmptyCount;

const MaxSentMessageLength = 246;

event PostBeginPlay()
{
	Super.PostBeginPlay();
	Connect();
}

function Connect()
{
	if (FullyConnected || ConnectingToAP || LinkState == STATE_Connecting)
		return;
	
	// Event mode breaks if a message is bigger than 255 bytes. Manual mode is needed to get around this.
	ReceiveMode = RMODE_Manual;
	LinkMode = MODE_Line;
	
	if (!ShouldFilterSelfJoins())
	{
		`AP.ScreenMessage("Connecting to A Hat in Time AP Client");
	}
	
    Resolve(`AP.SlotData.Host);
	ClearTimer(NameOf(TimedOut));
	SetTimer(10.0, false, NameOf(TimedOut));
}

event Resolved(IpAddr Addr)
{
	StringToIpAddr("localhost", Addr);
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
		`AP.ScreenMessage("Connection attempt timed out. Is the A Hat in Time AP Client running?");
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
	
	SendText("GET / HTTP/1.1" $crlf
	$"Host: " $`AP.SlotData.Host $crlf
	$"Connection: keep-alive, Upgrade" $crlf
	$"Upgrade: websocket" $crlf
	$"Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" $crlf
	$"Sec-WebSocket-Version: 13" $crlf
	$"Accept: /" $crlf);
	LinkMode = MODE_Binary;
	
	if (!ShouldFilterSelfJoins())
		`AP.ScreenMessage("Connected to A Hat in Time AP Client, awaiting room information from server... (connect the A Hat in Time AP client to the server if you haven't)");
}

function ConnectToAP()
{
	local JsonObject json;
	local JsonObject jsonVersion;
	local string message;
	
	if (FullyConnected)
		return;
	
	ConnectingToAP = true;
	CurrentMessage.Length = 0;
	
	// This Connect packet isn't actually sent to the server itself, but is used by the AP client
	json = new class'JsonObject';
	json.SetStringValue("cmd", "Connect");
	json.SetStringValue("game", "A Hat in Time");
	json.SetStringValue("name", `AP.SlotData.SlotName);
	json.SetStringValue("password", `AP.SlotData.Password);
	json.SetStringValue("uuid", "");
	json.SetStringValue("seed_name", `AP.SlotData.SeedName); // Used by AP client for verification.
	
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
		json.SetStringValue("tags", "[\"DeathLink\", \"AP\"]");
	}
	else
	{
		json.SetStringValue("tags", "[\"AP\"]");
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
	local int count, i, a, k, bracket, attempts;
	local string character, pong, msg, nullChar;
	local bool b, validMsg;
	
	Super.Tick(d);
	
	if (LinkState != STATE_Connected || LinkMode != MODE_Binary)
		return;
	
	// We can only read 255 bytes from the socket at a time.
	// IsDataPending ALWAYS returns true if we're connected, even if there isn't any data pending on the socket
	while (EmptyCount <= 5 && attempts <= 20)
	{
		attempts++;
		count = ReadBinary(255, byteMessage);
		
		if (count <= 0)
		{
			if (ParsingMessage)
				EmptyCount++;
			
			break;
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
		if (EmptyCount > 5)
		{
			// We've got a JSON message, parse it
			msg = "";
			
			for (i = 0; i < CurrentMessage.Length; i++)
			{
				if (CurrentMessage[i] == "{")
				{
					if (!validMsg && CurrentMessage[i+1] == "\"")
						validMsg = true;
					
					if (validMsg)
						bracket--;
				}
				else if (validMsg && CurrentMessage[i] == "}")
				{
					bracket++;
				}
				
				if (validMsg)
				{
					msg $= CurrentMessage[i];
					if (bracket >= 0)
					{
						ParseJSON(msg);
						msg = "";
						validMsg = false;
						bracket = 0;
					}
				}
			}
			
			CurrentMessage.Length = 0;
			ParsingMessage = false;
			EmptyCount = 0;
		}
	}
}

// ALL JsonObjects MUST be set to None after use!!!!!!!
// The engine will never garbage collect them on its own if they are referenced, even locally!
function ParseJSON(string json)
{
	local bool b;
	local Name msgType;
	local int i, a, count, pos, locId, count1, count2;
	local array<int> missingLocs;
	local string s, text, num, json2, player;
	local JsonObject jsonObj, jsonChild, textObj;
	local Archipelago_GameMod m;
	
	m = `AP;
	if (Len(json) <= 10) // this is probably garbage that we thought was a json
		return;
	
	// remove garbage at start and end of string
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
	}
	
	m.DebugMessage("[ParseJSON] Reformatted command: " $json);
	
	// Security
	for (i = 0; i < Len(json); i++)
	{
		if (Mid(json, i, 1) == "{")
			count1++;
		else if (Mid(json, i, 1) == "}")
			count2++;
	}
	
	if (count1 != count2)
	{
		m.DebugMessage("[ParseJSON] [WARNING] Encountered JSON message with mismatching braces. Cancelling to prevent crash!");
		return;
	}
	
	jsonObj = new class'JsonObject';
	jsonObj = class'JsonObject'.static.DecodeJson(json);
	if (jsonObj == None)
	{
		m.DebugMessage("[ParseJSON] Failed to parse JSON: " $json);
		return;
	}
	
	switch (jsonObj.GetStringValue("cmd"))
	{
		case "RoomInfo":
			m.DebugMessage("Received RoomInfo packet, sending Connect packet...");
			ConnectToAP();
			break;
		
		case "Connected":
			m.OnPreConnected();
			
			if (!ShouldFilterSelfJoins())
				m.ScreenMessage("Successfully connected to AP Client (" $m.SlotData.Host $":"$m.SlotData.Port $")");
			
			Reconnecting = false;
			m.SlotData.PlayerSlot = jsonObj.GetIntValue("my_slot");
			FullyConnected = true;
			ConnectingToAP = false;
			
			if (!m.SlotData.Initialized)
			{
				jsonChild = jsonObj.GetObject("slot_data");
				m.LoadSlotData(jsonChild);
			}
			
			// If we have checked locations that haven't been sent for some reason, send them now
			pos = InStr(json, "\"missing_locations\":[");
			if (pos != -1)
			{
				pos += len("\"missing_locations\":[");
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
								if (m.IsLocationChecked(locId))
									missingLocs.AddItem(locId);
								
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
			
			pos = InStr(json, "\"checked_locations\":[");
			if (pos != -1)
			{
				pos += len("\"checked_locations\":[");
				num = "";
				
				for (i = pos; i < len(json); i++)
				{
					s = Mid(json, i, 1);
					if (s == "]")
						break;
					
					if (len(num) > 0 && s == ",")
					{
						locId = int(num);
						if (!m.IsLocationChecked(locId) && missingLocs.Find(locId) == -1)
						{
							m.SlotData.CheckedLocations.AddItem(locId);
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
			
			if (!m.SlotData.PlayerNamesInitialized)
			{
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
					if (jsonChild.GetIntValue("slot") == m.SlotData.PlayerSlot)
					{
						m.SlotData.SlotName = jsonChild.GetStringValue("name");
					}
				}
				
				m.SlotData.PlayerNamesInitialized = true;
			}
			
			if (m.SlotData.DeathLink)
			{
				json2 = "[{`cmd`: `ConnectUpdate`, `tags`: [`DeathLink`]}]";
				json2 = Repl(json2, "`", "\"");
				SendBinaryMessage(json2);
			}
			
			// Fully connected
			m.OnFullyConnected();
			`AP.SetAPBits("SaveFileLoad", 1);
			break;
			
			
		case "PrintJSON":
			if (ShouldFilterSelfJoins() && jsonObj.GetStringValue("type") == "Join")
			{
				if (InStr(json, ""$m.SlotData.SlotName$" ") != -1)
					break;
			}
			
			m.ReplOnce(json, "\"data\"", "\"0\"", json);
			
			for (i = 0; i < Len(json); i++)
			{
				if (Mid(json, i, 3) == "},{")
				{
					m.ReplOnce(json, "},{", 
						"}," $"\"" $a+1 $"\"" $":{", json);
					
					a++;
				}
			}
			
			jsonChild = class'JsonObject'.static.DecodeJson(json);
			if (jsonChild == None)
				break;
				
			for (i = 0; i <= a; i++)
			{
				textObj = jsonChild.GetObject(string(i));
				if (textObj == None)
					continue;
				
				switch (textObj.GetStringValue("type"))
				{
					case "player_id":
						player = m.PlayerIDToName(int(textObj.GetStringValue("text")));

						if (player == m.SlotData.SlotName)
							msgType = 'Warning';
						
						text $= player;
						break;
					
					/*
					case "item_id":
						text $= m.ItemIDToName(textObj.GetStringValue("text"));
						break;
					
					case "location_id":
						text $= m.LocationIDToName(textObj.GetStringValue("text"));
						break;
					*/
					
					default:
						text $= textObj.GetStringValue("text");
						break;
				}
			}
			
			if (ShouldFilterSelfJoins() && InStr(text, "Now that you are connected") != -1)
				break;
			
			m.ScreenMessage(text, msgType);
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
		
		
		case "Bounced":
			OnBouncedCommand(json);
			break;


		case "Retrieved":
			OnRetrievedCommand(json);
			break;
			
		
		case "RoomUpdate":
			// Paste-a la CTRL+Vista baby.
			// I'm not sorry. Please help me.
			pos = InStr(json, "\"checked_locations\":[");
			if (pos != -1)
			{
				pos += len("\"checked_locations\":[");
				num = "";
				
				for (i = pos; i < len(json); i++)
				{
					s = Mid(json, i, 1);
					if (s == "]")
						break;
					
					if (len(num) > 0 && s == ",")
					{
						locId = int(num);
						if (!m.IsLocationChecked(locId))
						{
							m.SlotData.CheckedLocations.AddItem(locId);
						}
						
						num = "";
					}
					else if (s != "," && s != "[")
					{
						num $= s;
					}
				}
			}
			
			m.SaveGame();
			break;
		
			
		default:
			break;
	}

	jsonObj = None;
	jsonChild = None;
	textObj = None;
}

function OnLocationInfoCommand(string json)
{
	local LocationInfo locInfo;
	local bool isItem;
	local int i, locId, count, flags;
	local string s, mapName, itemId;
	local JsonObject jsonObj, jsonChild;
	local Archipelago_RandomizedItem_Base item;
	local Hat_Collectible_Important collectible;
	local class<Archipelago_ShopItem_Base> shopItemClass;
	local array<class< Object > > shopItemClasses;
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
	shopItemClasses = class'Hat_ClassHelper'.static.GetAllScriptClasses("Archipelago_ShopItem_Base");
	
	for (i = 0; i <= count; i++)
	{
		jsonChild = jsonObj.GetObject("locations_"$i);
		if (jsonChild == None)
			continue;
		
		if (m.GetShopItemClassFromLocation_Cheap(shopItemClasses, jsonChild.GetIntValue("location"), shopItemClass))
		{
			if (!m.GetShopItemInfo(shopItemClass))
			{
				m.CreateShopItemInfo(shopItemClass, 
					m.GetStringValue2(jsonChild, "item"),
					jsonChild.GetIntValue("flags"),
					jsonChild.GetIntValue("player"));
			}
			
			continue;
		}
		
		isItem = false;
		
		foreach DynamicActors(class'Hat_Collectible_Important', collectible)
		{
			if (collectible.IsA('Hat_Collectible_VaultCode_Base') || collectible.IsA('Hat_Collectible_InstantCamera')
				|| collectible.IsA('Hat_Collectible_Sticker') || collectible.IsA('Hat_Collectible_MetroTicket_Base'))
				continue;
			
			locId = m.ObjectToLocationId(collectible);
			if (m.IsLocationCached(locId))
				continue;
			
			if (locId == jsonChild.GetIntValue("location"))
			{
				m.DebugMessage("Replacing item: "$collectible $", Location ID: "$locId);
				
				if (m.IsLocationChecked(locId))
				{
					collectible.Destroy();
					isItem = true;
					break;
				}
				
				m.CreateItem(locId, 
					m.GetStringValue2(jsonChild, "item"),
					jsonChild.GetIntValue("flags"),
					jsonChild.GetIntValue("player"),
					collectible);
				
				isItem = true;
				collectible.Destroy();
				break;
			}
		}
		
		if (isItem)
			continue;
		
		locId = jsonChild.GetIntValue("location");
		if (m.IsLocationIDContainer(locId, container))
		{
			itemId = m.GetStringValue2(jsonChild, "item");
			flags = jsonChild.GetIntValue("flags");
			
			locInfo.ID = locId;
			locInfo.ItemID = itemId;
			locInfo.Player = jsonChild.GetIntValue("player");
			locInfo.Flags = flags;
			locInfo.MapName = mapName;
			locInfo.ContainerClass = container.class;
			locInfo.IsStatic = false;
			
			class'Archipelago_ItemInfo'.static.GetNativeItemData(itemId, locInfo.ItemClass);
			m.SlotData.LocationInfoArray.AddItem(locInfo);
			continue;
		}
		
		if (locId == m.CameraBadgeCheck1 || locId == m.CameraBadgeCheck2)
		{
			if (m.IsLocationChecked(locId))
				continue;

			item = m.CreateItem(locId, 
				m.GetStringValue2(jsonChild, "item"),
				jsonChild.GetIntValue("flags"),
				jsonChild.GetIntValue("player"),
				,
				locId == m.CameraBadgeCheck1 ? m.Camera1Loc : m.Camera2Loc);
			
			if (item != None)
			{
				item.Init();
			}
		}
		else
		{
			// Time piece/page/etc
			itemId = m.GetStringValue2(jsonChild, "item");
			flags = jsonChild.GetIntValue("flags");
			
			locInfo.ID = locId;
			locInfo.ItemID = itemId;
			locInfo.Player = jsonChild.GetIntValue("player");
			locInfo.Flags = flags;
			locInfo.MapName = m.IsLocationIDPage(locId) ? mapName : "";
			locInfo.ContainerClass = None;
			locInfo.IsStatic = !m.IsLocationIDPage(locId);
			
			class'Archipelago_ItemInfo'.static.GetNativeItemData(itemId, locInfo.ItemClass);
			m.SlotData.LocationInfoArray.AddItem(locInfo);
		}
	}
	
	if (!m.IsMapScouted(mapName))
	{
		m.SetAPBits("MapScouted_"$Locs(mapName), 1);
	}
	
	m.SaveGame();
	
	jsonObj = None;
	jsonChild = None;
}

function OnReceivedItemsCommand(string json)
{
	local int count, serverIndex, index, total, i, start, item;
	local string s;
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
	serverIndex = jsonObj.GetIntValue("index");
	
	// This means we are reconnecting to a previous session, and the server is giving us our entire list of items,
	// so we need to begin from the next new item in our list or don't give anything otherwise
	m.DebugMessage("serverIndex: "$serverIndex);
	m.DebugMessage("index: "$index);
	if (serverIndex == 0 && index > 0)
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
	
	m.DebugMessage("start: "$start);
	for (i = start; i <= count; i++)
	{
		jsonChild = jsonObj.GetObject("items_"$i);
		if (jsonChild != None)
		{
			// this should absolutely never be a 64 bit integer, so we can safely pass as an int
			item = jsonChild.GetIntValue("item");
			if (item > 0)
			{
				GrantItem(item);
				total++;
			}
		}
	}
	
	jsonObj = None;
	jsonChild = None;
	m.SetAPBits("LastItemIndex", index+total);
	m.SaveGame();
}

function GrantItem(int itemId)
{
	local class<Actor> worldClass, invOverride;
	local class<Hat_SnatcherContract_Act> contract;
	local Archipelago_RandomizedItem_Base item;
	local Pawn player;
	local ESpecialItemType special;
	local ETrapType trap;
	local Hat_SaveGame save;
	local Hat_MetroTicketGate gate;
	
	if (class'Archipelago_ItemInfo'.static.GetNativeItemData(string(itemId), worldClass, invOverride))
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
		
		if (itemId == class'Archipelago_ItemInfo'.static.GetTimePieceItemID())
		{
			GrantTimePiece();
		}
		else if (itemId == 2000300003) // Progressive painting
		{
			UnlockPaintings();
		}
		else if (itemId >= 2000300045 && itemId <= 2000300048)
		{
			// Metro ticket. Update gates if we're currently in Metro
			if (`GameManager.GetCurrentMapFilename() ~= "dlc_metro")
			{
				foreach DynamicActors(class'Hat_MetroTicketGate', gate)
					gate.DelayedInit();
			}
		}
		else if (itemId >= 2000300049 && itemId <= 2000300053)
		{
			// This is a hat, make sure hats are in the correct order for swapping
			`AP.SortPlayerHats();
		}
		else
		{
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
		}
		
		/*
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
		*/
	}
	else
	{
		// screen message so players report
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
	else if (itemId == 2000300204 || itemId == 2000300205 || itemId == 2000300206 || itemId == 2000300207)
	{
		UnlockZipline(itemId);
	}
}

function GrantTimePiece()
{
	local Archipelago_GameMod m;
	local String hg;
	local int tpCount;
	
	tpCount = `SaveManager.GetNumberOfTimePieces();
	hg = "ap_timepiece"$tpCount;
	
	// Zero Jumps fix
	class'Hat_SaveBitHelper'.static.SetLevelBits(
		class'Hat_SnatcherContract_DeathWish_NoAPresses'.static.GetObjectiveBitID()$"_TimePieceCollected_"$hg, 1, "subconforest");
	
	`SaveManager.GetCurrentSaveData().GiveTimePiece(hg, false);
	
	m = `AP;
	if (m.IsInSpaceship() && m.SlotData.Initialized)
	{
		m.UpdateActUnlocks();
		m.UpdatePowerPanels();

		if (m.SlotData.DeathWish && `SaveManager.GetNumberOfTimePieces() >= m.SlotData.DeathWishTPRequirement)
		{
			if (!class'Hat_SaveBitHelper'.static.HasLevelBit("DeathWish_intro", 1, `GameManager.HubMapName))
			{
				m.ScreenMessage("***DEATH WISH has been unlocked! Check your pause menu in the Spaceship!***", 'Warning');
				m.ScreenMessage("***DEATH WISH has been unlocked! Check your pause menu in the Spaceship!***", 'Warning');
				m.ScreenMessage("***DEATH WISH has been unlocked! Check your pause menu in the Spaceship!***", 'Warning');
			}
			
			class'Hat_SaveBitHelper'.static.SetLevelBits("DeathWish_intro", 1, `GameManager.HubMapName);
		}
	}
}

function UnlockZipline(int id)
{
	local string zipline;
	
	switch (id)
	{
		case 2000300204: // Birdhouse Path
			zipline = "Hat_SandTravelNode_44";
			break;
		
		case 2000300205: // Lava Cake Path
			zipline = "Hat_SandTravelNode_15";
			break;
		
		case 2000300206: // Windmill Path
			zipline = "Hat_SandTravelNode_17";
			break;
		
		case 2000300207: // Twilight Bell Path
			zipline = "Hat_SandTravelNode_43";
			break;
		
		default:
			return;
	}
	
	`AP.SetAPBits("ZiplineUnlock_"$zipline, 1);
}

function UnlockPaintings()
{
	local int count;
	local Archipelago_GameMod m;
	local Hat_SubconPainting painting;
	m = `AP;
	
	count = m.GetAPBits("PaintingUnlock", 0) + 1;
	m.SetAPBits("PaintingUnlock", count);
	
	switch (count)
	{
		// Village
		case 1:
			m.SetAPBits("Hat_SubconPainting_Yellow_5", 1);
			m.SetAPBits("Hat_SubconPainting_Yellow_6", 1);
			m.SetAPBits("Hat_SubconPainting_Yellow_7", 1);
			m.SetAPBits("Hat_SubconPainting_Yellow_8", 1);
			break;
		
		// Swamp
		case 2:
			m.SetAPBits("Hat_SubconPainting_Blue_2", 1);
			m.SetAPBits("Hat_SubconPainting_Blue_6", 1);
			break;
		
		// Courtyard
		case 3:
			m.SetAPBits("Hat_SubconPainting_Green_0", 1);
			m.SetAPBits("Hat_SubconPainting_Green_1", 1);
			m.SetAPBits("Hat_SubconPainting_Green_2", 1);
			m.SetAPBits("Hat_SubconPainting_Green_3", 1);
			m.SetAPBits("Hat_SubconPainting_Green_4", 1);
			break;
		
		default:
			break;
	}
	
	if (`GameManager.GetCurrentMapFilename() ~= "subconforest")
	{
		foreach DynamicActors(class'Hat_SubconPainting', painting)
		{
			if (m.HasAPBit(string(painting.Name), 1))
			{
				painting.SetHidden(false);
				painting.SetCollision(true, true);
			}
		}
	}
}

function DoSpecialItemEffects(ESpecialItemType special)
{
	local Hat_Player player;
	local array<class< Object > > skins;
	local array<class< Object > > flairs;
	
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
		
		case SpecialType_Cosmetic:
			skins = class'Hat_ClassHelper'.static.GetAllScriptClasses("Hat_Collectible_Skin");
			flairs = class'Hat_ClassHelper'.static.GetAllScriptClasses("Hat_CosmeticItemQualityInfo");
			if (Rand(2) == 1 || !GiveRandomFlair(flairs))
			{
				GiveRandomSkin(skins);
			}
			
			break;
			
		default:
			return;
	}
}

function bool GiveRandomSkin(array<class< Object > > skins)
{
	local class<Hat_Collectible_Skin> chosen;
	local array<class< Hat_Collectible_Skin > > candidates;
	local Hat_Loadout lo;
	local int i;
	
	lo = Hat_PlayerController(GetALocalPlayerController()).MyLoadout;
	for (i = 0; i < skins.Length; i++)
	{
		if (class<Hat_Collectible_Skin>(skins[i]).default.RequiredDLC != None &&
			!class'Hat_GameDLCInfo'.static.IsGameDLCInfoInstalled(class<Hat_Collectible_Skin>(skins[i]).default.RequiredDLC))
			continue;
		
		if (!lo.BackpackHasInventory(class<Hat_Collectible_Skin>(skins[i]))
		&& class<Hat_Collectible_Skin>(skins[i]).default.ItemQuality != None)
			candidates.AddItem(class<Hat_Collectible_Skin>(skins[i]));
	}
	
	if (candidates.Length > 0)
	{
		chosen = candidates[RandRange(0, candidates.Length-1)];
		`AP.ScreenMessage("Got Skin: "$chosen.static.GetLocalizedItemName());
		lo.AddBackpack(lo.MakeLoadoutItem(chosen));
		return true;
	}
	
	return false;
}

function bool GiveRandomFlair(array<class< Object > > flairs)
{
	local array<class< Hat_CosmeticItemQualityInfo > > candidates;
	local class<Hat_CosmeticItemQualityInfo> chosen;
	local Hat_Loadout lo;
	local int i;
	
	lo = Hat_PlayerController(GetALocalPlayerController()).MyLoadout;
	for (i = 0; i < flairs.Length; i++)
	{
		if (class<Hat_CosmeticItemQualityInfo>(flairs[i]).default.RequiredDLC != None &&
			!class'Hat_GameDLCInfo'.static.IsGameDLCInfoInstalled(class<Hat_CosmeticItemQualityInfo>(flairs[i]).default.RequiredDLC))
			continue;
		
		if (class<Hat_CosmeticItemQualityInfo>(flairs[i]).default.RequiredDLC == class'Hat_GameDLCInfo_KickstarterHat'
			|| class<Hat_CosmeticItemQualityInfo>(flairs[i]).default.ItemQuality == class'Hat_ItemQuality_Supporter')
			continue;
		
		if (class<Hat_CosmeticItemQualityInfo>(flairs[i]).default.SkinWeApplyTo != None)
			continue;
		
		if (!lo.BackpackHasInventory(class<Hat_CosmeticItemQualityInfo>(flairs[i]).static.GetBaseCosmeticItemWeApplyTo(), true, class<Hat_CosmeticItemQualityInfo>(flairs[i])) 
			&& class<Hat_CosmeticItemQualityInfo>(flairs[i]).default.CosmeticItemWeApplyTo != None
			&& lo.BackpackHasInventory(class<Hat_CosmeticItemQualityInfo>(flairs[i]).static.GetBaseCosmeticItemWeApplyTo()))
		{
			candidates.AddItem(class<Hat_CosmeticItemQualityInfo>(flairs[i]));
		}
	}
	
	if (candidates.Length > 0)
	{
		chosen = candidates[RandRange(0, candidates.Length-1)];
		`AP.ScreenMessage("Got Flair: "$class<Hat_Ability>(chosen.default.CosmeticItemWeApplyTo).static.GetLocalizedName(chosen));
		lo.AddBackpack(lo.MakeLoadoutItem(chosen.static.GetBaseCosmeticItemWeApplyTo(), chosen), false);
		return true;
	}
	
	return false;
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
			`AP.DeathLinked = true;
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

function OnRetrievedCommand(string json)
{
	local Archipelago_GameMod m;
	local class<Hat_SnatcherContract_DeathWish> dw;
	local array<class< Object> > dws;
	local int pos, i, v;
	local string s, hourglass;
	local bool b;
	local JsonObject jsonObj, jsonChild;
	
	m = `AP;
	hourglass = "";
	pos = InStr(json, "\"ahit_clearedacts_"$`AP.SlotData.PlayerSlot$"\":[");
	
	if (pos != -1)
	{
		pos += Len("\"ahit_clearedacts_"$`AP.SlotData.PlayerSlot$"\":[");
		for (i = pos; i < Len(json); i++)
		{
			s = Mid(json, i, 1);
			if (s == "]")
			{
				break;
			}
			
			if (b)
			{
				if (s == "\"")
				{
					b = false;
					if (hourglass != "")
					{
						m.SetAPBits("ActComplete_"$hourglass, 1);
						hourglass = "";
					}
				}
				else
				{
					hourglass $= s;
				}
			}
			else if (s == "\"")
			{
				b = true;
			}
		}
	}
	
	if (m.SlotData.DeathWish)
	{
		jsonObj = class'JsonObject'.static.DecodeJson(json);
		jsonChild = jsonObj.GetObject("keys");
		dws = class'Hat_ClassHelper'.static.GetAllScriptClasses("Hat_SnatcherContract_DeathWish");
		for (i = 0; i < dws.Length; i++)
		{
			dw = class<Hat_SnatcherContract_DeathWish>(dws[i]);
			if (dw == class'Hat_SnatcherContract_DeathWish'
			|| dw == class'Hat_SnatcherContract_ChallengeRoad')
				continue;
			
			if (m.SlotData.ExcludedContracts.Find(dw) != -1 || m.SlotData.DeathWishShuffle && m.SlotData.ShuffledDeathWishes.Find(dw) == -1)
				continue;
			
			if (dw.static.IsContractPerfected())
				continue;
			
			s = jsonChild.GetStringValue(string(dw)$"_"$m.SlotData.PlayerSlot);
			if (s != "")
			{
				for (v = 0; v <= 2; v++)
				{
					if (InStr(s, string(v)) != -1)
						dw.static.ForceUnlockObjective(v);
				}
			}
		}
	}
	
	m.SaveGame();
	jsonObj = None;
	jsonChild = None;
}

function SendBinaryMessage(string message, optional bool continuation, optional bool pong, optional string nullChar="")
{
	local byte byteMessage[255];
	local string buffer;
	local int length, offset, keyIndex, i, totalSent;
	local int maskKey[4];
	
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
		if (`AP.SlotData.ConnectedOnce)
			`AP.ScreenMessage("Connection was closed. Reconnecting in 5 seconds...");

		Refused = false;
	}
	
	CurrentMessage.Length = 0;
	EmptyCount = 0;
	ParsingMessage = false;
	FullyConnected = false;
	ConnectingToAP = false;
	Reconnecting = true;
	SetTimer(5.0, false, NameOf(Connect));
}

event Destroyed()
{
	Close();
	Super.Destroyed();
}

function bool ShouldFilterSelfJoins()
{
	if (Reconnecting || `AP.IsSaveFileJustLoaded())
		return false;
	
	return `AP.SlotData.ConnectedOnce;
}

defaultproperties
{
	bAlwaysTick = true;
}