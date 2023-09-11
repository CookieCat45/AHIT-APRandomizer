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
var transient bool GameDataLoaded;
var transient array<Archipelago_GameData> GamesToCache;

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
	
	ReceiveMode = RMODE_Manual;
	LinkMode = MODE_Line;
	
	if (!ShouldFilterSelfJoins())
	{
		`AP.ScreenMessage("Connecting to host: " $`AP.SlotData.Host$":"$`AP.SlotData.Port);
	}
	
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
	
	LinkMode = MODE_Binary;
	`AP.DebugMessage("Waiting for RoomInfo packet...");
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
	local int count, i, a, k, bracket;
	local string character, pong, msg, nullChar;
	local bool b, validMsg;
	
	Super.Tick(d);
	
	if (LinkState != STATE_Connected || LinkMode != MODE_Binary)
		return;
	
	// Messages from the AP server are not null-terminated, so it must be done this way.
	// We can only read 255 bytes from the socket at a time.
	// Also Unrealscript doesn't like [] in JSON.
	if (IsDataPending())
	{
		// IsDataPending seems to almost always return true even if no data is pending after a msg is sent, 
		// so to check for the end of a message, we simply count how many times we've read 0 bytes of data
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
		if (EmptyCount >= 5)
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
	local int i, a, count, split, pos, locId, count1, count2;
	local array<int> missingLocs;
	local string s, text, num, json2, game, checksum, player;
	local JsonObject jsonObj, jsonChild, games, myGame, mappings, textObj;
	local Archipelago_GameMod m;
	local Archipelago_GameData data;
	local LocationMap locMapping;
	local ItemMap itemMapping;
	
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
		
		// Also dumb, but seems to fix crashing problems, hopefully.
		split = InStr(json, ",{\"cmd\":\"ReceivedItems\"");
		if (split != -1)
		{
			json = Repl(json, Mid(json, split), "", false);
		}
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
		m.DebugMessage("[ParseJSON] [WARNING] Encountered JSON message with mismatching braces. Cancelling to prevent crash!", , true);
		return;
	}
	
	jsonObj = new class'JsonObject';
	jsonObj = class'JsonObject'.static.DecodeJson(json);
	if (jsonObj == None)
	{
		m.DebugMessage("[ParseJSON] Failed to parse JSON: " $json, , true);
		return;
	}
	
	switch (jsonObj.GetStringValue("cmd"))
	{
		case "RoomInfo":
			if (GameDataLoaded)
			{
				m.DebugMessage("Received RoomInfo packet, sending Connect packet...");
				ConnectToAP();
				break;
			}
			
			games = jsonObj.GetObject("datapackage_checksums");
			json2 = games.EncodeJson(games);
			
			b = true;
			game = "";
			
			for (i = 0; i < Len(json2); i++)
			{
				if (!b && Mid(json2, i, 2) == "\",") // start of game name string
				{
					b = true;
				}
				else if (b && Mid(json2, i, 2) == "\":") // end of game name string
				{
					m.DebugMessage("Found game: " $game);
					data = new class'Archipelago_GameData';
					class'Engine'.static.BasicLoadObject(data, "APGameData/"$game, false, 1);
					
					// do we need to update the data for this game, or create it?
					checksum = games.GetStringValue(game);
					if (data.Game == "" || data.Checksum != checksum)
					{
						data.Game = game;
						data.Checksum = checksum;
						GamesToCache.AddItem(data);
					}
					else
					{
						m.GameData.AddItem(data);
					}
					
					game = "";
					b = false;
				}
				else if (b)
				{
					s = Mid(json2, i, 1);
					
					if (s != "\"" && s != "{" && s != "}" && s != ",")
					{
						game $= Mid(json2, i, 1);
					}
				}
			}
			
			if (GamesToCache.Length > 0)
			{
				json2 = "[{\"cmd\":\"GetDataPackage\",\"games\":[";
				for (i = 0; i < GamesToCache.Length; i++)
				{
					json2 $= "\""$GamesToCache[i].Game$"\"";
					if (i < GamesToCache.Length-1)
					{
						json2 $= ",";
					}
					else
					{
						json2 $= "]}]";
					}
				}
				
				m.ScreenMessage("Reading new game location/item data...");
				SendBinaryMessage(json2);
			}
			else
			{
				GameDataLoaded = true;
			}
			
			m.DebugMessage("Received RoomInfo packet, sending Connect packet...");
			ConnectToAP();
			break;
		
		case "DataPackage":
			if (GameDataLoaded)
				break;
			
			m.DebugMessage("Reading data package...");
			games = jsonObj.GetObject("data").GetObject("games");
			if (games == None)
			{
				m.DebugMessage("Failed to read datapackage!", , true);
				break;
			}
			
			for (i = 0; i < GamesToCache.Length; i++)
			{
				myGame = games.GetObject(GamesToCache[i].Game);
				if (myGame == None)
				{
					m.DebugMessage("Failed to cache game: " $GamesToCache[i].Game, , true);
					continue;
				}
			
				mappings = myGame.GetObject("item_name_to_id");
				json2 = mappings.EncodeJson(mappings);
				
				for (a = 0; a < Len(json2); a++)
				{
					if (Mid(json2, a, 1) == "\"")
					{
						if (!b)
						{
							b = true;
						}
						else
						{
							// Found an item
							m.DebugMessage("Found item: " $s $", game: " $GamesToCache[i].Game);
							itemMapping.ID = mappings.GetIntValue(s);
							itemMapping.Item = s;
							GamesToCache[i].ItemMappings.AddItem(itemMapping);
							s = "";
							b = false;
						}
					}
					else if (b)
					{
						s $= Mid(json2, a, 1);
					}
				}
				
				mappings = myGame.GetObject("location_name_to_id");
				json2 = mappings.EncodeJson(mappings);
				b = false;
				s = "";
				
				for (a = 0; a < Len(json2); a++)
				{
					if (Mid(json2, a, 1) == "\"")
					{
						if (!b)
						{
							b = true;
						}
						else
						{
							// Found a location
							m.DebugMessage("Found location: " $s $", game: " $GamesToCache[i].Game);
							locMapping.ID = mappings.GetIntValue(s);
							locMapping.Location = s;
							GamesToCache[i].LocationMappings.AddItem(locMapping);
							b = false;
							s = "";
						}
					}
					else if (b)
					{
						s $= Mid(json2, a, 1);
					}
				}
				
				class'Engine'.static.BasicSaveObject(GamesToCache[i], "APGameData/"$GamesToCache[i].Game, false, 1);
				m.GameData.AddItem(GamesToCache[i]);
			}
			
			GameDataLoaded = true;
			break;
		
		case "Connected":
			m.OnPreConnected();
			
			if (!ShouldFilterSelfJoins())
				m.ScreenMessage("Successfully connected to " $m.SlotData.Host $":"$m.SlotData.Port);
			
			m.SlotData.PlayerSlot = jsonObj.GetIntValue("my_slot");
			FullyConnected = true;
			ConnectingToAP = false;
			
			if (!m.SlotData.Initialized)
			{
				jsonChild = jsonObj.GetObject("slot_data");
				m.LoadSlotData(jsonChild);
			}
			
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
			
			// Fully connected
			m.OnFullyConnected();
			break;
			
			
		case "PrintJSON":
			if (ShouldFilterSelfJoins() && jsonObj.GetStringValue("type") == "Join")
			{
				if (InStr(json, m.SlotData.SlotName) != -1)
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
					
					case "item_id":
						text $= m.ItemIDToName(int(textObj.GetStringValue("text")));
						break;
					
					case "location_id":
						text $= m.LocationIDToName(int(textObj.GetStringValue("text")));
						break;
					
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
	myGame = None;
	games = None;
	mappings = None;
	textObj = None;
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
					jsonChild.GetIntValue("item"),
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
		
		if (isItem)
			continue;
		
		locId = jsonChild.GetIntValue("location");
		if (m.IsLocationIDContainer(locId, container))
		{
			itemId = jsonChild.GetIntValue("item");
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
		else
		{
			// Time piece/page/etc
			itemId = jsonChild.GetIntValue("item");
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

function OnReceivedItemsCommand(string json, optional bool connection)
{
	local int count, index, total, i, start;
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
			GrantItem(jsonChild.GetIntValue("item"), jsonChild.GetIntValue("player"));
			total++;
		}
	}
	
	jsonObj = None;
	jsonChild = None;
	m.SetAPBits("LastItemIndex", index+total);
	m.SaveGame();
}

function GrantItem(int itemId, int playerId)
{
	local class<Actor> worldClass, invOverride;
	local class<Hat_SnatcherContract_Act> contract;
	local Archipelago_RandomizedItem_Base item;
	local Pawn player;
	local ESpecialItemType special;
	local ETrapType trap;
	local Hat_SaveGame save;
	local Hat_MetroTicketGate gate;
	
	if (class'Archipelago_ItemInfo'.static.GetNativeItemData(itemId, worldClass, invOverride))
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
			GrantTimePiece(playerId);
		}
		else if (itemId == 300003) // Progressive painting
		{
			UnlockPaintings();
		}
		else if (itemId >= 300045 && itemId <= 300048)
		{
			// Metro ticket. Update gates if we're currently in Metro
			if (`GameManager.GetCurrentMapFilename() ~= "dlc_metro")
			{
				foreach DynamicActors(class'Hat_MetroTicketGate', gate)
					gate.DelayedInit();
			}
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

function GrantTimePiece(int playerId)
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
	}
}

function UnlockZipline(int id)
{
	local string zipline;
	
	switch (id)
	{
		case 300204: // Birdhouse Path
			zipline = "Hat_SandTravelNode_44";
			break;
		
		case 300205: // Lava Cake Path
			zipline = "Hat_SandTravelNode_15";
			break;
		
		case 300206: // Windmill Path
			zipline = "Hat_SandTravelNode_17";
			break;
		
		case 300207: // Twilight Bell Path
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
			m.SlotData.UnlockedPaintings.AddItem('Hat_SubconPainting_Yellow_5');
			m.SlotData.UnlockedPaintings.AddItem('Hat_SubconPainting_Yellow_6');
			m.SlotData.UnlockedPaintings.AddItem('Hat_SubconPainting_Yellow_7');
			m.SlotData.UnlockedPaintings.AddItem('Hat_SubconPainting_Yellow_8');
			break;
		
		// Swamp
		case 2:
			m.SlotData.UnlockedPaintings.AddItem('Hat_SubconPainting_Blue_2');
			m.SlotData.UnlockedPaintings.AddItem('Hat_SubconPainting_Blue_6');
			break;
		
		// Courtyard
		case 3:
			m.SlotData.UnlockedPaintings.AddItem('Hat_SubconPainting_Green_0');
			m.SlotData.UnlockedPaintings.AddItem('Hat_SubconPainting_Green_1');
			m.SlotData.UnlockedPaintings.AddItem('Hat_SubconPainting_Green_2');
			m.SlotData.UnlockedPaintings.AddItem('Hat_SubconPainting_Green_3');
			m.SlotData.UnlockedPaintings.AddItem('Hat_SubconPainting_Green_4');
			break;
		
		default:
			break;
	}
	
	if (`GameManager.GetCurrentMapFilename() ~= "subconforest")
	{
		foreach DynamicActors(class'Hat_SubconPainting', painting)
		{
			if (m.SlotData.UnlockedPaintings.Find(painting.Name) != -1)
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
		lo.AddBackpack(lo.MakeLoadoutItem(candidates[RandRange(0, candidates.Length-1)]));
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
	
	m = `AP;
	
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
		//if (!`AP.SlotData.ConnectedOnce)
		//{
		//	`AP.ScreenMessage("Connection was closed. Try connecting via Archipelago WSS Proxy if you're connecting to the beta (24242) site.");
		//}
		if (!ShouldFilterSelfJoins())
		{
			`AP.ScreenMessage("Connection was closed. Reconnecting in 5 seconds...");
		}
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

function bool IsWSSProxyMode()
{
	return bool(`AP.WSSMode);
}

function bool ShouldFilterSelfJoins()
{
	if (bool(`AP.FilterSelfJoins))
		return `AP.SlotData.ConnectedOnce;
	
	return false;
}

defaultproperties
{
	bAlwaysTick = true;
}