class Archipelago_GameMod extends GameMod
	dependson(Archipelago_HUDElementBubble)
	config(Mods);

var Archipelago_TcpLink Client;
var Archipelago_BroadcastHandler Broadcaster;
var Archipelago_SlotData SlotData;
var Archipelago_ItemResender ItemResender;
var int PlayerSlot;
var bool ActMapChange;
var bool IsItemTimePiece; // used to tell if a time piece being given to us is from AP or not
var array<string> PlayerNames;

var config bool DebugMode;
var config bool DisableInjection;

struct immutable ShuffledAct
{
	var Hat_ChapterActInfo OriginalAct;
	var Hat_ChapterActInfo NewAct;
	var bool IsDeadBirdBasementOriginalAct;
	var bool IsDeadBirdBasementShuffledAct;
};

struct immutable ShopItemInfo
{
	var class<Archipelago_ShopItem_Base> ItemClass;
	var int ItemID;
	var int ItemFlags;
};

var array<ShopItemInfo> ShopItemList;

// Level bit prefix
const ArchipelagoPrefix = "AP_";

// Location ID ranges
const BaseIDRange = 300000;
const ActCompleteIDRange = 310000;
const Chapter3IDRange = 320000;
const Chapter4IDRange = 330000;
const StoryBookPageIDRange = 340000;

// Event checks
const RumbiYarnCheck = 301000;
const CookingCatRelicCheck = 301001;
const UmbrellaCheck = 301002;

// Traps
var transient int BabyCount;
var transient int LaserCount;
var int ParadeTrapMembers;
var float ParadeTrapDelay;
var float ParadeTrapSpread;

// Other things
var array<Hat_TreasureChest_Base> ChestArray;
var array<Hat_NPC> BulliedNPCArray;
var array<Hat_Enemy_ScienceBand_Base> ParadeArray;
var array<Texture2D> UnlockScreenNumbers;

event OnModLoaded()
{
	HookActorSpawn(class'Hat_Player', 'Player');
}

event OnModUnloaded()
{
	if (Client != None)
		Client.Destroy();
	
	if (Broadcaster != None)
		Broadcaster.Destroy();
}

event OnHookedActorSpawn(Object newActor, Name identifier)
{
	if (identifier == 'Player')
	{
		if (newActor.IsA('Hat_Player_MustacheGirl'))
			return;
			
		// Need to do this on a timer to prevent the game from overriding our actions
		SetTimer(0.3, false, NameOf(EnableConsoleCommands));
	}
}

// Override the player's input class so we can use our own console commands (without conflicting with Console Commands Plus)
function EnableConsoleCommands()
{
	local Hat_PlayerController c;
	
	c = Hat_PlayerController(GetALocalPlayerController());
	c.Interactions.RemoveItem(c.PlayerInput);
	c.PlayerInput = None;
	c.InputClass = class'Archipelago_CommandHelper';
	c.InitInputSystem();
}

function CreateClient(optional float delay=0.0)
{
	if (delay > 0.0)
	{
		SetTimer(delay, false, NameOf(CreateClient));
		return;
	}

	client = Spawn(class'Archipelago_TcpLink');
}

event PreBeginPlay()
{
	Super.PreBeginPlay();
	
	if (DisableInjection || `GameManager.GetCurrentMapFilename() ~= `GameManager.TitleScreenMapName)
		return;
	
	if (!IsArchipelagoEnabled() && `SaveManager.GetCurrentSaveData().TotalPlayTime <= 0.0)
	{
		// New save file. Check if we can enable Archipelago.
		SetAPBits("ArchipelagoEnabled", 1);
	}
}

event PostBeginPlay()
{
	Super.PostBeginPlay();
	
	if (!IsArchipelagoEnabled())
		return;
	
	`SaveManager.SetSavingEnabled(true);
	
	if (IsInSpaceship())
	{
		// Skip the intro cinematic so we don't go to Mafia Town
		class'Hat_SaveBitHelper'.static.SetLevelBits("hub_cinematics", 1);
	}
	
	if (ItemResender == None)
	{
		ItemResender = new class'Archipelago_ItemResender';
	}
}

function OnPostInitGame()
{
	local string path;
	local Hat_TreasureChest_Base chest;
	local Hat_SaveGame_Base save;
	local Actor a;
	local int i, saveCount;
	local Hat_NPC mu;
	
	// If on titlescreen, find any Archipelago-enabled save files and do this stuff 
	// to prevent the game from forcing the player into Mafia Town.
	if (`GameManager.GetCurrentMapFilename() ~= `GameManager.TitleScreenMapName)
	{
		saveCount = `SaveManager.NumUsedSaveSlots();
		
		for (i = 0; i < saveCount; i++)
		{
			save = `SaveManager.GetSaveSlot(i);
			if (save == None)
				continue;
			
			if (HasAPBit("ArchipelagoEnabled", 1, save))
			{
				//class'Hat_SaveBitHelper'.static.SetLevelBits("hub_cinematics", 0, "hub_spaceship", save);
				Hat_SaveGame(save).AllowSaving = false;
			}
		}
	}

	if (!IsArchipelagoEnabled())
		return;
	
	if (DebugMode)
	{
		SetTimer(1.0, true, NameOf(PrintItemsNearPlayer));
	}
	
	if (IsInSpaceship())
	{
		// Stop Mustache Girl tutorial cutscene (it breaks when removing the yarn)
		// The player can still get the yarn by smacking Rumbi after getting 4 time pieces.
		foreach DynamicActors(class'Hat_NPC', mu)
		{
			if (mu.IsA('Hat_NPC_MustacheGirl'))
			{
				if (string(mu.Name) ~= "Hat_NPC_MustacheGirl_0")
				{
					// Set this level bit to 0 so that Rumbi will drop the yarn
					class'Hat_SaveBitHelper'.static.SetLevelBits("mu_preawakening_intruder_tutorial", 0);
					mu.ShutDown();
					break;
				}
			}
		}
		
		SetTimer(0.01, false, NameOf(ForceStandVisibility));
	}
	else
	{
		foreach DynamicActors(class'Actor', a)
		{
			if (a.IsA('Hat_NPC_BadgeSalesman') && !a.IsA('Archipelago_NPC_BadgeSalesman'))
			{
				if (a.bHidden)
					continue;
				
				Spawn(class'Archipelago_NPC_BadgeSalesman', , , a.Location, a.Rotation);
				a.Destroy();
			}
			else if (a.IsA('Hat_Collectible_Important'))
			{
				// Hide all regular collectibles, just in case
				a.ShutDown();
			}
		}
		
		// We need to do this early, before connecting, otherwise the game
		// might empty the chest on us if it has an important item in vanilla.
		// Example of this happening is the Hookshot Badge chest in the Subcon Well.
		// This will also prevent the player from nabbing vanilla chest contents as well.
		foreach DynamicActors(class'Hat_TreasureChest_Base', chest)
		{
			if (chest.Opened || class<Hat_Collectible_Important>(chest.Content) == None)
				continue;
			
			if (chest.IsA('Hat_TreasureChest_GiftBox'))
				continue;
			
			ChestArray.AddItem(chest);
			chest.Content = class'Hat_Collectible_EnergyBit';
		}
	}
	
	// check if our slot data is already saved to disk
	SlotData = new class'Archipelago_SlotData';
	path = "APRandomizer/slot_data"$`SaveManager.GetCurrentSaveData().CreationTimeStamp;
	
	if (class'Engine'.static.BasicLoadObject(SlotData, path, false, 1))
	{
		DebugMessage("Loaded slot data from file: "$path);
		SlotData.Initialized = true;
		UpdateChapterInfo();
	}
	else
	{
		DebugMessage("Couldn't find slot data, will retrieve from server on connect"$path);
	}
	
	if (Client == None)
		CreateClient();
}

function OpenSlotNameBubble(optional float delay=0.0)
{
	local Archipelago_HUDElementBubble bubble;
	local Hat_HUD hud;
	
	if (delay > 0.0)
	{
		SetTimer(delay, false, NameOf(OpenSlotNameBubble));
		return;
	}
	
	hud = Hat_HUD(Hat_PlayerController(GetALocalPlayerController()).MyHUD);
	bubble = Archipelago_HUDElementBubble(hud.OpenHUD(class'Archipelago_HUDElementBubble'));
	bubble.BubbleType = BubbleType_SlotName;
	bubble.OpenInputText(hud, "Archipelago", class'Hat_ConversationType_Internet', 'a', 25);
}

function OpenPasswordBubble(optional float delay=0.0)
{
	local Archipelago_HUDElementBubble bubble;
	local Hat_HUD hud;
	
	if (delay > 0.0)
	{
		SetTimer(delay, false, NameOf(OpenPasswordBubble));
		return;
	}
	
	hud = Hat_HUD(Hat_PlayerController(GetALocalPlayerController()).MyHUD);
	bubble = Archipelago_HUDElementBubble(hud.OpenHUD(class'Archipelago_HUDElementBubble'));
	bubble.BubbleType = BubbleType_Password;
	bubble.OpenInputText(hud, "Archipelago", class'Hat_ConversationType_Internet', 'a', 25);
}

function OpenConnectBubble(optional float delay=0.0)
{
	local Archipelago_HUDElementBubble bubble;
	local Hat_HUD hud;
	
	if (delay > 0.0)
	{
		SetTimer(delay, false, NameOf(OpenConnectBubble));
		return;
	}
	
	hud = Hat_HUD(Hat_PlayerController(GetALocalPlayerController()).MyHUD);
	bubble = Archipelago_HUDElementBubble(hud.OpenHUD(class'Archipelago_HUDElementBubble'));
	bubble.BubbleType = BubbleType_Connect;
	bubble.OpenInputText(hud, "Archipelago", class'Hat_ConversationType_Internet', 'a', 25);
}

// Called by client the moment a "Connected" packet is received from the Archipelago server.
// Slot data is not available at this point.
function OnPreConnected()
{
	
}

// Called by client when fully connected to Archipelago
// All slot data should be available at this point.
function OnFullyConnected()
{
	if (!IsInSpaceship())
	{
		ShuffleCollectibles();
	}
	
	// Have we beaten our seed? Send again in case we somehow weren't connected before.
	if (HasAPBit("HasBeatenGame", 1))
	{
		BeatGame();
	}
	
	// resend any locations we checked while not connected
	if (class'Engine'.static.BasicLoadObject(ItemResender, 
	"APRandomizer/item_resender"$`SaveManager.GetCurrentSaveData().CreationTimeStamp, false, 1))
	{
		DebugMessage("Loaded item resender successfully!");
		ItemResender.ResendLocations();
	}

	// Call this just to see if we can craft a hat
	OnYarnCollected(0);
}

function LoadSlotData(JsonObject json)
{
	local array<Hat_ChapterInfo> chapters;
	local array<string> actNames;
	local ShuffledAct actShuffle;
	local string n, path;
	local int i, j, v;
	
	if (SlotData.Initialized)
		return;
	
	SlotData.ActRando = json.GetBoolValue("ActRandomizer");
	SlotData.ShuffleStorybookPages = json.GetBoolValue("ShuffleStorybookPages");
	SlotData.DeathLink = json.GetBoolValue("death_link");
	
	SlotData.Chapter1Cost = json.GetIntValue("Chapter1Cost");
	SlotData.Chapter2Cost = json.GetIntValue("Chapter2Cost");
	SlotData.Chapter3Cost = json.GetIntValue("Chapter3Cost");
	SlotData.Chapter4Cost = json.GetIntValue("Chapter4Cost");
	SlotData.Chapter5Cost = json.GetIntValue("Chapter5Cost");

	SlotData.SprintYarnCost = json.GetIntValue("SprintYarnCost");
	SlotData.BrewingYarnCost = json.GetIntValue("BrewingYarnCost");
	SlotData.IceYarnCost = json.GetIntValue("IceYarnCost");
	SlotData.DwellerYarnCost = json.GetIntValue("DwellerYarnCost");
	SlotData.TimeStopYarnCost = json.GetIntValue("TimeStopYarnCost");
	
	// hat stitch order
	SlotData.Hat1 = EHatType(json.GetIntValue("Hat1"));
	SlotData.Hat2 = EHatType(json.GetIntValue("Hat2"));
	SlotData.Hat3 = EHatType(json.GetIntValue("Hat3"));
	SlotData.Hat4 = EHatType(json.GetIntValue("Hat4"));
	SlotData.Hat5 = EHatType(json.GetIntValue("Hat5"));

	if (SlotData.ActRando)
	{
		chapters = class'Hat_ChapterInfo'.static.GetAllChapterInfo();
		
		for (i = 0; i < chapters.Length; i++)
		{
			chapters[i].ConditionalUpdateActList();
			for (j = 0; j < chapters[i].ChapterActInfo.Length; j++)
				actNames.AddItem(PathName(chapters[i].ChapterActInfo[j]));
		}
		
		for (v = 0; v < actNames.Length; v++)
		{
			// HasKey() doesn't work :/
			n = json.GetStringValue(actNames[v]);
			if (n != "")
			{
				if (n ~= "DeadBirdBasement") // This needs a special flag
				{
					actShuffle = CreateShuffledAct(Hat_ChapterActInfo(DynamicLoadObject(actNames[v], class'Hat_ChapterActInfo')), None);
					actShuffle.IsDeadBirdBasementShuffledAct = true;
				}
				else
				{
					actShuffle = CreateShuffledAct(Hat_ChapterActInfo(DynamicLoadObject(actNames[v], class'Hat_ChapterActInfo')), 
													Hat_ChapterActInfo(DynamicLoadObject(n, class'Hat_ChapterActInfo')));
				}
				
				SlotData.ShuffledActList.AddItem(actShuffle);
				DebugMessage("FOUND act pair:" $actNames[v] $"REPLACED WITH: " $n);
			}
		}
		
		// This is what the basement was replaced with
		n = json.GetStringValue("DeadBirdBasement");
		actShuffle = CreateShuffledAct(None, Hat_ChapterActInfo(DynamicLoadObject(n, class'Hat_ChapterActInfo')));
		actShuffle.IsDeadBirdBasementOriginalAct = true;
		SlotData.ShuffledActList.AddItem(actShuffle);
		DebugMessage("FOUND act pair:" $"DeadBirdBasement" $"REPLACED WITH: " $n);
	}
	
	path = "APRandomizer/slot_data"$`SaveManager.GetCurrentSaveData().CreationTimeStamp;	
	if (class'Engine'.static.BasicSaveObject(SlotData, path, false, 1, true))
	{
		DebugMessage("Saved slot data to file successfully!");
	}
	
	SlotData.Initialized = true;
	UpdateChapterInfo();
}

function ShuffledAct CreateShuffledAct(Hat_ChapterActInfo originalAct, Hat_ChapterActInfo newAct)
{
	local ShuffledAct actShuffle;
	actShuffle.OriginalAct = originalAct;
	actShuffle.newAct = newAct;
	return actShuffle;
}

function OnPreActSelectMapChange(Object ChapterInfo, out int ActID, out string MapName)
{
	local Hat_ChapterActInfo act, shuffled, finale;
	local bool basementShuffle;
	local int basement;
	
	if (!IsArchipelagoEnabled())
		return;
	
	if (InStr(MapName, "timerift_", false, true) == 0)
		return;
	
	ActMapChange = true;
	
	if (Hat_ChapterInfo(ChapterInfo).ChapterID == 2)
	{
		finale = Hat_ChapterActInfo(DynamicLoadObject(
			"hatintime_chapterinfo.BattleOfTheBirds.BattleOfTheBirds_AwardCeremony", class'Hat_ChapterActInfo'));
		
		// If we are entering the Chapter 2 true finale, force Award Ceremony if it hasn't been completed
		if (MapName ~= "DeadBirdStudio")
		{
			if (ActID == 6)
			{
				if (!IsActReallyCompleted(finale))
				{
					if (!SlotData.ActRando)
					{
						MapName = "dead_cinema";
						return;
					}
					else
					{
						act = finale;
					}
				}
			}
			else // This is the actual Act 1
			{
				act = Hat_ChapterInfo(ChapterInfo).GetChapterActInfoFromActID(ActID);
			}
		}
		else if (MapName ~= "dead_cinema")
		{
			// On the other hand, if the game wants us to go to Award Ceremony instead of the true finale, don't if it's completed
			if (IsActReallyCompleted(finale))
			{
				if (!SlotData.ActRando)
				{
					MapName = "DeadBirdStudio";
					return;
				}
				else
				{
					basementShuffle = true;
				}
			}
		}
		else
		{
			act = Hat_ChapterInfo(ChapterInfo).GetChapterActInfoFromActID(ActID);
		}
	}
	else
	{
		act = Hat_ChapterInfo(ChapterInfo).GetChapterActInfoFromActID(ActID);
	}
	
	if (!SlotData.ActRando)
		return;
	
	basement = 0;

	// We're looking for the Chapter 2 finale's shuffled act if this is true
	if (basementShuffle)
	{
		shuffled = GetDeadBirdBasementShuffledAct(basement);
		if (basement == 1) // It's vanilla, just don't do anything at this point
		{
			return;
		}
	}
	else
	{
		// Normal act
		shuffled = GetShuffledAct(act, basement);
	}
	
	if (shuffled == None)
	{
		DebugMessage("[ERROR] Failed to find shuffled act for " $act);
		return;
	}
	
	if (basement == 1)
	{
		ActID = 6;
		MapName = "DeadBirdStudio";
	}
	else // Normal act shuffle
	{
		ActID = shuffled.ActID;
		MapName = shuffled.MapName;
		DebugMessage("Switching act " $PathName(act) $" with act: " $PathName(shuffled) $", map:" $MapName);
	}
}

function OnPreOpenHUD(HUD InHUD, out class<Object> InHUDElement)
{
	if (!IsArchipelagoEnabled())
		return;
	
	if (InHUDElement == class'Hat_HUDMenuShop')
	{
		SetTimer(0.0001, false, NameOf(CheckShopOverride), self, Hat_HUD(InHUD));
	}
	if (InHUDElement == class'Hat_HUDMenuActSelect')
	{
		class'Hat_SaveBitHelper'.static.SetLevelBits("Chapter3_Finale", 0, "hub_spaceship");
		InHUDElement = class'Archipelago_HUDMenuActSelect';
	}
	else if (InHUDElement == class'Hat_HUDElementActTitleCard' && SlotData.ActRando && !ActMapChange)
	{
		SetTimer(0.0001, false, NameOf(CheckActTitleCard), self, Hat_HUD(InHUD));
	}
}

function CheckShopOverride(Hat_HUD hud)
{
	local Actor merchant;
	local Hat_HUDMenuShop shop;
	local Archipelago_ShopInventory_MafiaBoss mShop;
	
	shop = Hat_HUDMenuShop(hud.GetHUD(class'Hat_HUDMenuShop'));
	merchant = shop.MerchantActor;
	
	if (merchant.IsA('Hat_NPC_MafiaBossJar'))
	{
		mShop = new class'Archipelago_ShopInventory_MafiaBoss';
		shop.SetShopInventory(hud, mShop);
	}
}

function CheckActTitleCard(Hat_HUD hud)
{
	local string map;
	local int actId, basement, chapterId;
	local Hat_HUDElementActTitleCard card;
	local Hat_ChapterActInfo newAct;
	
	card = Hat_HUDElementActTitleCard(hud.GetHUD(class'Hat_HUDElementActTitleCard', true));
	if (card.IsNonMapChangeTitlecard)
		return;
	
	if (InStr(card.MapName, "timerift_", false, true) == 0)
	{
		newAct = GetShuffledAct(GetRiftActFromMapName(card.MapName), basement);
		if (basement == 1)
		{
			chapterId = 2;
			actId = 6;
			map = "DeadBirdStudio";
		}
		else
		{
			chapterId = newAct.ChapterInfo.ChapterID;
			actId = newAct.ActID;
			map = newAct.MapName;
		}
		
		`GameManager.LoadNewAct(chapterId, actId);
		card.MapName = map;
		//card.SetTitleCardInfo(newAct.GetTitleCardBackground(), newAct.ChapterInfo.ChapterName, newAct.ActName);
	}
}

function OnTimePieceCollected(string Identifier)
{
	local int i, id;
	local Hat_ChapterActInfo currentAct;
	local string hourglass;
	
	if (!IsArchipelagoEnabled())
		return;
	
	// This level bit says this Time Piece was given to us as an item, so remove the Time Piece if it's not there
	if (!HasAPBit(Identifier, 1))
	{
		`SaveManager.GetCurrentSaveData().RemoveTimePiece(Identifier);
	}
	
	if (!IsItemTimePiece) // Not given by server
	{
		// This is the only goal for now
		if (Identifier ~= "TheFinale_FinalBoss")
			BeatGame();
	}
	
	for (i = 0; i < Len(Identifier); i++)
		id += Asc(Mid(Identifier, i, 1));
	
	id += ActCompleteIDRange;
	DebugMessage("Collected Time Piece: "$Identifier $", Location ID = " $id);
	
	// We actually completed this act, so set the Time Piece ID as a level bit
	if (SlotData.ActRando)
	{
		// We entered this act from a different act, set the original act's Time Piece instead
		currentAct = GetActualCurrentAct();
		
		for (i = 0; i < SlotData.ShuffledActList.Length; i++)
		{
			if (SlotData.ShuffledActList[i].NewAct == currentAct)
			{
				if (SlotData.ShuffledActList[i].IsDeadBirdBasementOriginalAct)
				{
					hourglass = "chapter3_secret_finale";
				}
				else
				{
					hourglass = SlotData.ShuffledActList[i].OriginalAct.hourglass;
				}
				
				DebugMessage("Completed act: " $SlotData.ShuffledActList[i].OriginalAct);
				break;
			}
		}
		
		SetAPBits("ActComplete_"$hourglass, 1);
	}
	else
	{
		SetAPBits("ActComplete_"$Identifier, 1);
	}
	
	SendLocationCheck(id);
}

function Hat_ChapterActInfo GetActualCurrentAct()
{
	local Hat_ChapterInfo chapter;
	local Hat_ChapterActInfo act;
	local string map;
	
	chapter = `GameManager.GetChapterInfo();
	map = `GameManager.GetCurrentMapFilename();
	chapter.ConditionalUpdateActList();
	
	if (InStr(map, "timerift_", false, true) == 0)
	{
		foreach chapter.ChapterActInfo(act)
		{
			DebugMessage(map $" " $act.MapName);
			if (act.MapName ~= map)
				return act;
		}
	}
	
	return `GameManager.GetChapterActInfo();
}

function UpdateChapterInfo()
{
	local Hat_SpaceshipPowerPanel panel;

	SetChapterTimePieceRequirement(Hat_ChapterInfo'HatinTime_ChapterInfo.maingame.MafiaTown', SlotData.Chapter1Cost);
	SetChapterTimePieceRequirement(Hat_ChapterInfo'HatinTime_ChapterInfo.maingame.trainwreck_of_science', SlotData.Chapter2Cost);
	SetChapterTimePieceRequirement(Hat_ChapterInfo'HatinTime_ChapterInfo.maingame.subconforest', SlotData.Chapter3Cost);
	SetChapterTimePieceRequirement(Hat_ChapterInfo'HatinTime_ChapterInfo.maingame.Sand_and_Sails', SlotData.Chapter4Cost);
	SetChapterTimePieceRequirement(Hat_ChapterInfo'HatinTime_ChapterInfo.maingame.Mu_Finale', SlotData.Chapter5Cost);
	
	if (IsInSpaceship())
	{
		UpdateActUnlocks();
		UpdatePowerPanels();
		
		foreach DynamicActors(class'Hat_SpaceshipPowerPanel', panel)
		{
			// Always open this door
			if (panel.ChapterInfo.ChapterID == 3)
			{
				panel.SpaceshipDoor.Enabled = true;
				panel.SpaceshipDoor.bBlocksNavigation = false;
				panel.SpaceshipDoor.SetLockedVisuals(false);
			}
		}
	}
}

function UpdateActUnlocks()
{
	local array<Hat_ChapterInfo> chapterInfoArray;
	local Hat_ChapterInfo chapter;
	local Hat_ChapterActInfo act;
	
	chapterInfoArray = class'Hat_ChapterInfo'.static.GetAllChapterInfo();
	foreach chapterInfoArray(chapter)
	{
		chapter.ConditionalUpdateActList();
		foreach chapter.ChapterActInfo(act)
		{
			// This set to true prevents the act from unlocking no matter what
			act.InDevelopment = (!IsChapterActInfoUnlocked2(act));

			if (!act.InDevelopment) // unlocked
			{
				//DebugMessage("Unlocked act: " $act);
				
				// Need to add a dummy act to required acts for blue rifts,
				// otherwise the game thinks it's a purple rift and it won't unlock.
				if (act.IsBonus && !IsPurpleRift(act))
				{
					act.RequiredActID.Length = 0;
					act.RequiredActID.AddItem(0);
				}
			}
		}
	}
}

function UpdatePowerPanels()
{
	local Hat_SpaceshipPowerPanel panel;
	local float val;
	
	foreach DynamicActors(class'Hat_SpaceshipPowerPanel', panel)
	{
		if (panel.CanBeUnlocked() && panel.InteractPoint == None && (!panel.RuntimeMat.GetScalarParameterValue('Unlocked', val) || val == 0))
		{
			panel.InteractPoint = Spawn(class'Hat_InteractPoint',panel,,panel.Location + Vector(panel.Rotation)*10 + vect(0,0,1)*20,panel.Rotation,,true);
			panel.InteractPoint.PushDelegate(panel.OnInteractDelegate);
			
			panel.RuntimeMat.SetScalarParameterValue('Unlockable', 1);
			panel.ElectricityParticle[0].SetActive(true);
			panel.ElectricityParticle[1].SetActive(true);
			panel.ReadyToActivateParticle.SetActive(true);
			panel.ClearTimer(NameOf(panel.DoAttentionBeep));
			panel.SetTimer(1.8, true, NameOf(panel.DoAttentionBeep));
		}
	}
}

function SetChapterTimePieceRequirement(Hat_ChapterInfo chapter, int amount)
{
	local Hat_SpaceshipPowerPanel panel;
	if (!SlotData.Initialized)
		return;

	chapter.RequiredHourglassCount = amount;
	
	if (IsInSpaceship())
	{
		foreach DynamicActors(class'Hat_SpaceshipPowerPanel', panel)
		{
			if (panel.GetChapterInfo() == chapter)
			{
				panel.RuntimeMat = panel.Mesh.CreateAndSetMaterialInstanceConstant(0);
				panel.RuntimeMat.SetTextureParameterValue('CountTexture', UnlockScreenNumbers[amount]);
				break;
			}
		}
	}
}

function bool IsChapterActInfoUnlocked2(Hat_ChapterActInfo ChapterActInfo, optional string ModPackageName)
{
	local string hourglass;
	local int j, actid;
	local Hat_ChapterInfo ChapterInfo;
	local Hat_ChapterActInfo RequiredChapterActInfo;
	local bool IsFreeRoam;
	
	ChapterInfo = ChapterActInfo.ChapterInfo;
	actid = ChapterActInfo.ActID;
	hourglass = ChapterActInfo.Hourglass;
	IsFreeRoam = IsActFreeRoam(ChapterActInfo);
	
	if (ChapterInfo == None) return false;
	if (!class'Hat_SeqCond_ChapterUnlocked'.static.IsChapterUnlocked(ChapterInfo)) return false;
	if (!ChapterActInfo.IsBonus && (actid <= 0 || actid > 99)) return false;
	if (!ChapterActInfo.IsBonus && (actid >= 99 || (ChapterInfo.ActIDAfterIntro > 0 && actid == ChapterInfo.ActIDAfterIntro)) && !IsFreeRoam) return false;
	if (hourglass == "" && !IsFreeRoam) return false;
	if (!ChapterActInfo.HasDLCSupported(true)) return false;
	
	if (ModPackageName != "")
	{
		hourglass = class'Hat_TimeObject_Base'.static.GetModTimePieceIdentifier(ModPackageName, hourglass);
	}
	
	// If actless and we don't have this Time Piece (and its not the finale nor free roam nor rift), skip!
	if (!ChapterActInfo.IsBonus && ChapterInfo.IsActless && (ChapterInfo.FinaleActID <= 0 || actid != ChapterInfo.FinaleActID) && !IsFreeRoam) 
		return false;
	
	// Subcon Forest
	if (!ChapterActInfo.IsBonus && !IsFreeRoam && actid > 1 && ChapterInfo.UnlockedByLevelBit != "")
	{
		return class'Hat_SaveBitHelper'.static.HasLevelBit(ChapterInfo.UnlockedByLevelBit, actid, ChapterInfo.GetActMap(1));
	}
	else if (IsPurpleRift(ChapterActInfo))
	{
		// Purple rift
		return `SaveManager.IsSecretLevelUnlocked(hourglass);
	}
	else // Normal act / Blue rift
	{
		// Check that we meet the Time Piece requirements to have unlocked this act
		for (j = 0; j < ChapterActInfo.RequiredActID.Length; j++)
		{
			if (ChapterActInfo.RequiredActID[j] <= 0) continue;
			
			RequiredChapterActInfo = ChapterInfo.GetChapterActInfoFromActID(ChapterActInfo.RequiredActID[j]);
			if (RequiredChapterActInfo == None) continue;
			
			hourglass = RequiredChapterActInfo.Hourglass;
			if (hourglass == "") continue;
			
			if (ModPackageName != "")
			{
				hourglass = class'Hat_TimeObject_Base'.static.GetModTimePieceIdentifier(ModPackageName, hourglass);
			}
			
			if (IsActReallyCompleted(RequiredChapterActInfo)) 
			{
				ChapterActInfo.RequiredActID.RemoveItem(RequiredChapterActInfo.ActID);
				continue;
			}
			
			j = INDEX_NONE;
			break;
		}
		
		return (j != INDEX_NONE);
	}
}

function bool IsPurpleRift(Hat_ChapterActInfo act)
{
	return (act.IsBonus && InStr(act.hourglass, "_cave", false, true) != INDEX_NONE);
}

function ShuffleCollectibles()
{
	local Hat_Collectible_Important collectible;
	local Hat_NPC npc;
	//local class<Actor> actorClass;
	local array<int> locationArray;
	local array<class<Object>> shopItemClasses;
	local class<Object> shopItem;
	
	foreach DynamicActors(class'Hat_Collectible_Important', collectible)
	{
		if (collectible.IsA('Hat_Collectible_VaultCode_Base') || collectible.IsA('Hat_Collectible_InstantCamera')
		|| collectible.IsA('Hat_Collectible_Sticker'))
			continue;
		
		locationArray.AddItem(ObjectToLocationId(collectible));
		if (DebugMode)
		{
			DebugMessage("[ShuffleCollectibles] Found item: " $collectible.GetLevelName() $"."$collectible.Name $ObjectToLocationId(collectible));
		}
	}
	
	// We can spawn the items when we receive a LocationInfo packet from the server; we still need the XYZ locations of the collectibles on the map
	if (locationArray.Length > 0)
		SendMultipleLocationChecks(locationArray, true);
		
	BulliedNPCArray.Length = 0;
	foreach DynamicActors(class'Hat_NPC', npc)
	{
		if (npc.bHidden || !npc.IsA('Hat_NPC_Bullied'))
			continue;
			
		BulliedNPCArray.AddItem(npc);
	}
	
	locationArray.Length = 0;
	shopItemClasses = class'Hat_ClassHelper'.static.GetAllScriptClasses("Archipelago_ShopItem_Base");
	
	foreach shopItemClasses(shopItem)
	{
		if (shopItem == class'Archipelago_ShopItem_Base')
			continue;
	
		locationArray.AddItem(class<Archipelago_ShopItem_Base>(shopItem).default.LocationID);
	}
	
	// scout shop items
	if (locationArray.Length > 0)
		SendMultipleLocationChecks(locationArray, true);
	
	if (ChestArray.Length > 0 || BulliedNPCArray.Length > 0)
		SetTimer(0.5, true, NameOf(IterateChestArray));
}

function bool GetShopItemClassFromLocation(int locationId, out class<Archipelago_ShopItem_Base> outClass)
{
	local array<class<Object>> shopItemClasses;
	local class<Object> shopItem;
	
	shopItemClasses = class'Hat_ClassHelper'.static.GetAllScriptClasses("Archipelago_ShopItem_Base");
	
	foreach shopItemClasses(shopItem)
	{
		if (shopItem == class'Archipelago_ShopItem_Base')
			continue;
		
		if (class<Archipelago_ShopItem_Base>(shopItem).default.LocationID == locationId)
		{
			outClass = class<Archipelago_ShopItem_Base>(shopItem);
			return true;
		}
	}
	
	return false;
}

function ShopItemInfo CreateShopItemInfo(class<Archipelago_ShopItem_Base> itemClass, int ItemID, int flags)
{
	local ShopItemInfo shopInfo;
	shopInfo.ItemClass = itemClass;
	shopInfo.ItemID = itemId;
	shopInfo.ItemFlags = flags;
	ShopItemList.AddItem(shopInfo);
	return shopInfo;
}

function int GetShopItemID(class<Archipelago_ShopItem_Base> itemClass)
{
	local int i;
	for (i = 0; i < ShopItemList.Length; i++)
	{
		if (ShopItemList[i].ItemClass == itemClass)
			return ShopItemList[i].ItemID;
	}
	
	return 0;
}

function bool GetShopItemInfo(class<Archipelago_ShopItem_Base> itemClass, optional out ShopItemInfo shopInfo)
{
	local int i;
	for (i = 0; i < ShopItemList.Length; i++)
	{
		if (ShopItemList[i].ItemClass == itemClass)
		{
			shopInfo = ShopItemList[i];
			return true;
		}
	}
	
	return false;
}

function IterateChestArray()
{
	local int i;
	local string message, bitName;
	local array<int> locationArray;
	
	if (ChestArray.Length <= 0 && BulliedNPCArray.Length <= 0)
	{
		ClearTimer(NameOf(IterateChestArray));
		return;
	}
	
	for (i = 0; i < ChestArray.Length; i++)
	{
		if (!ChestArray[i].FullOpened)
			continue;
			
		if (DebugMode)
		{
			message = "";
			message = class'Hat_SaveBitHelper'.static.GetCorrectedMapFilename(string(ChestArray[i].GetLevelName()));
			message $= "."$ChestArray[i].Name;
			message $= "("$ObjectToLocationId(ChestArray[i])$")";
			ScreenMessage(message);
		}
		
		locationArray.AddItem(ObjectToLocationId(ChestArray[i]));
		ChestArray.RemoveItem(ChestArray[i]);
	}
	
	for (i = 0; i < BulliedNPCArray.Length; i++)
	{
		bitName = class'Hat_SaveBitHelper'.static.GetBitId(BulliedNPCArray[i], 0);
		if (!class'Hat_SaveBitHelper'.static.HasLevelBit(bitName, 1))
			continue;
			
		if (DebugMode)
		{
			message = "";
			message = class'Hat_SaveBitHelper'.static.GetCorrectedMapFilename(string(BulliedNPCArray[i].GetLevelName()));
			message $= "."$BulliedNPCArray[i].Name;
			message $= "("$ObjectToLocationId(BulliedNPCArray[i])$")";
			ScreenMessage(message);
		}
		
		locationArray.AddItem(ObjectToLocationId(BulliedNPCArray[i]));
		BulliedNPCArray.RemoveItem(BulliedNPCArray[i]);
	}
	
	if (locationArray.Length > 0)
	{
		SendMultipleLocationChecks(locationArray);
	}
}

// for breakable objects that contain important items
function OnPreBreakableBreak(Actor Breakable, Pawn Breaker)
{
	local Hat_ImpactInteract_Breakable_ChemicalBadge b;
	local class<Actor> spawnClass;
	local Archipelago_RandomizedItem_Misc item;
	local int i;
	local bool hasImportantItem;
	local string message;
	local Rotator rot;
	local Vector vel;
	local float rangeMin, rangeMax;
	
	if (!IsArchipelagoEnabled())
		return;
	
	if (Breakable.IsA('Hat_ImpactInteract_Breakable_ChemicalBadge'))
	{
		b = Hat_ImpactInteract_Breakable_ChemicalBadge(Breakable);
		if (b.Rewards.Length <= 0)
			return;
		
		for (i = 0; i < b.Rewards.Length; i++)
		{
			if (class<Hat_Collectible_Important>(b.Rewards[i]) == None)
				continue;
			
			b.Rewards.RemoveItem(b.Rewards[i]);
			hasImportantItem = true;
		}
		
		if (hasImportantItem)
		{
			if (DebugMode)
			{
				message = class'Hat_SaveBitHelper'.static.GetCorrectedMapFilename(string(b.GetLevelName()));
				message $= "."$b.Name;
				message $= "("$ObjectToLocationId(b)$")";
				ScreenMessage(message);
			}
			
			spawnClass = class'Archipelago_RandomizedItem_Misc';
			item = Archipelago_RandomizedItem_Misc(Spawn(spawnClass,,,b.Location + vect(0,0,50),,,true));
			item.LocationId = ObjectToLocationId(b);
			
			rangeMin = 65536 / 16;
			rangeMax = 65536 / 8;
			rot.Yaw = RandRange(65536 * -1,65536);
			rot.Pitch = 16384 + RandRange(rangeMin,rangeMax);
			vel = Vector(rot)*RandRange(150,300) + vect(0,0,1)*RandRange(200,500);
			item.Bounce(vel);
		}
	}
}

function OnPlayerDeath(Pawn Player)
{
	local string message;
	if (!IsDeathLinkEnabled() || !IsArchipelagoEnabled() || !IsFullyConnected())
		return;
	
	message = "[{\"cmd\":\"Bounce\",\"tags\":[\"DeathLink\"],\"data\":{\"time\":" $float(TimeStamp()) $",\"source\":\"CookieHat\",\"cause\":\"\"}}]";
	client.SendBinaryMessage(message);
}

function OnLoadoutChanged(PlayerController controller, Object loadout, Object backpackItem)
{
	local Hat_BackpackItem item;

	if (!IsArchipelagoEnabled())
		return;
	
	item = Hat_BackpackItem(backpackItem);
	if (item == None)
		return;
	
	// remove base game umbrella in favor of our own. This is the umbrella check in Mafia Town.
	if (class<Hat_Weapon_Umbrella>(item.BackpackClass) != None 
	&& class<Archipelago_Weapon_Umbrella>(item.BackpackClass) == None)
	{
		Hat_Loadout(loadout).RemoveBackpack(item);
		SendLocationCheck(UmbrellaCheck);
	}
}

function OnCollectibleSpawned(Object collectible)
{
	local Archipelago_RandomizedItem_Misc item;
	local class<Actor> spawnClass;
	local Vector vel;
	local Rotator rot;
	local float range;
	
	if (!IsArchipelagoEnabled() || collectible.IsA('Archipelago_RandomizedItem_Base')
	|| collectible.IsA('Archipelago_ShopItem_Base'))
		return;
	
	if (IsInSpaceship())
	{
		if (collectible.IsA('Hat_Collectible_BadgePart_Sprint'))
		{
			// Rumbi yarn
			Actor(collectible).Destroy();
			SendLocationCheck(RumbiYarnCheck);
		}
		else if (collectible.IsA('Hat_Collectible_Decoration_BurgerTop'))
		{
			// Cooking Cat relic
			Actor(collectible).ShutDown();
			Hat_Collectible_Important(collectible).InventoryClass = None;
			Hat_Collectible_Important(collectible).CollectSound = None;
			Hat_Collectible_Important(collectible).SkipFirstTimeMessage = true;
			SendLocationCheck(CookingCatRelicCheck);
		}
	}
	else if (Hat_Collectible_Important(collectible) != None && Actor(collectible).CreationTime > 0)
	{
		DebugMessage(collectible.Name $"Owner Name: " $Actor(collectible).Owner.Name);
		
		if (Actor(collectible).Owner != None)
		{
			if (Actor(collectible).Owner.IsA('Hat_Goodie_Vault_Base'))
			{
				// We don't have the data of this item so just spawn a misc
				spawnClass = class'Archipelago_RandomizedItem_Misc';
				item = Archipelago_RandomizedItem_Misc(Spawn(spawnClass,,,Actor(collectible).Location, Actor(collectible).Rotation,,true));
				item.LocationId = ObjectToLocationId(Actor(collectible).Owner);
				
				rot = item.Rotation;
				range = 65536/8;
				rot.Yaw += RandRange(range*-1,range);
				rot.Pitch += RandRange(range*-1,range);
				vel = Vector(rot)*RandRange(150,300) + vect(0,0,1)*RandRange(200,500);
				item.Bounce(vel);
				
				Actor(collectible).Destroy();
			}
		}
		else if (collectible.IsA('Hat_Collectible_HatPart'))
		{
			// probably a yarn spawned by one of the old guys in Mafia Town. Remove it.
			Actor(collectible).Destroy();
		}
	}
}

function OnCollectedCollectible(Object collectible)
{
	local string message;
	local Archipelago_RandomizedItem_Base item;
	
	if (DebugMode && collectible.IsA('Hat_Collectible_Important'))
	{
		// Show location ID
		message = class'Hat_SaveBitHelper'.static.GetCorrectedMapFilename(string(Actor(collectible).GetLevelName()));
		message $= "."$collectible.Name;
		message $= "("$ObjectToLocationId(collectible)$")";
		DebugMessage(message);
	}
	
	if (!IsArchipelagoEnabled())
		return;
	
	// If this is an Archipelago item or a storybook page, send it
	if (SlotData.ShuffleStorybookPages && collectible.IsA('Hat_Collectible_StoryBookPage'))
	{
		SendLocationCheck(ObjectToLocationId(collectible));
	}
	else // Normal item
	{
		item = Archipelago_RandomizedItem_Base(collectible);
		
		if (item != None && !item.WasFromServer())
			SendLocationCheck(item.LocationId);
	}
}

function OnYarnCollected(optional int amount=1)
{
	local int count, cost, index, pons;
	local Hat_PlayerController pc;
	local Hat_Loadout loadout;
	local Hat_BackpackItem item;
	local class<Hat_Ability> abilityClass;
	
	count = GetAPBits("TotalYarnCollected", 0) + amount;
	SetAPBits("TotalYarnCollected", count);
	`GameManager.AddBadgePoints(amount);
	
	if (!SlotData.Initialized)
		return;
	
	foreach DynamicActors(class'Hat_PlayerController', pc)
	{
		loadout = pc.MyLoadout;
		break;
	}
	
	abilityClass = GetNextHat();
	cost = GetHatYarnCost(abilityClass);
	index = GetAPBits("HatCraftIndex", 1);
	
	if (abilityClass != None)
	{
		if (amount > 0)
		{
			ScreenMessage("Yarn: "$count $"/"$cost);
		}
		
		// Stitch our new hat!
		if (count >= cost)
		{
			item = class'Hat_Loadout'.static.MakeLoadoutItem(abilityClass);
			loadout.AddBackpack(item);
			PlayHatStitchAnimation(pc, item);
			ScreenMessage("Got " $GetHatName(abilityClass));
			
			`GameManager.AddBadgePoints(-cost);
			SetAPBits("TotalYarnCollected", 0);
			SetAPBits("HatCraftIndex", index+1);
		}
	}
	else
	{
		pons = 20 * amount;
		`GameManager.AddEnergyBits(pons);
		ScreenMessage("Got " $pons $" Pons");
	}
}

function class<Hat_Ability> GetNextHat()
{
	switch (EHatType(GetAPBits("HatCraftIndex", 1)))
	{
		case HatType_Sprint: 
			return class'Hat_Ability_Sprint';
		
		case HatType_Brewing: 
			return class'Hat_Ability_Chemical';
		
		case HatType_Ice: 
			return class'Hat_Ability_StatueFall';
		
		case HatType_Dweller: 
			return class'Hat_Ability_FoxMask';

		case HatType_TimeStop: 
			return class'Hat_Ability_TimeStop';
	}
	
	return None;
}

function int GetHatYarnCost(class<Hat_Ability> hatClass)
{
	switch (hatClass)
	{
		case class'Hat_Ability_Sprint':
			return SlotData.SprintYarnCost;
		
		case class'Hat_Ability_Chemical':
			return SlotData.BrewingYarnCost;

		case class'Hat_Ability_StatueFall':
			return SlotData.IceYarnCost;
		
		case class'Hat_Ability_FoxMask':
			return SlotData.DwellerYarnCost;

		case class'Hat_Ability_TimeStop':
			return SlotData.TimeStopYarnCost;
	}

	return 0;
}

function SendLocationCheck(int id, optional bool scout)
{
	local string jsonMessage;
	
	if (!IsFullyConnected() && !scout)
	{
		ItemResender.AddLocation(id);
		
		class'Engine'.static.BasicSaveObject(ItemResender, 
		"APRandomizer/item_resender"$`SaveManager.GetCurrentSaveData().CreationTimeStamp, false, 1, true);
		
		return;
	}
	
	if (!scout)
	{
		jsonMessage = "[{\"cmd\":\"LocationChecks\",\"locations\":[" $id $"]}]";
	}
	else
	{
		jsonMessage = "[{\"cmd\":\"LocationScouts\",\"locations\":[" $id $"]}]";
	}
	
	Client.SendBinaryMessage(jsonMessage);
}

function SendMultipleLocationChecks(array<int> locationArray, optional bool scout, optional bool hint)
{
	local string jsonMessage;
	local int i;
	
	if (!IsFullyConnected() && !scout && !hint)
	{
		ItemResender.AddMultipleLocations(locationArray);
		
		class'Engine'.static.BasicSaveObject(ItemResender, 
		"APRandomizer/item_resender"$`SaveManager.GetCurrentSaveData().CreationTimeStamp, false, 1, true);
		
		return;
	}

	if (!scout)
	{
		jsonMessage = "[{\"cmd\":\"LocationChecks\",\"locations\":[";
	}
	else
	{
		jsonMessage = "[{\"cmd\":\"LocationScouts\",\"locations\":[";
	}
	
	for (i = 0; i < locationArray.Length; i++)
	{
		jsonMessage $= locationArray[i];
		if (i+1 < locationArray.Length)
		{
			jsonMessage $= ",";
		}
	}
	
	if (scout && hint)
	{
		jsonMessage $= "],\"create_as_hint\":1";
	}
	else
	{
		jsonMessage $= "]";
	}
	
	jsonMessage $= "}]";
	client.SendBinaryMessage(jsonMessage);
}

function BabyTrapTimer()
{
	local Hat_Player player;
	local class<Hat_CarryObject_Stackable> stackClass;
	local Hat_CarryObject_Stackable stack;
	
	foreach DynamicActors(class'Hat_Player', player)
	{
		if (player.IsA('Hat_Player_MustacheGirl'))
			continue;
	
		if (RandRange(1, 150) == 1)
		{
			stackClass = class'Archipelago_Stackable_Conductor';
		}
		else
		{
			stackClass = class'Archipelago_Stackable_ConductorBaby';
		}
		
		stack = Spawn(stackClass, , , player.Location);
		stack.StartDelivery();
		if (!player.BeginCarry(stack, true))
		{
			stack.Destroy();
			return; // There is no escape from your fate as a babysitter!
		}
	}
	
	BabyCount--;
	if (BabyCount <= 0)
		ClearTimer(NameOf(BabyTrapTimer));
}

function LaserTrapTimer()
{
	local Hat_Player player;

	foreach DynamicActors(class'Hat_Player', player)
	{
		if (player.IsA('Hat_Player_MustacheGirl'))
			continue;
	
		Spawn(class'Archipelago_Hazard_SnatcherLaser', , , player.Location);
	}
	
	LaserCount--;
	if (LaserCount <= 0)
		ClearTimer(NameOf(LaserTrapTimer));
}

function DoParadeTrap()
{
	local Hat_Enemy_ScienceBand_Base member, lastMember[2];
	local int i, playerIndex;
	local Hat_Player p, player, player2;
	local Vector loc;
	local float time, mult;
	local bool timerActive;
	
	foreach DynamicActors(class'Hat_Player', p)
	{
		if (p.IsA('Hat_Player_MustacheGirl'))
			continue;
			
		if (p.IsA('Hat_Player_CoPartner'))
			player2 = p;
		else
			player = p;
	}
	
	lastMember[0] = None;
	lastMember[1] = None;
	timerActive = IsTimerActive(NameOf(ActivateParade));
	
	for (i = 0; i < ParadeTrapMembers; i++)
	{
		for (playerIndex = 0; playerIndex < 2; playerIndex++)
		{
			if (playerIndex == 0 || player2 == None)
				loc = player.Location;
			else if (playerIndex == 1)
				loc = player2.Location;
				
			mult = timerActive ? ParadeArray.Length/2 : i;
				
			loc += vect(1,1,0) * (mult * 50);
			member = Spawn(class'Hat_Enemy_ScienceBand_DeadBirdBoss', , , loc, , , true);
			member.DropDownLandStingerSoundPitch = 1.0 + (ParadeArray.Length/2) * 0.2;
			member.DoDropDown(0.3*mult);
			member.FrontBandMember = lastMember[playerIndex];
			member.MimicDelay = ParadeTrapDelay + (ParadeArray.Length/2) * ParadeTrapSpread;
			member.MimicPlayerIndex = playerIndex;
			
			ParadeArray.AddItem(member);
			lastMember[playerIndex] = member;
			time += 0.3;
		}
	}
	
	if (timerActive)
		ClearTimer(NameOf(ActivateParade));
		
	SetTimer(1.0+time, false, NameOf(ActivateParade));
}

function ActivateParade()
{
	local int i;
	for (i = 0; i < ParadeArray.Length; i++)
	{
		if (ParadeArray[i].Active)
			continue;
	
		ParadeArray[i].Active = true;
		ParadeArray[i].AutoSetMimickActor();
	}
}

function ForceStandVisibility()
{
	local Actor a;
	
	foreach DynamicActors(class'Actor', a)
	{
		if (a.bHidden && a.IsA('Hat_DecorationStand'))
		{
			a.SetHidden(false);
		}
	}
}

function PlayHatStitchAnimation(Hat_PlayerController pc, Hat_BackpackItem item)
{
	local Hat_HUDElement element;
	element = Hat_HUD(pc.MyHUD).OpenHUD(class'Hat_HUDElementStitchNewHat');
	Hat_HUDElementStitchNewHat(element).SetItemInfo(pc.MyHUD, item);
}

function string GetHatName(class<Hat_Ability> abilityClass)
{
	switch (abilityClass)
	{
		case class'Hat_Ability_Sprint':
			return "Sprint Hat";
			
		case class'Hat_Ability_Chemical':
			return "Brewing Hat";
			
		case class'Hat_Ability_StatueFall':
			return "Ice Hat";
			
		case class'Hat_Ability_FoxMask':
			return "Dweller Mask";
			
		case class'Hat_Ability_TimeStop':
			return "Time Stop Hat";
			
		default:
			return "None";
	}
}

// For recording location IDs
function PrintItemsNearPlayer()
{
	local Hat_Player player;
	local Hat_Collectible_Important collectible;
	local Hat_Collectible page;
	
	player = Hat_Player(GetALocalPlayerController().Pawn);
	foreach DynamicActors(class'Hat_Collectible_Important', collectible)
	{
		if (!collectible.Enabled || collectible.IsA('Archipelago_RandomizedItem_Base') || collectible.IsA('Hat_Collectible_VaultCode_Base'))
			continue;
	
		if (GetVectorDistance(player.Location, collectible.Location) <= 1000.0)
		{
			ScreenMessage("[PrintItemsNearPlayer] Found collectible: " $collectible.Name $"("$ObjectToLocationId(collectible)$")");
		}
	}
	
	foreach DynamicActors(class'Hat_Collectible', page)
	{
		if (!page.IsA('Hat_Collectible_StoryBookPage'))
			continue;
		
		if (GetVectorDistance(player.Location, page.Location) <= 1000.0)
		{
			ScreenMessage("[PrintItemsNearPlayer] Found collectible: " $page.Name $"("$ObjectToLocationId(page)$")");
		}
	}
}

function BeatGame()
{
	SetAPBits("HasBeatenGame", 1);
	if (!IsFullyConnected())
		return;
	
	client.SendBinaryMessage("[{\"cmd\":\"StatusUpdate\", \"status\":30}]");
}

function bool IsArchipelagoEnabled()
{
	if (`GameManager.GetCurrentMapFilename() ~= `GameManager.TitleScreenMapName)
		return false;
	
	return HasAPBit("ArchipelagoEnabled", 1);
}

function bool IsFullyConnected()
{
	return (client != None && client.FullyConnected);
}

function bool IsDeathLinkEnabled()
{
	return SlotData.DeathLink;
}

function bool IsInSpaceship()
{
	return `GameManager.GetCurrentMapFilename() ~= `GameManager.HubMapName;
}

// Since this is a randomizer, we may already have this act's Time Piece without actually completing it.
// So we check if the act is really completed by checking for this level bit set in OnTimePieceCollected()
// using the act's Time Piece.
function bool IsActReallyCompleted(Hat_ChapterActInfo act)
{
	if (act.hourglass == "")
		return true;
	
	return HasAPBit("ActComplete_"$act.hourglass, 1);
}

function bool IsActFreeRoam(Hat_ChapterActInfo act)
{
	return (act.ChapterInfo != None && (act.ChapterInfo.IsActless || act.ChapterInfo.HasFreeRoam)
	&& (act.ActID == 99 || (act.ChapterInfo.ActIDAfterIntro > 0 && act.ActID == act.ChapterInfo.ActIDAfterIntro)) && !act.IsBonus);
}

function Hat_ChapterActInfo GetShuffledAct(Hat_ChapterActInfo act, optional out int basement)
{
	local int i;
	for (i = 0; i < SlotData.ShuffledActList.Length; i++)
	{
		if (SlotData.ShuffledActList[i].OriginalAct != None && SlotData.ShuffledActList[i].OriginalAct == act)
		{
			basement = int(SlotData.ShuffledActList[i].IsDeadBirdBasementShuffledAct);
			return SlotData.ShuffledActList[i].NewAct;
		}
	}
	
	return None;
}

function Hat_ChapterActInfo GetDeadBirdBasementShuffledAct(optional out int vanilla)
{
	local int i;
	for (i = 0; i < SlotData.ShuffledActList.Length; i++)
	{
		if (SlotData.ShuffledActList[i].IsDeadBirdBasementOriginalAct)
		{
			if (SlotData.ShuffledActList[i].IsDeadBirdBasementShuffledAct)
			{
				vanilla = 1;
			}

			return SlotData.ShuffledActList[i].NewAct;
		}
	}
	
	return None;
}

function Hat_ChapterActInfo GetRiftActFromMapName(string MapName)
{
	local array<Hat_ChapterInfo> chapterInfoArray;
	local Hat_ChapterInfo chapter;
	local Hat_ChapterActInfo act;
	
	chapterInfoArray = class'Hat_ChapterInfo'.static.GetAllChapterInfo();
	foreach chapterInfoArray(chapter)
	{
		chapter.ConditionalUpdateActList();
		foreach chapter.ChapterActInfo(act)
		{
			if (act.MapName ~= MapName)
				return act;
		}
	}
	
	return None;
}

function ScreenMessage(String message)
{
	if (Broadcaster == None)
	{
		Broadcaster = Spawn(class'Archipelago_BroadcastHandler');
	}
	
    Broadcaster.Broadcast(GetALocalPlayerController(), message);
}

function DebugMessage(String message)
{
	if (!DebugMode)
		return;
	
	if (Broadcaster == None)
	{
		Broadcaster = Spawn(class'Archipelago_BroadcastHandler');
	}
	
    Broadcaster.Broadcast(GetALocalPlayerController(), message);
	`Broadcast(message);
}

function int ObjectToLocationId(Object obj)
{
	local int i;
	local int id;
	local string fullName;
	
	fullName = class'Hat_SaveBitHelper'.static.GetCorrectedMapFilename(string(Actor(obj).GetLevelName()))$"."$obj.Name;
	
	// Convert the object's name to an ID, using the Unicode values of the characters
	for (i = 0; i < Len(fullName); i++)
	{
		id += Asc(Mid(fullName, i, 1));
	}
	
	if (obj.IsA('Hat_Collectible_StoryBookPage'))
	{
		id += StoryBookPageIDRange;
	}
	else
	{
		id += GetChapterIDRange(`GameManager.GetChapterInfo());
	}
	
	return id;
}

// DO NOT use the 310000 range, that is for act completion location IDs
function int GetChapterIDRange(Hat_ChapterInfo chapter)
{
	switch (chapter)
	{
		case Hat_ChapterInfo'HatinTime_ChapterInfo.maingame.subconforest':
			return Chapter3IDRange;
			
		case Hat_ChapterInfo'HatinTime_ChapterInfo.maingame.Sand_and_Sails':
			return Chapter4IDRange;
			
		default:
			return BaseIDRange;
	}
}

function string PlayerIdToName(int id)
{
	return PlayerNames[id];
}

// Equivalent to Repl(), but only replaces the given string once
function bool ReplOnce(string str, string match, string with, out string result, optional bool caseSensitive)
{
	local int index;
	local string l;
	local string r;
	local bool found;
	
	result = str;
	index = InStr(str, match, false, !caseSensitive);
	
	if (index != -1)
	{
		found = true;
	
		// Slice out the left and right parts of the string
		l = Left(str, index+Len(match));
		r = Split(str, l, true);
		l = Repl(l, match, "", caseSensitive);
		result = l$with$r;
	}
	
	return found;
}

function float GetVectorDistance(Vector start, Vector end)
{
	local float distance;
	distance = Abs(start.x - end.x);
	distance += Abs(start.y - end.y);
	distance += Abs(start.z - end.z);
	
	return distance;
}

static function bool SetAPBits(string id, int i, optional Hat_SaveGame_Base save)
{
	return class'Hat_SaveBitHelper'.static.SetLevelBits(id, i, ArchipelagoPrefix, save);
}

static function bool HasAPBit(string id, int i, optional Hat_SaveGame_Base save)
{
	return class'Hat_SaveBitHelper'.static.HasLevelBit(id, i, ArchipelagoPrefix, save);
}

static function int GetAPBits(string id, optional int defaultValue=0, optional Hat_SaveGame_Base save)
{
	return class'Hat_SaveBitHelper'.static.GetLevelBits(id, ArchipelagoPrefix, save, defaultValue);
}

// Borrowed this handy function from Jawchewa, 
// you can access the mod actor via the `AP macro
// if you have `include(APRandomizer\Classes\Globals.uci); in your file.
static function Archipelago_GameMod GetGameMod()
{
    local Archipelago_GameMod mod;
    
    foreach class'WorldInfo'.static.GetWorldInfo().DynamicActors(class'Archipelago_GameMod', mod)
    {
		return mod;
    }
    
    return None;
}

defaultproperties
{
	bAlwaysTick = true;
	ParadeTrapMembers = 4;
	ParadeTrapDelay = 1;
	ParadeTrapSpread = 1;
	
	UnlockScreenNumbers[0] = Texture2D'APRandomizer_content.unlock_screen_numbers_00';
	UnlockScreenNumbers[1] = Texture2D'APRandomizer_content.unlock_screen_numbers_01';
	UnlockScreenNumbers[2] = Texture2D'APRandomizer_content.unlock_screen_numbers_02';
	UnlockScreenNumbers[3] = Texture2D'APRandomizer_content.unlock_screen_numbers_03';
	UnlockScreenNumbers[4] = Texture2D'APRandomizer_content.unlock_screen_numbers_04';
	UnlockScreenNumbers[5] = Texture2D'APRandomizer_content.unlock_screen_numbers_05';
	UnlockScreenNumbers[6] = Texture2D'APRandomizer_content.unlock_screen_numbers_06';
	UnlockScreenNumbers[7] = Texture2D'APRandomizer_content.unlock_screen_numbers_07';
	UnlockScreenNumbers[8] = Texture2D'APRandomizer_content.unlock_screen_numbers_08';
	UnlockScreenNumbers[9] = Texture2D'APRandomizer_content.unlock_screen_numbers_09';
	UnlockScreenNumbers[10] = Texture2D'APRandomizer_content.unlock_screen_numbers_10';
	UnlockScreenNumbers[11] = Texture2D'APRandomizer_content.unlock_screen_numbers_11';
	UnlockScreenNumbers[12] = Texture2D'APRandomizer_content.unlock_screen_numbers_12';
	UnlockScreenNumbers[13] = Texture2D'APRandomizer_content.unlock_screen_numbers_13';
	UnlockScreenNumbers[14] = Texture2D'APRandomizer_content.unlock_screen_numbers_14';
	UnlockScreenNumbers[15] = Texture2D'APRandomizer_content.unlock_screen_numbers_15';
	UnlockScreenNumbers[16] = Texture2D'APRandomizer_content.unlock_screen_numbers_16';
	UnlockScreenNumbers[17] = Texture2D'APRandomizer_content.unlock_screen_numbers_17';
	UnlockScreenNumbers[18] = Texture2D'APRandomizer_content.unlock_screen_numbers_18';
	UnlockScreenNumbers[19] = Texture2D'APRandomizer_content.unlock_screen_numbers_19';
	UnlockScreenNumbers[20] = Texture2D'APRandomizer_content.unlock_screen_numbers_20';
	UnlockScreenNumbers[21] = Texture2D'APRandomizer_content.unlock_screen_numbers_21';
	UnlockScreenNumbers[22] = Texture2D'APRandomizer_content.unlock_screen_numbers_22';
	UnlockScreenNumbers[23] = Texture2D'APRandomizer_content.unlock_screen_numbers_23';
	UnlockScreenNumbers[24] = Texture2D'APRandomizer_content.unlock_screen_numbers_24';
	UnlockScreenNumbers[25] = Texture2D'APRandomizer_content.unlock_screen_numbers_25';
	UnlockScreenNumbers[26] = Texture2D'APRandomizer_content.unlock_screen_numbers_26';
	UnlockScreenNumbers[27] = Texture2D'APRandomizer_content.unlock_screen_numbers_27';
	UnlockScreenNumbers[28] = Texture2D'APRandomizer_content.unlock_screen_numbers_28';
	UnlockScreenNumbers[29] = Texture2D'APRandomizer_content.unlock_screen_numbers_29';
	UnlockScreenNumbers[30] = Texture2D'APRandomizer_content.unlock_screen_numbers_30';
	UnlockScreenNumbers[31] = Texture2D'APRandomizer_content.unlock_screen_numbers_31';
	UnlockScreenNumbers[32] = Texture2D'APRandomizer_content.unlock_screen_numbers_32';
	UnlockScreenNumbers[33] = Texture2D'APRandomizer_content.unlock_screen_numbers_33';
	UnlockScreenNumbers[34] = Texture2D'APRandomizer_content.unlock_screen_numbers_34';
	UnlockScreenNumbers[35] = Texture2D'APRandomizer_content.unlock_screen_numbers_35';
	UnlockScreenNumbers[36] = Texture2D'APRandomizer_content.unlock_screen_numbers_36';
	UnlockScreenNumbers[37] = Texture2D'APRandomizer_content.unlock_screen_numbers_37';
	UnlockScreenNumbers[38] = Texture2D'APRandomizer_content.unlock_screen_numbers_38';
	UnlockScreenNumbers[39] = Texture2D'APRandomizer_content.unlock_screen_numbers_39';
	UnlockScreenNumbers[40] = Texture2D'APRandomizer_content.unlock_screen_numbers_40';
	UnlockScreenNumbers[41] = Texture2D'APRandomizer_content.unlock_screen_numbers_41';
	UnlockScreenNumbers[42] = Texture2D'APRandomizer_content.unlock_screen_numbers_42';
	UnlockScreenNumbers[43] = Texture2D'APRandomizer_content.unlock_screen_numbers_43';
	UnlockScreenNumbers[44] = Texture2D'APRandomizer_content.unlock_screen_numbers_44';
	UnlockScreenNumbers[45] = Texture2D'APRandomizer_content.unlock_screen_numbers_45';
	UnlockScreenNumbers[46] = Texture2D'APRandomizer_content.unlock_screen_numbers_46';
	UnlockScreenNumbers[47] = Texture2D'APRandomizer_content.unlock_screen_numbers_47';
	UnlockScreenNumbers[48] = Texture2D'APRandomizer_content.unlock_screen_numbers_48';
	UnlockScreenNumbers[49] = Texture2D'APRandomizer_content.unlock_screen_numbers_49';
	UnlockScreenNumbers[50] = Texture2D'APRandomizer_content.unlock_screen_numbers_50';
}