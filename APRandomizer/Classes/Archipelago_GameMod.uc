class Archipelago_GameMod extends GameMod
	dependson(Archipelago_ItemInfo)
	dependson(Archipelago_HUDElementBubble)
	dependson(Archipelago_GameData)
	config(Mods);

// IMPORTANT!! If you add or remove *ANYTHING* in the Archipelago_SlotData class, INCREMENT THIS NUMBER!
// Not doing so can and will break existing save files for seeds!!!
const SlotDataVersion = 2;

var Archipelago_TcpLink Client;
var Archipelago_SlotData SlotData;
var Archipelago_ItemResender ItemResender;
var array<class<Archipelago_ShopItem_Base > > ShopItemsPending;
var array<Archipelago_GameData> GameData;
var array<Hat_GhostPartyPlayerStateBase> Buddies; // Online Party co-op support
var transient int ActMapChangeChapter;
var transient bool ActMapChange;
var transient bool CollectiblesShuffled;
var transient bool ControllerCapsLock;
var transient bool ContractEventActive;
var transient bool ItemSoundCooldown;
var transient string DebugMsg;

var config int DebugMode;
var config int DisableInjection;
var config int VerboseLogging;
var config int DisableAutoConnect;
var config int WSSMode;
var config int FilterSelfJoins;
var const editconst Vector SpaceshipSpawnLocation;

var transient array<Hat_SnatcherContract_Selectable> SelectContracts;
var transient bool TrapsDestroyed;
var transient float TimeSinceLastItem;

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
	var int ID;
	var int ItemID;
	var int ItemFlags;
	var int PonCost;
	var int Player;
	var bool Hinted;
};

struct immutable LocationInfo
{
	var int ID;
	var int ItemID;
	var int Player;
	var int Flags;
	var bool IsStatic;
	var string MapName;
	
	var Vector Position;
	var class<Actor> ItemClass;
	var class<Actor> ContainerClass;
};

// Level bit prefix
const ArchipelagoPrefix = "AP_";

// Location ID ranges
const BaseIDRange = 300000;
const ActCompleteIDRange = 310000;
const Chapter3IDRange = 320000;
const Chapter4IDRange = 330000;
const StoryBookPageIDRange = 340000;
const TasksanityIDStart = 300204;

// Event checks
const RumbiYarnCheck = 301000;
const UmbrellaCheck = 301002;

// These have to be hardcoded because camera badge item disappears if you have the camera badge
const CameraBadgeCheck1 = 302003;
const CameraBadgeCheck2 = 302004;
const SubconBushCheck1 = 325478;
const SubconBushCheck2 = 325479;
var const editconst Vector Camera1Loc;
var const editconst Vector Camera2Loc;

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
var array<string> ThugCatShops;

event OnModLoaded()
{
	local string mapName;
	
	if (IsCurrentPatch())
		return;
	
	HookActorSpawn(class'Hat_Player', 'Player');
	
	if (IsArchipelagoEnabled())
	{
		mapName = class'Hat_SaveBitHelper'.static.GetCorrectedMapFilename();
		if (mapName ~= "subconforest")
		{
			HookActorSpawn(class'Actor', 'ContractEvent');
		}
	}
}

event OnModUnloaded()
{
	if (IsArchipelagoEnabled())
		SaveGame();
}

function OnPreRestartMap(out String MapName)
{
	if (IsArchipelagoEnabled())
		SaveGame();
}

function SaveGame()
{
	if (SlotData != None && SlotData.Initialized)
	{
		if (class'Engine'.static.BasicSaveObject(SlotData, 
		"APSlotData/slot_data"$`SaveManager.GetCurrentSaveData().CreationTimeStamp, false, SlotDataVersion, true))
		{
			DebugMessage("Saved slot data to file successfully!");
		}
	}
	
	if (ItemResender != None)
	{
		if (class'Engine'.static.BasicSaveObject(ItemResender, 
		"APSlotData/item_resender"$`SaveManager.GetCurrentSaveData().CreationTimeStamp, false, 1, true))
		{
			DebugMessage("Saved item resender to file successfully!");
		}
	}
	
	`SaveManager.SaveToFile(true);
}

event Tick(float d)
{
	local int i;
	local array<LocalPlayer> players;
	
	Super.Tick(d);
	if (!IsArchipelagoEnabled())
		return;
	
	IterateChestArray();
	
	if (ParadeArray.Length > 0)
	{
		players = class'Engine'.static.GetEngine().GamePlayers;
	
		for (i = 0; i < ParadeArray.Length; i++)
		{
			if (ParadeArray[i].MimicPlayerIndex >= players.Length)
				continue;
			
			if (ShouldFreezeParade(Hat_PlayerController(players[ParadeArray[i].MimicPlayerIndex].Actor.Pawn.Controller)))
			{
				ParadeArray[i].SetTickIsDisabled(true);
				ParadeArray[i].SetCollision(false);
			}
			else
			{
				ParadeArray[i].SetTickIsDisabled(false);
				ParadeArray[i].SetCollision(true);
			}
		}
	}
}

function bool ShouldFreezeParade(Hat_PlayerController c)
{
	if (c.IsTalking()) return true;
	if (c.PlayerCamera != None && Hat_PlayerCamera(c.PlayerCamera) != None && Hat_PlayerCamera(c.PlayerCamera).IgnorePlayerMovement()) return true;
	if (c.MyHUD != None && Hat_HUD(c.MyHUD) != None && Hat_HUD(c.MyHUD).CacheElementsDisableMovement)
	{
		if (Hat_HUD(c.MyHUD).GetHUD(class'Hat_HUDMenu_ItemWheel', true) == None)
			return true;
	}
	
	return false;
}

event OnHookedActorSpawn(Object newActor, Name identifier)
{
	local int i;
	local Hat_SaveGame save;
	local Hat_PlayerController ctr;
	
	if (identifier == 'Player')
	{
		if (newActor.IsA('Hat_Player_MustacheGirl'))
			return;
			
		// Need to do this on a timer to prevent the game from overriding our actions
		SetTimer(0.3, false, NameOf(EnableConsoleCommands));
	}
	
	if (IsArchipelagoEnabled())
	{
		if (identifier == 'ContractEvent' && SlotData.ShuffleActContracts)
		{
			if (newActor.IsA('Hat_SnatcherContractEvent'))
			{
				if (newActor.IsA('Hat_SnatcherContractEvent_Initial') || newActor.IsA('Hat_SnatcherContractEvent_GenericTrap')
					|| newActor.IsA('Hat_SnatcherContractEvent_IceBroken'))
				{
					DebugMessage("Hooking contract event: " $newActor.name);
					ContractEventActive = true;
					save = `SaveManager.GetCurrentSaveData();
					
					for (i = 0; i < SlotData.ObtainedContracts.Length; i++)
					{
						if (SlotData.CheckedContracts.Find(SlotData.ObtainedContracts[i]) != -1)
							continue;
						
						// temporarily remove any obtained contracts so player can still do contract checks
						SlotData.TakenContracts.AddItem(SlotData.ObtainedContracts[i]);
						save.SnatcherContracts.RemoveItem(SlotData.ObtainedContracts[i]);
						save.CompletedSnatcherContracts.RemoveItem(SlotData.ObtainedContracts[i]);
					}
					
					foreach DynamicActors(class'Hat_PlayerController', ctr)
					{
						// Dying while signing a contract may cause the check to not send and become permanently unavailable.
						// This can primarily happen with traps. So we need to enable god mode temporarily.
						ctr.bGodMode = true;
					}
					
					SetTimer(0.5, true, NameOf(WaitForContractEvent));
				}
			}
			else if (newActor.IsA('Hat_SnatcherContract_Selectable'))
			{
				SelectContracts.AddItem(Hat_SnatcherContract_Selectable(newActor));
				ClearTimer(NameOf(CheckContractsForDeletion));
				SetTimer(0.5, false, NameOf(CheckContractsForDeletion));
			}
		}
	}
}

// Override the player's input class so we can use our own console commands (without conflicting with Console Commands Plus!)
function EnableConsoleCommands()
{
	local PlayerController c;
	
	if (!IsArchipelagoEnabled())
		return;
	
	c = GetALocalPlayerController();
	c.Interactions.RemoveItem(c.PlayerInput);
	c.PlayerInput = None;
	c.InputClass = class'Archipelago_CommandHelper';
	c.InitInputSystem();
}

function CreateClient()
{
	if (client != None)
		return;
	
	client = Spawn(class'Archipelago_TcpLink');
}

event PreBeginPlay()
{
	local Hat_CollectibleBackpackItem relic;
	local Hat_SaveGame save;
	local string path;
	local int i, pos, a, j;
	
	Super.PreBeginPlay();
	
	if (IsInTitlescreen() || IsCurrentPatch())
		return;
	
	if (bool(DisableInjection) && !IsArchipelagoEnabled())
		return;
	
	save = `SaveManager.GetCurrentSaveData();
	if (!IsArchipelagoEnabled() && save.TotalPlayTime <= 0.0)
	{
		SetAPBits("ArchipelagoEnabled", 1);
	}
	
	if (!IsArchipelagoEnabled())
		return;
	
	SlotData = new class'Archipelago_SlotData';
	path = "APSlotData/slot_data"$`SaveManager.GetCurrentSaveData().CreationTimeStamp;
	
	if (class'Engine'.static.BasicLoadObject(SlotData, path, false, SlotDataVersion))
	{
		SlotData.Initialized = true;
		UpdateChapterInfo();
	}
	
	if (!IsInSpaceship())
	{
		if (`GameManager.GetCurrentMapFilename() ~= "subconforest")
		{
			// If player has all contracts (other than Subcon Well), remove one so that traps still spawn
			if (save.SnatcherContracts.Length >= 3 || save.CompletedSnatcherContracts.Length >= 3)
			{
				for (i = 0; i < 4; i++)
				{
					if (i < save.SnatcherContracts.Length || i < save.CompletedSnatcherContracts.Length)
					{
						if (i < save.SnatcherContracts.Length && save.SnatcherContracts[i] != class'Hat_SnatcherContract_IceWall'
						|| i < save.CompletedSnatcherContracts.Length && save.CompletedSnatcherContracts[i] != class'Hat_SnatcherContract_IceWall')
						{
							pos = save.SnatcherContracts.Find(save.SnatcherContracts[i]);
							if (pos != -1)
							{
								SlotData.TakenContracts.AddItem(save.SnatcherContracts[pos]);
								save.SnatcherContracts.RemoveItem(save.SnatcherContracts[pos]);
							}
							
							pos = save.CompletedSnatcherContracts.Find(save.SnatcherContracts[i]);
							if (pos != -1)
							{
								if (SlotData.TakenContracts.Find(save.SnatcherContracts[pos]) == -1)
									SlotData.TakenContracts.AddItem(save.SnatcherContracts[pos]);
							
								save.CompletedSnatcherContracts.RemoveItem(save.SnatcherContracts[pos]);
							}
							
							break;
						}
					}
				}
			}
			else if (save.SnatcherContracts.Length <= 1 && save.CompletedSnatcherContracts.Length <= 1
				&& save.TurnedInSnatcherContracts.Length <= 1)
			{
				// We need to give the player two dummy contracts so that all of the traps spawn,
				// this is due to the MinContractsToSpawn variable in Hat_SnatcherContractSummon
				// (using console commands to set to 0 doesn't work, because some have it set to 2 when the default is 1)
				save.GiveContract(class'Archipelago_SnatcherContract_Dummy1', GetALocalPlayerController());
				save.GiveContract(class'Archipelago_SnatcherContract_Dummy2', GetALocalPlayerController());
			}
		}
		
		if (`GameManager.GetChapterInfo().ChapterID == 4)
		{
			if (!class'Hat_SaveBitHelper'.static.HasActBit("ForceAlpineFinale", 1))
			{
				if (HasAPBit("AlpineFinale", 1))
					EnableAlpineFinale();
				else
					DisableAlpineFinale();
			}
		}
	}
	
	// Hat_DecorationStand is not alwaysloaded, and the alwaysloaded workaround doesn't seem to work with it (crash on boot).
	// So what we do here is, when a relic stand is completed, tell our save file that it actually HASN'T been
	// completed on map load so that it doesn't place the decorations on the stand and we can place more.
	// We do this because the player can place relics in an order the logic doesn't expect them to, potentially locking them out of a seed.
	for (i = 0; i < save.HUBDecorations.Length; i++)
	{
		if (save.HUBDecorations[i].Complete)
		{
			for (a = 0; a < save.HUBDecorations[i].Decorations.Length; a++)
			{
				relic = class'Hat_Loadout'.static.MakeCollectibleBackpackItem(save.HUBDecorations[i].Decorations[a]);
				
				for (j = 0; j < save.MyBackpack2017.Collectibles.Length; j++)
				{
					if (save.MyBackpack2017.Collectibles[j].BackpackClass == relic.BackpackClass)
						save.MyBackpack2017.Collectibles[j] = None;
				}
			}
			
			save.HUBDecorations.RemoveItem(save.HUBDecorations[i]);
			i--;
		}
	}
	
	SetAPBits("AlpineFinale", 0);
	ConsoleCommand("set Hat_IntruderInfo_CookingCat HasIntruderAlert false");
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
	
	ItemResender = new class'Archipelago_ItemResender';
}

function OnPostInitGame()
{
	local int i, saveCount;
	local string mapName, realMapName;
	local Hat_BackpackItem item;
	local Hat_TreasureChest_Base chest;
	local Hat_TimeRiftPortal portal;
	local TriggerVolume trigger;
	local Hat_SaveGame save;
	local Hat_Player ply;
	local Hat_PlayerController ctr;
	local Hat_NPC npc;
	local Hat_SubconPainting painting;
	local array<SequenceObject> seqObjects;
	local Hat_MetroTicketBooth_Base booth;
	local ShopInventoryItem dummy;
	local array<Object> shopInvs;
	local Hat_BonfireBarrier barrier;
	local Hat_SandStationHorn_Base horn;
	local array<class<Object > > DeathWishes;
	local class<Hat_SnatcherContract_DeathWish> dw;
	local class<Hat_CosmeticItemQualityInfo> flair;
	
	if (IsCurrentPatch())
		return;
	
	// If on titlescreen, find any Archipelago-enabled save files and do this stuff 
	// to prevent the game from forcing the player into Mafia Town.
	if (IsInTitlescreen())
	{
		saveCount = `SaveManager.NumUsedSaveSlots();
		
		for (i = 0; i < saveCount; i++)
		{
			save = Hat_SaveGame(`SaveManager.GetSaveSlot(i));
			if (save == None)
				continue;
			
			if (HasAPBit("ArchipelagoEnabled", 1, save))
				save.AllowSaving = false;
		}
		
		ResetEverything();
	}
	
	if (!IsArchipelagoEnabled())
		return;
	
	if (bool(DebugMode))
		SetTimer(1.0, true, NameOf(PrintItemsNearPlayer));
	
	HideItems();
	
	// Bon Voyage hotfix
	SetTimer(0.5, false, NameOf(HideItems));

	if (IsInSpaceship())
	{
		// Stop Mustache Girl tutorial cutscene (it breaks when removing the yarn)
		// The player can still get the yarn by smacking Rumbi after getting 4 time pieces.
		foreach DynamicActors(class'Hat_NPC', npc)
		{
			if (npc.IsA('Hat_NPC_MustacheGirl') && npc.Name == 'Hat_NPC_MustacheGirl_0')
			{
				// Set this level bit to 0 so that Rumbi will drop the yarn
				class'Hat_SaveBitHelper'.static.SetLevelBits("mu_preawakening_intruder_tutorial", 0);
				npc.ShutDown();
			}
			else if (npc.IsA('Hat_NPC_CookingCat'))
			{
				npc.ShutDown();
			}
			else if (SlotData.DeathWishOnly && npc.IsA('Hat_NPC_MafiaBossJar'))
			{
				npc.ShutDown();
			}
		}
		
		SetTimer(0.01, false, NameOf(SpawnDecorationStands));
		
		// When returning to hub from levels in act rando, the player may get softlocked behind chapter doors, prevent this
		if (SlotData.ActRando)
		{
			foreach DynamicActors(class'Hat_Player', ply)
			{
				if (ply.IsA('Hat_Player_MustacheGirl'))
					continue;
				
				ply.SetLocation(SpaceshipSpawnLocation);
			}
		}
		
		if ((SlotData.DLC1 || SlotData.DeathWishOnly) && IsDLC1Installed())
		{
			// In vanilla, Tour requires ALL but 1 time pieces, which changes depending on the DLC the player has.
			// This may change in the future, but for now, it's always available (once the player unlocks Chapter 5).
			foreach DynamicActors(class'Hat_TimeRiftPortal', portal)
			{
				if (portal.Name == 'Hat_TimeRiftPortal_2')
				{
					if (SlotData.ExcludeTour && !SlotData.DeathWishOnly)
					{
						portal.Enabled = false;
						portal.SetIdleSound(false);
						portal.SetHidden(true);
					}
					else
					{
						portal.Enabled = true;
						portal.SetIdleSound(true);
						portal.SetHidden(false);
					}
					
					break;
				}
			}
		}
		
		OpenBedroomDoor();
		`SetMusicParameterInt('FirstChapterUnlockSilence', 0);
	}
	else
	{
		// We need to do this early, before connecting, otherwise the game
		// might empty the chest on us if it has an important item in vanilla.
		// Example of this happening is the Hookshot Badge chest in the Subcon Well.
		// This will also prevent the player from possibly nabbing vanilla chest contents as well.
		foreach DynamicActors(class'Hat_TreasureChest_Base', chest)
		{
			if (chest.Opened || class<Hat_Collectible_Important>(chest.Content) == None
				&& class<Hat_Collectible_StoryBookPage>(chest.Content) == None)
				continue;
			
			if (chest.IsA('Hat_TreasureChest_GiftBox'))
				continue;
			
			if (SlotData.DeathWishOnly || class'Hat_SnatcherContract_DeathWish'.static.IsAnyActive(false))
			{
				if (class<Hat_Collectible_Important>(chest.Content) != None)
					chest.Empty();
				
				continue;
			}
			
			if (IsLocationChecked(ObjectToLocationId(chest)))
			{
				chest.Empty();
				continue;
			}
			
			ChestArray.AddItem(chest);
			
			if (class<Hat_Collectible_StoryBookPage>(chest.Content) == None
			&& class<Hat_Collectible_TreasureBit>(chest.Content) == None)
			{
				chest.Content = class'Hat_Collectible_EnergyBit';
			}
		}
		
		if (SlotData.BadgeSellerItemCount <= 0 || SlotData.DeathWishOnly)
		{
			foreach DynamicActors(class'Hat_NPC', npc)
			{
				if (npc.IsA('Hat_NPC_BadgeSalesman'))
					npc.ShutDown();
			}
		}
		
		mapName = class'Hat_SaveBitHelper'.static.GetCorrectedMapFilename();
		realMapName = `GameManager.GetCurrentMapFilename();
		
		// Fix for Rock the Boat
		if (realMapName ~= "ship_sinking")
			mapName = "ship_sinking";
		
		if (IsMapScouted(mapName))
			SetTimer(0.4, false, NameOf(ShuffleCollectibles2));
		
		if (InStr(realMapName, "mafia_town") != -1)
		{
			DeleteCameraParticle();
		}
		else if (realMapName ~= "alpsandsails" && SlotData.ShuffleZiplines && !class'Hat_SnatcherContract_DeathWish_Speedrun_Illness'.static.IsActive())
		{
			SetTimer(0.8, true, NameOf(UpdateZiplineUnlocks));
		}
		else if (realMapName ~= "dlc_metro")
		{
			CleanUpMetro();
			
			// so the shopkeeper doesn't say "we're sold out" when the player has the ticket
			foreach DynamicActors(class'Hat_MetroTicketBooth_Base', booth)
			{
				booth.WasBought = false;
				booth.UnlockView = None;
			}
			
			shopInvs = class'Hat_ClassHelper'.static.GetAllObjectsExpensive("Hat_ShopInventory");
			dummy.CollectibleClass = class'Archipelago_ShopItem_Dummy';
			dummy.ItemCost = 99999999;
			
			for (i = 0; i < shopInvs.Length; i++)
			{
				if (Archipelago_ShopInventory_Base(shopInvs[i]) != None
				|| Hat_ShopInventory_MetroFood(shopInvs[i]) != None)
					continue;
			
				Hat_ShopInventory(shopInvs[i]).ItemsForSale.AddItem(dummy);
			}
			
			foreach DynamicActors(class'Hat_NPC', npc)
			{
				if (npc.IsA('Hat_NPC_NyakuzaShop'))
					ConsoleCommand("set " $npc.Name $" SoldOut false");
			}
		}
		else if (realMapName ~= "subconforest")
		{
			// If act rando or contracts are shuffled, remove these act transitions for the well/manor if we don't enter from the proper act.
			// This forces the player to find the act/contracts in order to enter them
			if (SlotData.ActRando || SlotData.ShuffleActContracts)
			{
				DebugMessage("Disabling trigger volumes...");
				
				foreach AllActors(class'TriggerVolume', trigger)
				{
					if (trigger.Name == 'TriggerVolume_26' && `GameManager.GetCurrentAct() != 2
					|| trigger.Name == 'TriggerVolume_20' && `GameManager.GetCurrentAct() != 4)
					{
						DebugMessage("Disabling trigger volume: "$trigger.Name);
						trigger.ShutDown();
					}
					
					// If contracts are shuffled, disable the bag trap trigger if we already checked the Subcon Well contract
					if (SlotData.ShuffleActContracts && trigger.Name == 'TriggerVolume_4')
					{
						if (SlotData.CheckedContracts.Find(class'Hat_SnatcherContract_IceWall') != -1)
						{
							DebugMessage("Disabling trigger volume: "$trigger.Name);
							trigger.ShutDown();
						}
					}
				}
			}
			
			if (SlotData.ShuffleSubconPaintings)
			{
				foreach DynamicActors(class'Hat_SubconPainting', painting)
				{
					if (SlotData.UnlockedPaintings.Find(painting.Name) == -1)
					{
						painting.SetHidden(true);
						painting.SetCollision(false, false);
					}
				}
			}
			
			// Kismet edits here
			WorldInfo.GetGameSequence().FindSeqObjectsByClass(class'Hat_SeqAct_ClearContractObjective', true, seqObjects);
			for (i = 0; i < seqObjects.Length; i++)
			{
				Hat_SeqAct_ClearContractObjective(seqObjects[i]).ContractClass = None;
			}
		}
	}
	
	if (SlotData.DeathWish)
	{
		ConsoleCommand("set hat_snatchercontract_deathwish_riftcollapse PenaltyWaitTimeInSeconds 0");
		ConsoleCommand("set hat_snatchercontract_deathwish_riftcollapse Condition_3Lives false");
		ConsoleCommand("set hat_snatchercontract_deathwish neverobscureobjectives true");
		
		if (`SaveManager.GetNumberOfTimePieces() >= SlotData.DeathWishTPRequirement)
		{
			if (!class'Hat_SaveBitHelper'.static.HasLevelBit("DeathWish_intro", 1, `GameManager.HubMapName))
			{
				ScreenMessage("***DEATH WISH has been unlocked! Check your pause menu in the Spaceship!***", 'Warning');
				ScreenMessage("***DEATH WISH has been unlocked! Check your pause menu in the Spaceship!***", 'Warning');
				ScreenMessage("***DEATH WISH has been unlocked! Check your pause menu in the Spaceship!***", 'Warning');
			}
			
			class'Hat_SaveBitHelper'.static.SetLevelBits("DeathWish_intro", 1, `GameManager.HubMapName);
		}
		
		if (class'Hat_SnatcherContract_DeathWish'.static.IsAnyActive(true))
		{
			SetTimer(0.5, true, NameOf(CheckDeathWishObjectives));
		
			if (class'Hat_SnatcherContract_DeathWish_Speedrun_SubWell'.static.IsActive())
			{
				foreach DynamicActors(class'Hat_BonfireBarrier', barrier)
				{
					barrier.SetHidden(true);
					barrier.SetCollision(false, false);
				}
			}
			
			if (class'Hat_SnatcherContract_DeathWish_Speedrun_Illness'.static.IsActive()
			|| class'Hat_SnatcherContract_DeathWish_NiceBirdhouse'.static.IsActive())
			{
				foreach DynamicActors(class'Hat_SandStationHorn_Base', horn)
				{
					if (horn.IsActivated)
						continue;
						
					horn.IsActivated = true;
					horn.PostTargetUnlocks();
				}
			}
		}
		
		DeathWishes = class'Hat_ClassHelper'.static.GetAllScriptClasses("Hat_SnatcherContract_DeathWish");
		for (i = 0; i < DeathWishes.Length; i++)
		{
			dw = class<Hat_SnatcherContract_DeathWish>(DeathWishes[i]);
			if (dw.default.CompletionReward == None)
				continue;
				
			flair = class<Hat_CosmeticItemQualityInfo>(dw.default.CompletionReward);
			if (flair == None)
				continue;
			
			// Remove Death Wish flair rewards if we don't have the base hat, since the game doesn't bother checking if you have it.
			if (!class'Hat_Loadout'.static.BackpackHasInventory(flair.static.GetBaseCosmeticItemWeApplyTo()))
			{
				ConsoleCommand("set "$dw $" CompletionReward None");
			}
		}
	}
	
	if (SlotData.UmbrellaLogic)
	{
		ReplaceUnarmedWeapon();
	}
	
	ctr = Hat_PlayerController(GetALocalPlayerController());
	save = `SaveManager.GetCurrentSaveData();
	
	// If we load a new save file with at least 1 time piece, the game will force the umbrella into our inventory.
	for (i = 0; i < save.MyBackpack2017.Weapons.Length; i++)
	{
		item = save.MyBackpack2017.Weapons[i];
		if (item != None)
		{
			if (class<Hat_Weapon_Umbrella>(item.BackpackClass) != None 
			&& class<Archipelago_Weapon_Umbrella>(item.BackpackClass) == None)
			{
				ctr.MyLoadout.RemoveBackpack(item);
			}
		}
	}
	
	if (SlotData.Initialized)
		UpdateChapterInfo();
	
	for (i = 0; i < SlotData.ObtainedContracts.Length; i++)
	{
		// these occasionally get wiped for some reason
		SlotData.ObtainedContracts[i].static.UnlockActs(save);
	}
	
	// Remove our dummy contracts from earlier.
	if (save.SnatcherContracts.Find(class'Archipelago_SnatcherContract_Dummy1') != -1)
	{
		save.SnatcherContracts.RemoveItem(class'Archipelago_SnatcherContract_Dummy1');
	}
	
	if (save.SnatcherContracts.Find(class'Archipelago_SnatcherContract_Dummy2') != -1)
	{
		save.SnatcherContracts.RemoveItem(class'Archipelago_SnatcherContract_Dummy2');
	}
	
	if (SlotData != None && SlotData.Initialized)
	{
		// Restore any taken contracts if they're still in the list for some reason
		if (SlotData.TakenContracts.Length > 0)
			OnContractEventEnd();
		
		// Check for new contracts
		if (SlotData.ShuffleActContracts)
			SetTimer(1.0, true, NameOf(CheckForNewContracts));
	}
	
	if (Client == None)
		CreateClient();
}

function OnPostLevelIntro()
{
	if (!IsArchipelagoEnabled())
		return;

	if (`GameManager.GetCurrentMapFilename() ~= "dlc_metro")
		SetTimer(0.1, false, NameOf(CleanUpMetro));
}

function HideItems()
{
	local Hat_Collectible_Important a;
	local bool deathWish;
	
	deathWish = class'Hat_SnatcherContract_DeathWish'.static.IsAnyActive(false);
	foreach DynamicActors(class'Hat_Collectible_Important', a)
	{
		if (a.IsA('Hat_Collectible_VaultCode_Base') || a.IsA('Hat_Collectible_Sticker')
			|| a.IsA('Hat_Collectible_MetroTicket_Base'))
			continue;
		
		if (a.IsA('Hat_Collectible_InstantCamera'))
		{
			a.Destroy();
			continue;
		}
		
		// Hide all regular collectibles, just in case
		DebugMessage("Removing " $a.Name);
		
		if (deathWish) // no items in Death Wish.
			a.Destroy();
		else
			a.ShutDown();
	}
}

function bool DoesPlayerReallyHaveContract(class<Hat_SnatcherContract_Act> contract)
{
	return SlotData.ObtainedContracts.Find(contract) != -1;
}

function CheckForNewContracts()
{
	local int i, j, id;
	local Hat_SaveGame save;
	local Actor a;
	save = `SaveManager.GetCurrentSaveData();
	
	for (i = 0; i < save.SnatcherContracts.Length; i++)
	{
		if (save.SnatcherContracts[i] == None 
		|| !ContractEventActive && DoesPlayerReallyHaveContract(save.SnatcherContracts[i])
		|| SlotData.CheckedContracts.Find(save.SnatcherContracts[i]) != -1)
			continue;
		
		// We don't have this contract. Remove it and send the check for it.
		for (j = 0; j < save.SnatcherContracts[i].default.UnlockActIDs.Length; j++)
		{
			class'Hat_SaveBitHelper'.static.RemoveLevelBit("contract_unlock_actid", save.SnatcherContracts[i].default.UnlockActIDs[j], "subconforest");
		}
		
		id = class'Archipelago_ItemInfo'.static.GetContractID(save.SnatcherContracts[i]);
		DebugMessage("Sending contract as location: " $save.SnatcherContracts[i] $" ID: " $id);
		SendLocationCheck(id);
		
		SlotData.CheckedContracts.AddItem(save.SnatcherContracts[i]);
		save.SnatcherContracts.RemoveItem(save.SnatcherContracts[i]);
	}
	
	if (!TrapsDestroyed)
	{
		if (SlotData.CheckedContracts.Find(class'Hat_SnatcherContract_Toilet') != -1
		&& SlotData.CheckedContracts.Find(class'Hat_SnatcherContract_Vanessa') != -1
		&& SlotData.CheckedContracts.Find(class'Hat_SnatcherContract_MailDelivery') != -1)
		{
			foreach DynamicActors(class'Actor', a)
			{
				if (a.IsA('Hat_SnatcherContractSummon'))
					a.Destroy();
			}
			
			TrapsDestroyed = true;
		}
	}
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
	bubble.OpenInputText(hud, "Please enter your slot name. If you are using a controller, hold the X button for capital letters.", 
	class'Hat_ConversationType_Regular', 'a', 25);
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
	bubble.OpenInputText(hud, "Please enter password (if there is none, just left-click or press Y if on controller).", class'Hat_ConversationType_Regular', 'a', 25);
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
	bubble.OpenInputText(hud, "Please enter IP:Port. If you are using a controller, - may be used in place of :", class'Hat_ConversationType_Regular', 'a', 25);
}

function KeepConnectionAlive()
{
	local JsonObject json;
	if (!IsFullyConnected())
		return;
	
	json = new class'JsonObject';
	json.SetStringValue("cmd", "Bounce");
	json.SetIntValue("slot", SlotData.PlayerSlot);
	client.SendBinaryMessage(EncodeJson2(json));
	json = None;
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
	local int i;

	SetTimer(0.5, false, NameOf(ShuffleCollectibles));
	UpdateChapterInfo();
	
	// Have we beaten our seed? Send again in case we somehow weren't connected before.
	if (HasAPBit("HasBeatenGame", 1))
	{
		BeatGame();
	}
	
	// resend any locations we checked while not connected
	if (class'Engine'.static.BasicLoadObject(ItemResender, 
	"APSlotData/item_resender"$`SaveManager.GetCurrentSaveData().CreationTimeStamp, false, 1))
	{
		SetTimer(0.5, false, NameOf(ResendLocations));
	}
	
	for (i = 0; i < ShopItemsPending.Length; i++)
	{
		InitShopItemDisplayName(ShopItemsPending[i]);
	}
	
	ShopItemsPending.Length = 0;
	
	// Call this just to see if we can craft a hat
	OnYarnCollected(0);
	
	if (IsOnlineParty())
	{
		SendOnlinePartyCommand(string(SlotData.Seed)$"+"$SlotData.PlayerSlot, 'APSeedCheck', GetALocalPlayerController().Pawn);
	}
}

event OnOnlinePartyCommand(string Command, Name CommandChannel, Hat_GhostPartyPlayerStateBase Sender)
{
	local Actor a;
	local int seed, slot, i, locId;
	local bool isLive;
	local JsonObject locSync, actSync;
	local array<Hat_ChapterInfo> chapterInfoArray;
	local String hourglass, map;
	local array<string> hourglasses;
	local Hat_ChapterInfo chapter;
	local Hat_ChapterActInfo act;
	
	if (CommandChannel == 'APSeedCheck')
	{
		slot = int(Split(Command, "+", true));
		seed = int(Repl(Command, "+"$slot, ""));
		
		if (SlotData.Seed == seed && SlotData.PlayerSlot == slot || Command == "MatchingSeed")
		{
			// If we have a matching seed and slot number, add this guy to our list of valid buddies.
			if (Buddies.Find(Sender) == -1)
			{
				DebugMessage("Adding Online Party buddy: " $Sender.GetDisplayName());
				Buddies.AddItem(Sender);
			}
			
			if (Command == "MatchingSeed")
			{
				// Sync all locations/acts
				PartySyncLocations(SlotData.CheckedLocations, Sender);
				
				actSync = new class'JsonObject';
				chapterInfoArray = class'Hat_ChapterInfo'.static.GetAllChapterInfo();
				foreach chapterInfoArray(chapter)
				{
					chapter.ConditionalUpdateActList();
					foreach chapter.ChapterActInfo(act)
					{
						if (act.hourglass == "" || !IsActReallyCompleted(act))
							continue;
						
						hourglasses.AddItem(act.hourglass);
					}
				}
				
				PartySyncActs(hourglasses, Sender);
				SendOnlinePartyCommand(actSync.EncodeJson(actSync), 'APActSync', GetALocalPlayerController().Pawn, Sender);
			}
			else 
			{
				// send response to let our buddy know we have a matching seed
				SendOnlinePartyCommand("MatchingSeed", 'APSeedCheck', GetALocalPlayerController().Pawn, Sender);
			}
		}
	}
	else if (CommandChannel == 'APLocationSync')
	{
		locSync = class'JsonObject'.static.DecodeJson(Command);
		isLive = locSync.GetBoolValue("IsLive");
		map = `GameManager.GetCurrentMapFilename();
		
		i = 0;
		while (locSync.GetIntValue(string(i)) > 0)
		{
			locId = locSync.GetIntValue(string(i));
			if (!IsLocationChecked(locId))
			{
				SlotData.CheckedLocations.AddItem(locId);
				if (IsLive && map == Sender.CurrentMapName)
				{
					a = LocationIdToObject(locId, class'Archipelago_RandomizedItem_Base');
					if (a != None)
					{
						a.Destroy();
					}
					else
					{
						a = LocationIdToObject(locId, class'Hat_TreasureChest_Base');
						if (a != None && !Hat_TreasureChest_Base(a).Opened
							&& class<Hat_Collectible_StoryBookPage>(Hat_TreasureChest_Base(a).Content) == None)
						{
							Hat_TreasureChest_Base(a).Empty();
						}
					}
				}
				
				DebugMessage("Syncing location" $locId $" from " $Sender.GetDisplayName());
			}
			
			i++;
		}
	}
	else if (CommandChannel == 'APActSync')
	{
		i = 0;
		actSync = class'JsonObject'.static.DecodeJson(Command);

		while (actSync.GetStringValue(string(i)) != "")
		{
			hourglass = actSync.GetStringValue(string(i));
			
			if (!HasAPBit("ActComplete_"$hourglass, 1))
			{
				SetAPBits("ActComplete_"$hourglass, 1);
				DebugMessage("Syncing act" $hourglass $" from " $Sender.GetDisplayName());
			}
			
			i++;
		}
	}
	
	SaveGame();
	locSync = None;
	actSync = None;
}

function ResendLocations()
{
	if (!IsFullyConnected() || ItemResender == None)
		return;

	ItemResender.ResendLocations();
}

function LoadSlotData(JsonObject json)
{
	local array<Hat_ChapterInfo> chapters;
	local array<string> actNames;
	local ShuffledAct actShuffle;
	local string n;
	local int i, j, v;
	local class<Hat_SnatcherContract_DeathWish> dw;
	
	if (SlotData.Initialized)
		return;
	
	SlotData.ConnectedOnce = true;
	SlotData.Goal = json.GetIntValue("EndGoal");
	SlotData.LogicDifficulty = json.GetIntValue("LogicDifficulty");
	SlotData.KnowledgeTricks = json.GetBoolValue("KnowledgeChecks");
	SlotData.ActRando = json.GetBoolValue("ActRandomizer");
	SlotData.ShuffleStorybookPages = json.GetBoolValue("ShuffleStorybookPages");
	SlotData.ShuffleActContracts = json.GetBoolValue("ShuffleActContracts");
	SlotData.ShuffleZiplines = json.GetBoolValue("ShuffleAlpineZiplines");
	SlotData.UmbrellaLogic = json.GetBoolValue("UmbrellaLogic");
	SlotData.ShuffleSubconPaintings = json.GetBoolValue("ShuffleSubconPaintings");
	SlotData.CTRSprint = json.GetBoolValue("CTRWithSprint");
	SlotData.DeathLink = json.GetBoolValue("death_link");
	SlotData.Seed = json.GetIntValue("SeedNumber");
	SlotData.HatItems = json.GetBoolValue("HatItems");
	
	SlotData.CompassBadgeMode = json.GetIntValue("CompassBadgeMode");
	
	SlotData.Chapter1Cost = json.GetIntValue("Chapter1Cost");
	SlotData.Chapter2Cost = json.GetIntValue("Chapter2Cost");
	SlotData.Chapter3Cost = json.GetIntValue("Chapter3Cost");
	SlotData.Chapter4Cost = json.GetIntValue("Chapter4Cost");
	SlotData.Chapter5Cost = json.GetIntValue("Chapter5Cost");
	
	SlotData.DLC1 = json.GetBoolValue("EnableDLC1");
	SlotData.DLC2 = json.GetBoolValue("EnableDLC2");
	
	if (SlotData.DLC1)
	{
		SlotData.Chapter6Cost = json.GetIntValue("Chapter6Cost");
		SlotData.ShipShapeCustomTaskGoal = json.GetIntValue("ShipShapeCustomTaskGoal");
		SlotData.Tasksanity = json.GetBoolValue("Tasksanity");
		SlotData.ExcludeTour = json.GetBoolValue("ExcludeTour");
		
		if (SlotData.Tasksanity)
		{
			SlotData.TasksanityTaskStep = json.GetIntValue("TasksanityTaskStep");
			SlotData.TasksanityCheckCount = json.GetIntValue("TasksanityCheckCount");
		}
	}
	
	if (SlotData.DLC2)
	{
		SlotData.Chapter7Cost = json.GetIntValue("Chapter7Cost");
		for (i = 0; i < ThugCatShops.Length; i++)
		{
			// Set shop item count as level bit
			DebugMessage(ThugCatShops[i] $" THUG SHOP COUNT: "$json.GetIntValue(ThugCatShops[i]));
			SetAPBits(ThugCatShops[i], json.GetIntValue(ThugCatShops[i]));
		}
		
		SlotData.MetroMinPonCost = json.GetIntValue("MetroMinPonCost");
		SlotData.MetroMaxPonCost = json.GetIntValue("MetroMaxPonCost");
		SlotData.MetroMinPonCost = Min(SlotData.MetroMinPonCost, SlotData.MetroMaxPonCost);
		SlotData.MetroMaxPonCost = Max(SlotData.MetroMinPonCost, SlotData.MetroMaxPonCost);
	}
	
	SlotData.DeathWish = json.GetBoolValue("EnableDeathWish");
	if (SlotData.DeathWish)
	{
		SlotData.BonusRewards = json.GetBoolValue("DWEnableBonus");
		SlotData.AutoCompleteBonuses = json.GetBoolValue("DWAutoCompleteBonuses");
		SlotData.DeathWishTPRequirement = json.GetIntValue("DWTimePieceRequirement");
		SlotData.DeathWishShuffle = json.GetBoolValue("DWShuffle");
		if (SlotData.DeathWishShuffle)
		{
			for (i = 0; i <= 99; i++)
			{
				n = json.GetStringValue("dw_"$i);
				if (n == "")
					break;

				dw = class<Hat_SnatcherContract_DeathWish>(class'Hat_ClassHelper'.static.ClassFromName(n));
				if (dw == None)
				{
					ScreenMessage("Invalid Death Wish class: " $n $", please report", 'Warning');
					continue;
				}
				
				SlotData.ShuffledDeathWishes.AddItem(dw);
			}
		}
		
		for (i = 0; i <= 99; i++)
		{
			n = json.GetStringValue("excluded_dw"$i);
			if (n == "")
				break;
			
			dw = class<Hat_SnatcherContract_DeathWish>(class'Hat_ClassHelper'.static.ClassFromName(n));
			if (dw == None)
			{
				ScreenMessage("Invalid Death Wish class: " $n $", please report", 'Warning');
				continue;
			}
			
			SlotData.ExcludedContracts.AddItem(dw);
		}
		
		for (i = 0; i <= 99; i++)
		{
			n = json.GetStringValue("excluded_bonus"$i);
			if (n == "")
				break;
			
			dw = class<Hat_SnatcherContract_DeathWish>(class'Hat_ClassHelper'.static.ClassFromName(n));
			if (dw == None)
			{
				ScreenMessage("Invalid Death Wish class: " $n $", please report", 'Warning');
				continue;
			}
			
			SlotData.ExcludedBonuses.AddItem(dw);
		}
		
		SlotData.DeathWishOnly = json.GetBoolValue("DeathWishOnly");
		if (SlotData.DeathWishOnly)
		{
			class'Hat_SaveBitHelper'.static.SetLevelBits("DeathWish_intro", 1, `GameManager.HubMapName);
			UnlockAlmostEverything();
		}
	}
	
	SlotData.BaseballBat = json.GetBoolValue("BaseballBat");
	
	SlotData.SprintYarnCost = json.GetIntValue("SprintYarnCost");
	SlotData.BrewingYarnCost = json.GetIntValue("BrewingYarnCost");
	SlotData.IceYarnCost = json.GetIntValue("IceYarnCost");
	SlotData.DwellerYarnCost = json.GetIntValue("DwellerYarnCost");
	SlotData.TimeStopYarnCost = json.GetIntValue("TimeStopYarnCost");
	
	SlotData.BadgeSellerItemCount = json.GetIntValue("BadgeSellerItemCount");
	SlotData.MinPonCost = json.GetIntValue("MinPonCost");
	SlotData.MaxPonCost = json.GetIntValue("MaxPonCost");
	SlotData.MinPonCost = Min(SlotData.MinPonCost, SlotData.MaxPonCost);
	SlotData.MaxPonCost = Max(SlotData.MinPonCost, SlotData.MaxPonCost);
	
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
				if (n ~= "DeadBirdBasement")
				{
					// Ch.2 true finale needs a special flag, since there's no unique ChapterActInfo for it
					actShuffle = CreateShuffledAct(Hat_ChapterActInfo(DynamicLoadObject(actNames[v], class'Hat_ChapterActInfo')), None);
					actShuffle.IsDeadBirdBasementShuffledAct = true;
				}
				else
				{
					actShuffle = CreateShuffledAct(Hat_ChapterActInfo(DynamicLoadObject(actNames[v], class'Hat_ChapterActInfo')), 
													Hat_ChapterActInfo(DynamicLoadObject(n, class'Hat_ChapterActInfo')));
				}
				
				/*
				if (actShuffle.NewAct != None && actShuffle.NewAct.Hourglass == "")
				{
					SetAPBits("ActComplete_"$actShuffle.OriginalAct.hourglass, 1);
				}
				*/
				
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
	
	if (SlotData.UmbrellaLogic)
	{
		ReplaceUnarmedWeapon();
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
	local Hat_ChapterActInfo act, shuffled, ceremony;
	local bool basementShuffle;
	local int basement;

	if (!IsArchipelagoEnabled())
		return;
	
	if (InStr(MapName, "timerift_", false, true) == 0)
		return;
	
	ActMapChange = true;
	
	if (!SlotData.ActRando)
	{
		if (Hat_ChapterInfo(ChapterInfo).ChapterID == 4)
		{
			if (ActID == 99 && class'Hat_SaveBitHelper'.static.HasLevelBit("Actless_FreeRoam_Intro_Complete", 1, "AlpsAndSails"))
			{
				ActID = 1;
				
				if (class'Hat_SeqCond_IsAlpineFinale'.static.IsAlpineFinale())
					DisableAlpineFinale();
			}
			else if (ActID == 1)
			{
				EnableAlpineFinale();
			}
		}
		else if (Hat_ChapterInfo(ChapterInfo).ChapterID == 7)
		{
			// ActID 99 is intro, skip if completed
			if (ActID == 99 && IsActReallyCompleted(GetChapterActInfoFromHourglass("Metro_Intro")))
				ActID = 98;
		}
		
		if (Hat_ChapterInfo(ChapterInfo).ChapterID != 2)
			return;
	}
	
	if (Hat_ChapterInfo(ChapterInfo).ChapterID == 2)
	{
		ceremony = Hat_ChapterActInfo(DynamicLoadObject(
			"hatintime_chapterinfo.BattleOfTheBirds.BattleOfTheBirds_AwardCeremony", class'Hat_ChapterActInfo'));
		
		if (MapName ~= "DeadBirdStudio")
		{
			// If we are entering the Chapter 2 true finale, force Award Ceremony if it hasn't been completed
			if (ActID == 6)
			{
				if (!IsActReallyCompleted(ceremony))
				{
					if (!SlotData.ActRando)
					{
						MapName = "dead_cinema";
						return;
					}
					else
					{
						act = ceremony;
					}
				}
				else if (SlotData.ActRando)
				{
					basementShuffle = true;
				}
			}
			else
			{
				// This is the actual Act 1
				act = Hat_ChapterInfo(ChapterInfo).GetChapterActInfoFromActID(ActID);
			}
		}
		else if (MapName ~= "dead_cinema")
		{
			// If the game wants us to go to Award Ceremony, go to the true finale instead if Award Ceremony is completed.
			// In the act randomizer, Award Ceremony is not shuffled due to this.
			if (SlotData.ActRando)
			{
				if (!IsActReallyCompleted(ceremony))
					return;
				
				basementShuffle = true; // Go to true finale shuffled act
			}
			else if (IsActReallyCompleted(ceremony))
			{
				MapName = "DeadBirdStudio"; // Go to true finale
				return;
			}
		}
		else
		{
			// Normal Chapter 2 act
			act = Hat_ChapterInfo(ChapterInfo).GetChapterActInfoFromActID(ActID);
		}
	}
	else
	{
		// Normal act
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
			return;
	}
	else
	{
		// Normal act
		shuffled = GetShuffledAct(act, basement);
	}
	
	if (shuffled == None && basement == 0)
	{
		DebugMessage("[ERROR] Failed to find shuffled act for " $act, , true);
		ScriptTrace();
		return;
	}
	
	if (basement == 1)
	{
		ActMapChangeChapter = 2;
		ActID = 6;
		MapName = "DeadBirdStudio";
	}
	else // Normal act shuffle
	{
		ActMapChangeChapter = shuffled.ChapterInfo.ChapterID;
		ActID = shuffled.ActID;
		MapName = shuffled.MapName;
	}
	
	// Game will override it if we do it here
	SetTimer(0.01, false, NameOf(SetMapChangeChapter));

	if (shuffled.ChapterInfo.ChapterID == 4)
	{
		// Free Roam
		if (ActID == 99)
		{
			if (class'Hat_SaveBitHelper'.static.HasLevelBit("Actless_FreeRoam_Intro_Complete", 1, "AlpsAndSails"))
				ActID = 1;
			
			if (class'Hat_SeqCond_IsAlpineFinale'.static.IsAlpineFinale())
				DisableAlpineFinale();
		}
		else if (ActID == 1 && !shuffled.IsBonus)
		{
			EnableAlpineFinale();
		}
	}
	else if (shuffled.ChapterInfo.ChapterID == 7)
	{
		// ActID 99 is intro, skip if completed
		if (ActID == 99 && IsActReallyCompleted(GetChapterActInfoFromHourglass("Metro_Intro")))
			ActID = 98;
	}
	
	DebugMessage("Switching act " $PathName(act) $" with act: " $PathName(shuffled) $", map:" $MapName $" Act ID: "$ActID);
}

function SetMapChangeChapter()
{
	`SaveManager.SetCurrentChapter(ActMapChangeChapter);
}

function OnMiniMissionBegin(Object MiniMission)
{
	if (!IsArchipelagoEnabled() || !SlotData.Initialized)
		return;
	
	if (Hat_MiniMissionTaskMaster(MiniMission) == None) 
		return;
	
	if (!`GameManager.IsCurrentAct(2))
		return;
	
	if (class'Hat_SnatcherContract_DeathWish_EndlessTasks'.static.IsActive(true))
		return;
	
	if (Hat_MiniMissionTaskMaster(MiniMission).MissionMode == MiniMissionTaskMaster_ScoreTarget)
		Hat_MiniMissionTaskMaster(MiniMission).ScoreTarget = SlotData.ShipShapeCustomTaskGoal;
}

function OnMiniMissionGenericEvent(Object MiniMission, String id)
{
	if (!IsArchipelagoEnabled() || !SlotData.Initialized || !SlotData.Tasksanity)
		return;
	
	if (Hat_MiniMissionTaskMaster(MiniMission) == None) 
		return;
	
	if (!`GameManager.IsCurrentAct(2))
		return;
	
	if (class'Hat_SnatcherContract_DeathWish_EndlessTasks'.static.IsActive(true))
		return;
	
	if (SlotData.CompletedTasks >= SlotData.TasksanityCheckCount)
		return;
	
	if (id == "score")
	{
		SlotData.TaskStep++;
		if (SlotData.TaskStep >= SlotData.TasksanityTaskStep)
		{
			SlotData.TaskStep = 0;
			SendLocationCheck(TasksanityIDStart + SlotData.CompletedTasks);
			SlotData.CompletedTasks++;
		}
	}
}

function OnPreOpenHUD(HUD InHUD, out class<Object> InHUDElement)
{
	if (IsCurrentPatch())
		return;

	// These get extremely annoying as they pop up every time a new save file is present when going into the save select screen
	if (InHUDElement == class'Hat_HUDMenuDLCSplash')
		InHUDElement = None;
	
	if (!IsArchipelagoEnabled())
		return;
	
	switch (InHUDElement)
	{
		case class'Hat_HUDMenuLoadout':
			Hat_HUD(InHUD).OpenHUD(class'Archipelago_HUDElementInfoButton', , true);
			break;
		
		case class'Hat_HUDElementGhostPartyJoinAct':
			if (SlotData == None || SlotData.ActRando)
				InHUDElement = None;
			
			break;
		
		case class'Hat_HUDElementLocationBanner_Metro':
			if (`GameManager.GetCurrentMapFilename() != "dlc_metro")
				break;
			
			InHUDElement = class'Archipelago_HUDElementLocationBanner_Metro';
			break;
		
		case class'Hat_HUDMenuDeathWish':
			if (!SlotData.DeathWish)
				break;
			
			InHUDElement = class'Archipelago_HUDMenuDeathWish';
			break;
		
		case class'Hat_HUDElementRareStickerAlert':
			SetTimer(0.0001, false, NameOf(RemoveRareStickerAlert), self, Hat_HUD(InHUD));
			break;
		
		case class'Hat_HUDMenuShop':
			SetTimer(0.0001, false, NameOf(CheckShopOverride), self, Hat_HUD(InHUD));
			break;
		
		case class'Hat_HUDMenuActSelect':
			if (!SlotData.DeathWishOnly)
				InHUDElement = class'Archipelago_HUDMenuActSelect';
			
			break;
		
		case class'Hat_HUDElementActTitleCard':
			if (SlotData != None && SlotData.ActRando && !ActMapChange)
				SetTimer(0.0001, false, NameOf(CheckActTitleCard), self, Hat_HUD(InHUD));
			
			break;
		
		case class'Hat_HUDElementCinematic':
			SetTimer(0.1, false, NameOf(OnCutsceneStart), self, Hat_HUD(InHUD));
			break;
	
		default:
			break;
	}
}

function CheckDeathWishObjectives()
{
	local int i;
	local array< class<Hat_SnatcherContract_DeathWish> > dws;
	dws = class'Hat_SnatcherContract_DeathWish'.static.GetActiveDeathWishes();
	for (i = 0; i < dws.Length; i++)
	{
		if (dws[i].default.RequiredDLC == class'Hat_GameDLCInfo_DLC2' && !SlotData.DLC2)
			continue;
		
		if (SlotData.PerfectedDeathWishes.Find(dws[i]) != -1)
			continue;
		
		if (dws[i].static.IsContractPerfected() || dws[i].static.IsContractComplete() && SlotData.CompletedDeathWishes.Find(dws[i]) == -1)
			OnDeathWishObjectiveCompleted(dws[i]);
	}
}

function OnDeathWishObjectiveCompleted(class<Hat_SnatcherContract_DeathWish> dw)
{
	local int id;
	local array<int> locIds;
	
	id = class'Archipelago_ItemInfo'.static.GetDeathWishLocationID(dw);
	if (id <= 0)
	{
		ScreenMessage("[OnDeathWishObjectiveCompleted] contract with missing location ID: "$dw, 'Warning');
		return;
	}
	
	if (dw.static.IsContractComplete() && SlotData.CompletedDeathWishes.Find(dw) == -1)
	{
		if (SlotData.AutoCompleteBonuses)
		{
			dw.static.SetObjectiveFailed(1, false);
			dw.static.SetObjectiveFailed(2, false);
			class'Hat_HUDElementContractObjectives'.static.TriggerContractObjectiveStatic(dw, 1);
			class'Hat_HUDElementContractObjectives'.static.TriggerContractObjectiveStatic(dw, 2);
			dw.static.ForceUnlockObjective(1);
			dw.static.ForceUnlockObjective(2);
		}
		
		if (SlotData.Goal == 3 && dw.default.class == class'Hat_SnatcherContract_DeathWish_BossRushEX')
		{
			BeatGame();
		}
		
		SlotData.CompletedDeathWishes.AddItem(dw);
		locIds.AddItem(id);
	}
	
	if (SlotData.AutoCompleteBonuses || dw.static.IsContractPerfected() && !dw.static.IsDeathWishEasyMode())
	{
		SlotData.PerfectedDeathWishes.AddItem(dw);
		
		if (SlotData.BonusRewards)
			locIds.AddItem(id+1);
	}
	
	if (locIds.Length > 0)
		SendMultipleLocationChecks(locIds);
}

function CheckShopOverride(Hat_HUD hud)
{
	local Actor merchant;
	local Hat_MetroTicketBooth_Base booth;
	local int i;
	local array<int> hintIds;
	local Hat_HUDMenuShop shop;
	local ShopItemInfo shopInfo;
	local array<class <Object> > shopInvs;
	local Archipelago_ShopInventory_Base newShop;
	local Hat_Loadout lo;
	
	if (SlotData.DeathWishOnly)
		return;
	
	shopInvs = class'Hat_ClassHelper'.static.GetAllScriptClasses("Archipelago_ShopInventory_Base");
	shop = Hat_HUDMenuShop(hud.GetHUD(class'Hat_HUDMenuShop'));
	merchant = shop.MerchantActor;
	
	if (merchant.IsA('Hat_NPC_MetroCreepyCat_FoodShop') || merchant.IsA('Hat_NPC_MetroHelpDesk'))
		return;
	
	if (merchant.IsA('Hat_NPC_MetroCreepyCat') && !merchant.IsA('Hat_NPC_NyakuzaShop'))
	{
		foreach DynamicActors(class'Hat_MetroTicketBooth_Base', booth)
		{
			if (booth.BoothCat.Name == merchant.Name)
			{
				merchant = booth;
				break;
			}
		}
	}
	
	if (merchant.IsA('Hat_NPC_MetroCreepyCat') && !merchant.IsA('Hat_NPC_NyakuzaShop'))
		return;
	
	if (merchant.IsA('Hat_NPC_MetroTicketBooth_Base'))
		shop.PurchaseDelegates.Length = 0;
	
	for (i = 0; i < shopInvs.Length; i++)
	{
		if (class<Archipelago_ShopInventory_Base>(shopInvs[i]).default.ShopNPC != None
			&& class<Archipelago_ShopInventory_Base>(shopInvs[i]).default.ShopNPC == merchant.Class
			|| class<Archipelago_ShopInventory_Base>(shopInvs[i]).default.ShopNPCName != ""
			&& class<Archipelago_ShopInventory_Base>(shopInvs[i]).default.ShopNPCName == string(merchant.Name))
		{
			newShop = new class<Archipelago_ShopInventory_Base>(shopInvs[i]);
			break;
		}
	}
	
	if (newShop == None)
		return;
	
	for (i = 0; i < newShop.ItemsForSale.Length; i++)
	{
		GetShopItemInfo(class<Archipelago_ShopItem_Base>(newShop.ItemsForSale[i].CollectibleClass), shopInfo);
		newShop.ItemsForSale[i].ItemCost = shopInfo.PonCost;
		
		if (IsLocationChecked(shopInfo.ID))
		{
			// Someone in Online Party may have already bought this, add the collectible class so it appears as purchased
			lo = Hat_PlayerController(GetALocalPlayerController()).MyLoadout;
			if (!lo.HasCollectible(newShop.ItemsForSale[i].CollectibleClass))
			{
				lo.AddCollectible(newShop.ItemsForSale[i].CollectibleClass);
			}
			
			continue;
		}
		
		if (shopInfo.ID <= 0)
			continue;
		
		if (!shopInfo.Hinted)
		{
			if (shopInfo.ItemFlags == ItemFlag_Important || shopInfo.ItemFlags == ItemFlag_ImportantSkipBalancing)
			{
				hintIds.AddItem(shopInfo.ID);
				SetShopInfoAsHinted(shopInfo);
			}
		}
	}
	
	if (merchant.IsA('Hat_NPC_BadgeSalesman'))
	{
		newShop.ItemsForSale.Length = SlotData.BadgeSellerItemCount;
	}
	else if (InStr(newShop.ShopNPCName, "Hat_NPC_NyakuzaShop") != -1)
	{
		newShop.ItemsForSale.Length = GetAPBits(newShop.ShopNPCName);
	}
	
	if (newShop.ItemsForSale.Length <= 0 && !merchant.IsA('Hat_NPC_BadgeSalesman'))
		return;
	
	hintIds.Length = newShop.ItemsForSale.Length;
		
	for (i = 0; i < hintIds.Length; i++)
	{
		if (hintIds[i] <= 0)
		{
			hintIds.RemoveItem(hintIds[i]);
			i--;
		}
	}
	
	if (hintIds.Length > 0)
		SendMultipleLocationChecks(hintIds, true, true);
	
	shop.SetShopInventory(hud, newShop);
}

function CheckActTitleCard(Hat_HUD hud)
{
	local string map;
	local int actId, basement, chapterId;
	local Hat_HUDElementActTitleCard card;
	local Hat_ChapterActInfo newAct;
	
	card = Hat_HUDElementActTitleCard(hud.GetHUD(class'Hat_HUDElementActTitleCard', true));
	if (card.IsNonMapChangeTitlecard || card.IsDeathWish)
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
			map = newAct.MapName;
			actId = newAct.ActID;
		}
		
		if (chapterId == 4)
		{
			if (actId == 99)
			{
				if (class'Hat_SaveBitHelper'.static.HasLevelBit("Actless_FreeRoam_Intro_Complete", 1, "AlpsAndSails"))
					actId = 1;
				
				if (class'Hat_SeqCond_IsAlpineFinale'.static.IsAlpineFinale())
					DisableAlpineFinale();
			}
			else if (actId == 1 && !newAct.IsBonus)
			{
				EnableAlpineFinale();
			}
		}
		else if (chapterId == 7)
		{
			// ActID 99 is intro, skip if completed
			if (actId == 99 && IsActReallyCompleted(GetChapterActInfoFromHourglass("Metro_Intro")))
				actId = 98;
		}
		
		`GameManager.LoadNewAct(chapterId, actId);
		card.MapName = map;
	}
}

function OnCutsceneStart(Hat_HUD hud)
{
	local Hat_HUDElementCinematic cutscene;
	
	cutscene = Hat_HUDElementCinematic(hud.GetHUD(class'Hat_HUDElementCinematic'));
	if (cutscene == None)
		return;
	
	// Skip Nyakuza intro cutscene manually if already watched once since it will keep replaying 
	// presumably due to not having the Metro_Intro time piece
	if (`GameManager.GetCurrentMapFilename() ~= "dlc_metro")
	{
		if (HasAPBit("MetroCutscene", 1))
		{
			cutscene.IsSkippingCinematic = 99;
		}
		
		SetAPBits("MetroCutscene", 1);
	}
}

function RemoveRareStickerAlert(Hat_HUD hud)
{
	local Hat_HUDElementRareStickerAlert alert;
	alert = Hat_HUDElementRareStickerAlert(hud.GetHUD(class'Hat_HUDElementRareStickerAlert', true));
	alert.Progress = 0.99;
}

static function bool HasZipline(EZiplineType zipline)
{
	local string id;
	
	switch (zipline)
	{
		case Zipline_Birdhouse:
			id = "Hat_SandTravelNode_44";
			break;
		
		case Zipline_LavaCake:
			id = "Hat_SandTravelNode_15";
			break;
		
		case Zipline_Windmill:
			id = "Hat_SandTravelNode_17";
			break;
		
		case Zipline_Bell:
			id = "Hat_SandTravelNode_43";
			break;
	}
	
	return HasAPBit("ZiplineUnlock_"$id, 1);
}

function ShowSeedInfoMenu()
{
	Hat_HUD(GetALocalPlayerController().MyHUD).OpenHUD(class'Archipelago_HUDMenuSeedInfo');
}

static function int GetPaintingUnlocks()
{
	return GetAPBits("PaintingUnlock");
}

function bool IsAwardCeremonyCompleted()
{
	return IsActReallyCompleted(GetChapterActInfoFromHourglass("award_ceremony"));
}

static function EnableAlpineFinale()
{
	SetAPBits("AlpineFinale", 1);
	class'Hat_SaveBitHelper'.static.SetActBits("ForceAlpineFinale", 1);
}

static function DisableAlpineFinale()
{
	SetAPBits("AlpineFinale", 0);
	class'Hat_SaveBitHelper'.static.SetActBits("ForceAlpineFinale", 0);
}

function OnTimePieceCollected(string Identifier)
{
	local int i, id;
	local Hat_ChapterActInfo currentAct;
	local string hourglass;
	local bool actless, basement;
	
	if (!IsArchipelagoEnabled() || SlotData.DeathWishOnly)
		return;
	
	if (InStr(Identifier, "ap_timepiece") != -1)
		return;
	
	`SaveManager.GetCurrentSaveData().RemoveTimePiece(Identifier);
	
	if (class'Hat_SnatcherContract_DeathWish'.static.IsAnyActive(false))
		return;

	if (SlotData.Goal == 1 && Identifier ~= "TheFinale_FinalBoss"
		|| SlotData.Goal == 2 && Identifier ~= "Metro_Escape")
	{
		BeatGame();
	}
	
	id = GetTimePieceLocationID(Identifier);
	DebugMessage("Collected Time Piece: "$Identifier $", Location ID = " $id);
	
	actless = (Identifier ~= "Alps_Birdhouse"
	|| Identifier ~= "AlpineSkyline_WeddingCake"
	|| Identifier ~= "Alpine_Twilight"
	|| Identifier ~= "AlpineSkyline_Windmill"
	|| Identifier ~= "Metro_Intro"
	|| InStr(Identifier, "Metro_Route") != -1 || InStr(Identifier, "Metro_Manhole") != -1);
	
	// We actually completed this act, so set the Time Piece ID as a level bit
	if (SlotData.ActRando)
	{
		if (actless)
		{
			hourglass = Identifier;
			DebugMessage("Completed act: " $GetChapterActInfoFromHourglass(Identifier));
		}
		else
		{
			// We entered this act from a different act, set the original act's Time Piece instead
			currentAct = GetChapterActInfoFromHourglass(Identifier);
			basement = (Identifier ~= "chapter3_secret_finale");
			
			for (i = 0; i < SlotData.ShuffledActList.Length; i++)
			{
				if (!basement && SlotData.ShuffledActList[i].NewAct == currentAct 
				|| basement && SlotData.ShuffledActList[i].IsDeadBirdBasementShuffledAct)
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
		}
		
		SetAPBits("ActComplete_"$hourglass, 1);
		PartySyncActs_Single(hourglass);
	}
	else
	{
		DebugMessage("Completed act: " $GetChapterActInfoFromHourglass(Identifier));
		SetAPBits("ActComplete_"$Identifier, 1);
		PartySyncActs_Single(hourglass);
	}
	
	if (hourglass == "")
	{
		DebugMessage("FAILED to find ChapterActInfo: "$Identifier, , true);
		ScriptTrace();
	}
	
	SendLocationCheck(id);
}

static function int GetTimePieceLocationID(string Identifier)
{
	local int id, i;
	
	// Happens to be the same as Green Clean Station
	if (Identifier ~= "Metro_Escape")
		return 311210;
	
	for (i = 0; i < Len(Identifier); i++)
		id += Asc(Mid(Identifier, i, 1));
	
	return id + ActCompleteIDRange;
}

function Hat_ChapterActInfo GetChapterActInfoFromHourglass(string hourglass)
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
			if (act.Hourglass ~= hourglass)
				return act;
		}
	}
	
	return None;
}

function UpdateChapterInfo()
{
	if (!SlotData.Initialized)
		return;
	
	SetChapterTimePieceRequirement(Hat_ChapterInfo'HatinTime_ChapterInfo.maingame.MafiaTown', SlotData.Chapter1Cost);
	SetChapterTimePieceRequirement(Hat_ChapterInfo'HatinTime_ChapterInfo.maingame.trainwreck_of_science', SlotData.Chapter2Cost);
	SetChapterTimePieceRequirement(Hat_ChapterInfo'HatinTime_ChapterInfo.maingame.subconforest', SlotData.Chapter3Cost);
	SetChapterTimePieceRequirement(Hat_ChapterInfo'HatinTime_ChapterInfo.maingame.Sand_and_Sails', SlotData.Chapter4Cost);
	SetChapterTimePieceRequirement(Hat_ChapterInfo'HatinTime_ChapterInfo.maingame.Mu_Finale', SlotData.Chapter5Cost);
	
	if (SlotData.DLC1)
	{
		SetChapterTimePieceRequirement(Hat_ChapterInfo'HatinTime_ChapterInfo_DLC1.ChapterInfos.ChapterInfo_Cruise', SlotData.Chapter6Cost);
	}
	else
	{
		SetChapterTimePieceRequirement(Hat_ChapterInfo'HatinTime_ChapterInfo_DLC1.ChapterInfos.ChapterInfo_Cruise', 99);
	}
	
	if (SlotData.DLC2)
	{
		SetChapterTimePieceRequirement(Hat_ChapterInfo'hatintime_chapterinfo_dlc2.ChapterInfos.ChapterInfo_Metro', SlotData.Chapter7Cost);
	}
	else
	{
		SetChapterTimePieceRequirement(Hat_ChapterInfo'hatintime_chapterinfo_dlc2.ChapterInfos.ChapterInfo_Metro', 99);
	}
	
	UpdateActUnlocks();

	if (IsInSpaceship() && !class'Hat_SeqCond_IsMuMission'.static.IsFinaleMuMission() 
		&& !class'Hat_SaveBitHelper'.static.HasActBit("thefinale_ending", 1))
	{
		UpdatePowerPanels();
		OpenBedroomDoor();
	}
	
	SaveGame();
}

function ResetEverything()
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
			if (act.IsBonus && !IsPurpleRift(act))
			{
				act.RequiredActID.Length = 0;
				
				switch (act.MapName)
				{
					case "TimeRift_Water_Mafia_Easy": // Sewers
						act.RequiredActID.AddItem(4);
						break;

					case "TimeRift_Water_Mafia_Hard": // Bazaar
						act.RequiredActID.AddItem(6);
						break;

					case "TimeRift_Water_TWreck_Panels": // The Owl Express
						act.RequiredActID.AddItem(2);
						act.RequiredActID.AddItem(3);
						break;
					
					case "TimeRift_Water_TWreck_Parade": // The Moon
						act.RequiredActID.AddItem(4);
						act.RequiredActID.AddItem(5);
						break;
					
					case "TimeRift_Water_Subcon_Hookshot": // Pipe
						act.RequiredActID.AddItem(2);
						break;
					
					case "TimeRift_Water_Subcon_Dwellers": // Village
						act.RequiredActID.AddItem(4);
						break;
					
					case "TimeRift_Water_Alp_Cats": // Curly Tail Trail
						act.RequiredActID.AddItem(13);
						break;
					
					case "TimeRift_Water_Alp_Goats": // The Twilight Bell
						act.RequiredActID.AddItem(15);
						break;

					case "TimeRift_Water_Cruise_Slide": // Balcony
						act.RequiredActID.AddItem(3);
						break;
					
					default:
						break;
				}
			}
		}
	}
	
	SetChapterTimePieceRequirement(Hat_ChapterInfo'HatinTime_ChapterInfo.maingame.MafiaTown', 1);
	SetChapterTimePieceRequirement(Hat_ChapterInfo'HatinTime_ChapterInfo.maingame.trainwreck_of_science', 4);
	SetChapterTimePieceRequirement(Hat_ChapterInfo'HatinTime_ChapterInfo.maingame.subconforest', 7);
	SetChapterTimePieceRequirement(Hat_ChapterInfo'HatinTime_ChapterInfo.maingame.Sand_and_Sails', 14);
	SetChapterTimePieceRequirement(Hat_ChapterInfo'HatinTime_ChapterInfo.maingame.Mu_Finale', 25);
	SetChapterTimePieceRequirement(Hat_ChapterInfo'HatinTime_ChapterInfo_DLC1.ChapterInfos.ChapterInfo_Cruise', 35);
	
	ConsoleCommand("set Hat_IntruderInfo_CookingCat HasIntruderAlert true");
    ConsoleCommand("set hat_snatchercontract_deathwish_riftcollapse PenaltyWaitTimeInSeconds 300");
    ConsoleCommand("set hat_snatchercontract_deathwish_riftcollapse Condition_3Lives true");
	ConsoleCommand("set hat_snatchercontract_deathwish neverobscureobjectives false");
}

function OpenBedroomDoor()
{
	local Hat_SpaceshipPowerPanel panel;
	
	foreach DynamicActors(class'Hat_SpaceshipPowerPanel', panel)
	{
		if (panel.ChapterInfo.ChapterID == 3)
		{
			panel.SpaceshipDoor.Enabled = true;
			panel.SpaceshipDoor.bBlocksNavigation = false;
			panel.SpaceshipDoor.SetLockedVisuals(false);
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
			if (act.IsBonus && !IsPurpleRift(act) && IsChapterActInfoUnlocked(act))
			{
				act.RequiredActID.Length = 0;
				act.RequiredActID.AddItem(0); // else game thinks it's a purple rift
			}
		}
	}
}

function bool IsActCompletable(Hat_ChapterActInfo act, Hat_Loadout lo, optional bool basement)
{
	local int difficulty;
	local bool canHit, canHitMaskBypass, hookshot, umbrella, sdj, nobonk;

	if (SlotData.DeathWishOnly)
		return true;
	
	difficulty = SlotData.LogicDifficulty; // 0 = Normal, 1 = Hard, 2 = Expert
	
	// Can hit objects, has Umbrella or Brewing Hat, only for umbrella logic
	canHit = !SlotData.UmbrellaLogic || class'Archipelago_HUDElementItemFinder'.static.CanHitObjects();
	
	// Can hit dweller bells, but not needed if player has Dweller Mask, only for umbrella logic
	canHitMaskBypass = !SlotData.UmbrellaLogic || class'Archipelago_HUDElementItemFinder'.static.CanHitObjects(true);
	
	hookshot = lo.BackpackHasInventory(class'Hat_Ability_Hookshot');
	umbrella = !SlotData.UmbrellaLogic || lo.BackpackHasInventory(class'Archipelago_Weapon_Umbrella', true) 
				|| lo.BackpackHasInventory(class'Archipelago_Weapon_BaseballBat', true);
	
	sdj = class'Archipelago_HUDElementItemFinder'.static.CanSDJ();
	nobonk = lo.BackpackHasInventory(class'Hat_Ability_NoBonk');
	
	if (basement)
	{
		return hookshot;
	}
	
	switch (act.hourglass)
	{
		case "mafiatown_lava": case "moon_parade": case "snatcher_boss":
			return umbrella;
		
		case "DeadBirdStudio":
			return canHit;
		
		case "Cruise_Boarding": case "Cruise_WaterRift_Slide": case "TimeRift_Water_Subcon_Hookshot": case "trainwreck_selfdestruct":
			return hookshot;
		
		case "Metro_Escape":
			return hookshot
				&& lo.BackpackHasInventory(class'Hat_Ability_StatueFall')
				&& lo.BackpackHasInventory(class'Hat_Ability_Chemical')
				&& lo.HasCollectible(class'Hat_Collectible_MetroTicket_RouteA')
				&& lo.HasCollectible(class'Hat_Collectible_MetroTicket_RouteC')
				&& lo.HasCollectible(class'Hat_Collectible_MetroTicket_RouteD');
		
		case "chapter2_toiletboss":
			if (difficulty < 2 && SlotData.ShuffleSubconPaintings && GetPaintingUnlocks() < 1)
				return false;
			
			return (hookshot || difficulty >= 1 && sdj && nobonk || difficulty >= 2) && canHit;
		
		case "vanessa_manor_attic":
			if (SlotData.ShuffleSubconPaintings && GetPaintingUnlocks() < 1)
				return false;
			
			return canHitMaskBypass || difficulty >= 2;
		
		case "subcon_village_icewall":
			return !SlotData.ShuffleSubconPaintings || GetPaintingUnlocks() >= 1;
		
		case "subcon_cave":
			if (SlotData.ShuffleSubconPaintings && GetPaintingUnlocks() < 1)
				return false;
			
			return difficulty >= 2 && nobonk || hookshot && canHit;
		
		case "TheFinale_FinalBoss":
			return hookshot && lo.BackpackHasInventory(class'Hat_Ability_FoxMask');
		
		case "Spaceship_WaterRift_Gallery":
			return difficulty >= 1 || lo.BackpackHasInventory(class'Hat_Ability_Chemical');
		
		case "Cruise_Sinking":
			return difficulty >= 1 || lo.BackpackHasInventory(class'Hat_Ability_StatueFall');
		
		case "AlpineSkyline_Finale":
			return hookshot &&
				(!SlotData.ShuffleZiplines || HasZipline(Zipline_Birdhouse) && HasZipline(Zipline_LavaCake) && HasZipline(Zipline_Windmill));
		
		case "TimeRift_Water_AlpineSkyline_Cats":
			return sdj || lo.BackpackHasInventory(class'Hat_Ability_StatueFall');
		
		case "TimeRift_Water_Alp_Goats":
			return lo.BackpackHasInventory(class'Hat_Ability_FoxMask')
				|| difficulty >= 1 && lo.BackpackHasInventory(class'Hat_Ability_Sprint') && lo.BackpackHasInventory(class'Hat_Badge_Scooter');
		
		case "harbor_impossible_race":
			return lo.BackpackHasInventory(class'Hat_Ability_TimeStop')
				|| SlotData.CTRSprint && lo.BackpackHasInventory(class'Hat_Ability_Sprint');
		
		case "subcon_maildelivery":
			return lo.BackpackHasInventory(class'Hat_Ability_Sprint');
		
		// Hitting the bell with fists wastes too much time with the hitstun to cross the dweller platforms
		case "TimeRift_Water_Subcon_Dwellers":
			return lo.BackpackHasInventory(class'Hat_Ability_FoxMask')
				|| (lo.BackpackHasInventory(class'Hat_Ability_Chemical') || lo.BackpackHasInventory(class'Hat_Weapon_Umbrella', true));
		
		default:
			return true;
	}
}

function UpdatePowerPanels()
{
	local Hat_SpaceshipPowerPanel panel;
	local float val;
	
	foreach DynamicActors(class'Hat_SpaceshipPowerPanel', panel)
	{
		if (SlotData.DeathWishOnly && !IsPowerPanelActivated2(panel))
		{
			panel.OnDoUnlock();
			
			if (panel.Telescope != None)
				panel.Telescope.SetUnlocked(true);

			continue;
		}
		
		if (!IsPowerPanelActivated2(panel) && panel.CanBeUnlocked() 
		&& panel.InteractPoint == None && (panel.RuntimeMat == None || !panel.RuntimeMat.GetScalarParameterValue('Unlocked', val) || val == 0))
		{
			panel.InteractPoint = Spawn(class'Hat_InteractPoint',panel,,panel.Location + Vector(panel.Rotation)*10 + vect(0,0,1)*20,panel.Rotation,,true);
			panel.InteractPoint.PushDelegate(panel.OnInteractDelegate);
			
			if (panel.RuntimeMat != None)
				panel.RuntimeMat.SetScalarParameterValue('Unlockable', 1);

			panel.ElectricityParticle[0].SetActive(true);
			panel.ElectricityParticle[1].SetActive(true);
			panel.ReadyToActivateParticle.SetActive(true);
			panel.ClearTimer(NameOf(panel.DoAttentionBeep));
			panel.SetTimer(1.8, true, NameOf(panel.DoAttentionBeep));
		}
	}
}

function bool IsPowerPanelActivated2(Hat_SpaceshipPowerPanel panel)
{
	local Hat_ChapterInfo ci;
	ci = panel.GetChapterInfo();
	
	if (ci == None) return false;
	if (ci.ChapterID <= 0) return false;
	if (!ci.HasDLCSupported(true)) return false;
	if (!class'Hat_SaveBitHelper'.static.HasLevelBit(panel.ActivatedLevelBit, ci.ChapterID)) return false;
	
	return true;
}

function SetChapterTimePieceRequirement(Hat_ChapterInfo chapter, int amount)
{
	local Hat_SpaceshipPowerPanel panel;
	chapter.RequiredHourglassCount = amount;
	
	if (IsInSpaceship() && amount <= 50)
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

function bool IsChapterActInfoUnlocked(Hat_ChapterActInfo ChapterActInfo, optional string ModPackageName)
{
	local string hourglass;
	local int j, actid;
	local Hat_ChapterInfo ChapterInfo;
	local Hat_ChapterActInfo RequiredChapterActInfo, shuffled;
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
	if (!ChapterActInfo.IsBonus && ChapterInfo.IsActless && (ChapterInfo.FinaleActID <= 0 || actid != ChapterInfo.FinaleActID) && !IsFreeRoam
	&& !HasAPBit("ActComplete_"$ChapterActInfo.hourglass, 1)) 
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
			
			// If a Free Roam act is shuffled onto this act, it's a free space
			shuffled = GetShuffledAct(RequiredChapterActInfo);
			if (shuffled != None && IsActFreeRoam(shuffled) && IsChapterActInfoUnlocked(GetOriginalAct(shuffled)) && shuffled.ActID != 1)
				continue;
			
			if (ModPackageName != "")
			{
				hourglass = class'Hat_TimeObject_Base'.static.GetModTimePieceIdentifier(ModPackageName, hourglass);
			}
			
			if (HasAPBit("ActComplete_"$hourglass, 1)) continue;
			
			j = INDEX_NONE;
			break;
		}
		
		return (j != INDEX_NONE);
	}
}

function bool IsPurpleRift(Hat_ChapterActInfo act)
{
	return (act.IsBonus && InStr(act.hourglass, "_cave", false, true) != -1);
}

function ShuffleCollectibles(optional bool cache)
{
	local Hat_Collectible_Important collectible;
	local Hat_NPC npc;
	local int locId, i, maxItems;
	local Actor a;
	local array<int> locationArray, shopLocationArray, forceSendArray;
	local array<class<Object > > shopInvClasses;
	local LocationInfo locInfo;
	local class<Object> shopInvClass;
	local class<Archipelago_ShopItem_Base> shopItem;
	local string mapName, bitName;
	local Archipelago_ShopInventory_Base shopInv;
	
	if (CollectiblesShuffled || SlotData.DeathWishOnly || class'Hat_SnatcherContract_DeathWish'.static.IsAnyActive(false))
		return;
	
	mapName = class'Hat_SaveBitHelper'.static.GetCorrectedMapFilename();
	
	// Fix for Rock the Boat
	DebugMessage("Map Name: "$mapName);
	if (`GameManager.GetCurrentMapFilename() ~= "ship_sinking")
		mapName = "ship_sinking";
	
	foreach DynamicActors(class'Hat_Collectible_Important', collectible)
	{
		if (collectible.IsA('Hat_Collectible_VaultCode_Base') || collectible.IsA('Hat_Collectible_InstantCamera')
		|| collectible.IsA('Hat_Collectible_Sticker') || collectible.IsA('Hat_Collectible_MetroTicket_Base'))
			continue;
		
		// Some items only appear in certain acts
		locId = ObjectToLocationId(collectible);
		if (IsMapScouted(mapName) && !IsLocationCached(locId))
		{
			// We are trying to load from cache. This means we aren't connected. Wait until we are.
			if (cache)
				return;
			
			forceSendArray.AddItem(locId);
		}
		
		locationArray.AddItem(locId);
		if (bool(DebugMode))
		{
			DebugMessage("[ShuffleCollectibles] Found item: " $collectible.GetLevelName() $"."$collectible.Name $ObjectToLocationId(collectible));
		}
	}
	
	DebugMessage("Map Name: " $mapName);
	if (mapName ~= "mafia_town")
	{
		locationArray.AddItem(CameraBadgeCheck1);
		locationArray.AddItem(CameraBadgeCheck2);
	}
	else if (mapName ~= "subconforest")
	{
		locationArray.AddItem(SubconBushCheck1);
		locationArray.AddItem(SubconBushCheck2);
	}
	else if (mapName ~= "hub_spaceship")
	{
		// Rumbi
		locationArray.AddItem(301000);
	}
	
	for (i = 0; i < ChestArray.Length; i++)
	{
		if (ChestArray[i] == None)
			continue;
		
		locationArray.AddItem(ObjectToLocationId(ChestArray[i]));
	}
	
	foreach DynamicActors(class'Actor', a)
	{
		if (a.IsA('Hat_Goodie_Vault_Base'))
		{
			if (a.Name == 'Hat_Goodie_Vault_1') // golden vault
				continue;
			
			locId = ObjectToLocationId(a);

			// Vaults don't appear in HUMT
			if (IsMapScouted(mapName) && !IsLocationCached(locId))
			{
				// We are trying to load from cache. This means we aren't connected. Wait until we are.
				if (cache)
					return;
				
				forceSendArray.AddItem(locId);
			}
			
			locationArray.AddItem(locId);
		}
		else if (a.IsA('Hat_ImpactInteract_Breakable_ChemicalBadge'))
		{
			if (Hat_ImpactInteract_Breakable_ChemicalBadge(a).Rewards.Length <= 0)
				continue;
			
			for (i = 0; i < Hat_ImpactInteract_Breakable_ChemicalBadge(a).Rewards.Length; i++)
			{
				if (class<Hat_Collectible_Important>(Hat_ImpactInteract_Breakable_ChemicalBadge(a).Rewards[i]) != None)
				{
					locationArray.AddItem(ObjectToLocationId(a));
					break;
				}
			}
		}
		else if (SlotData.ShuffleStorybookPages && a.IsA('Hat_Collectible_StoryBookPage') && a.CreationTime <= 0)
		{
			locId = ObjectToLocationId(a);
			locationArray.AddItem(locId);
			
			if (SlotData.PageLocationIDs.Find(locId) == -1)
				SlotData.PageLocationIDs.AddItem(locId);
		}
	}
	
	BulliedNPCArray.Length = 0;
	foreach DynamicActors(class'Hat_NPC', npc)
	{
		if (npc.bHidden || !npc.IsA('Hat_NPC_Bullied'))
			continue;
		
		locId = ObjectToLocationId(npc);
		if (locId != 303832 && locId != 303833)
			continue;
		
		// Old guys don't appear in SCFOS/HUMT
		if (IsMapScouted(mapName) && !IsLocationCached(locId))
		{
			// We are trying to load from cache. This means we aren't connected. Wait until we are.
			if (cache)
				return;
			
			forceSendArray.AddItem(locId);
		}
		
		bitName = class'Hat_SaveBitHelper'.static.GetBitId(npc, 0);
		if (class'Hat_SaveBitHelper'.static.HasLevelBit(bitName, 1))
			continue;
		
		BulliedNPCArray.AddItem(npc);
		locationArray.AddItem(locId);
	}
	
	shopInvClasses = class'Hat_ClassHelper'.static.GetAllScriptClasses("Archipelago_ShopInventory_Base");
	foreach shopInvClasses(shopInvClass)
	{
		shopInv = new class<Archipelago_ShopInventory_Base>(shopInvClass);
		
		if (shopInv.ItemsForSale.Length <= 0)
			continue;
		
		if (InStr(shopInv.ShopNPCName, "Hat_NPC_NyakuzaShop") != -1 && !SlotData.DLC2
			|| InStr(shopInv.ShopNPCName, "Hat_MetroTicketBooth") != -1 && !SlotData.DLC2)
			continue;
		
		if (InStr(shopInv.ShopNPCName, "Hat_NPC_NyakuzaShop", false, true) != -1
			|| shopInv.ShopNPC == class'Hat_NPC_BadgeSalesman')
		{
			maxItems = shopInv.ShopNPC == class'Hat_NPC_BadgeSalesman' ? SlotData.BadgeSellerItemCount : GetAPBits(shopInv.ShopNPCName, 0);	
		}
		else
		{
			maxItems = 1;
		}
		
		if (maxItems <= 0)
			continue;
		
		for (i = 0; i < maxItems; i++)
		{
			if (!GetShopItemClassFromLocation(
				class<Archipelago_ShopItem_Base>(shopInv.ItemsForSale[i].CollectibleClass).default.LocationID, shopItem))
				continue;
			
			if (IsShopItemCached(shopItem))
			{
				ShopItemsPending.AddItem(shopItem);
				continue;
			}
			
			shopLocationArray.AddItem(shopItem.default.LocationID);
		}
	}
	
	if (cache)
		shopLocationArray.Length = 0;
	
	if (locationArray.Length > 0 || shopLocationArray.Length > 0 || forceSendArray.Length > 0)
	{
		if (!IsMapScouted(mapName))
		{
			for (i = 0; i < shopLocationArray.Length; i++)
				locationArray.AddItem(shopLocationArray[i]);
			
			if (locationArray.Length > 0)
				SendMultipleLocationChecks(locationArray, true);
		}
		else
		{
			// Load from cache
			for (i = 0; i < locationArray.Length; i++)
			{
				if (IsLocationChecked(locationArray[i]))
					continue;
				
				locInfo = GetLocationInfoFromID(locationArray[i]);
				if (locInfo.ContainerClass != None || locInfo.IsStatic
				|| locInfo.Position.x == 0 && locInfo.Position.y == 0 && locInfo.position.z == 0)
					continue;
				
				CreateItemFromInfo(GetLocationInfoFromID(locationArray[i]));
			}
			
			foreach DynamicActors(class'Hat_Collectible_Important', collectible)
			{
				if (collectible.IsA('Hat_Collectible_VaultCode_Base') || collectible.IsA('Hat_Collectible_Sticker')
				 	|| collectible.IsA('Hat_Collectible_MetroTicket_Base') || collectible.IsA('Hat_Collectible_InstantCamera'))
					continue;
				
				if (forceSendArray.Find(ObjectToLocationId(collectible)) != -1)
					continue;
				
				collectible.Destroy();
			}
		}
		
		if (forceSendArray.Length > 0)
		{
			SendMultipleLocationChecks(forceSendArray, true);
		}
	}
	
	CollectiblesShuffled = true;
}

function ShuffleCollectibles2()
{
	ShuffleCollectibles(true);
}

function LocationInfo GetLocationInfoFromID(int id)
{
	local int i;
	local LocationInfo locInfo;
	for (i = 0; i < SlotData.LocationInfoArray.Length; i++)
	{
		if (SlotData.LocationInfoArray[i].ID == id)
			return SlotData.LocationInfoArray[i];
	}
	
	return locInfo;
}

function bool IsShopItemCached(class<Archipelago_ShopItem_Base> shopClass)
{
	local int i;
	
	if (SlotData == None || !SlotData.Initialized)
		return false;
	
	for (i = 0; i < SlotData.ShopItemList.Length; i++)
	{
		if (SlotData.ShopItemList[i].ItemClass == shopClass)
			return true;
	}
	
	return false;
}

function SetShopInfoAsHinted(ShopItemInfo shopInfo)
{
	local int i;
	for (i = 0; i < SlotData.ShopItemList.Length; i++)
	{
		if (SlotData.ShopItemList[i].ItemClass == shopInfo.ItemClass)
		{
			SlotData.ShopItemList[i].Hinted = true;
			break;
		}
	}
}

function bool IsLocationCached(int id)
{
	local int i;
	
	if (SlotData == None || !SlotData.Initialized)
		return false;
	
	for (i = 0; i < SlotData.LocationInfoArray.Length; i++)
	{
		if (SlotData.LocationInfoArray[i].ID == id)
			return true;
	}
	
	return false;
}

function bool IsLocationIDPage(int id)
{
	return SlotData.PageLocationIDs.Find(id) != -1;
}

function bool IsMapScouted(string map)
{
	return HasAPBit("MapScouted_"$Locs(map), 1);
}

function Archipelago_RandomizedItem_Base CreateItem(int locId, int itemId, int flags, int player, 
	optional Hat_Collectible_Important collectible, optional Vector pos)
{
	local string mapName;
	local class<Actor> worldClass;
	local Archipelago_RandomizedItem_Base item;
	local int i;
	local bool found;
	local LocationInfo locInfo;
	
	if (!class'Archipelago_ItemInfo'.static.GetNativeItemData(itemId, worldClass)) // not a regular item
		worldClass = class'Archipelago_RandomizedItem_Misc';
	
	item = Archipelago_RandomizedItem_Base(Spawn(worldClass, , , collectible != None ? collectible.Location : pos, , , true));
	item.LocationId = locId;
	item.ItemId = itemId;
	item.ItemFlags = flags;
	item.ItemOwner = player;
	
	if (collectible != None)
	{
		if (locId == CameraBadgeCheck1 || locId == CameraBadgeCheck2)
		{
			item.OriginalCollectibleName = locId == CameraBadgeCheck1 ? "AP_Camera1Check" : "AP_Camera2Check";
		}
		else
		{
			item.OriginalCollectibleName = class'Hat_SaveBitHelper'.static.GetCorrectedMapFilename(string(collectible.GetLevelName()))$"."$collectible.Name;
		}
	}
	
	if (!item.Init())
		return None;
	
	mapName = class'Hat_SaveBitHelper'.static.GetCorrectedMapFilename();
	
	// can we cache this item?
	for (i = 0; i < SlotData.LocationInfoArray.Length; i++)
	{
		if (locId == SlotData.LocationInfoArray[i].ID && mapName ~= SlotData.LocationInfoArray[i].MapName)
		{
			found = true;
			break;
		}
	}
	
	if (!found)
	{
		DebugMessage("Caching location: "$locId);
		locInfo.ID = locId;
		locInfo.ItemID = itemId;
		locInfo.Player = player;
		locInfo.Flags = flags;
		locInfo.MapName = mapName;
		locInfo.ItemClass = item.class;
		locInfo.Position = item.Location;
		SlotData.LocationInfoArray.AddItem(locInfo);
	}
	
	return item;
}

function Archipelago_RandomizedItem_Base CreateItemFromInfo(LocationInfo locInfo)
{
	local Archipelago_RandomizedItem_Base item;
	
	item = Archipelago_RandomizedItem_Base(Spawn(locInfo.ItemClass, , , locInfo.Position, , , true));
	item.LocationId = locInfo.ID;
	item.ItemId = locInfo.ItemID;
	item.ItemFlags = locInfo.Flags;
	item.ItemOwner = locInfo.Player;
	
	if (!item.Init())
		return None;
	
	return item;
}

function bool IsLocationChecked(int id)
{
	return SlotData.CheckedLocations.Find(id) != -1;
}

function bool GetShopItemClassFromLocation(int locationId, out class<Archipelago_ShopItem_Base> outClass)
{
	local array<class<Object > > shopItemClasses;
	local class<Object> shopItem;
	
	shopItemClasses = class'Hat_ClassHelper'.static.GetAllScriptClasses("Archipelago_ShopItem_Base");
	
	foreach shopItemClasses(shopItem)
	{
		if (class<Archipelago_ShopItem_Base>(shopItem).default.LocationID <= 0)
			continue;
		
		if (class<Archipelago_ShopItem_Base>(shopItem).default.LocationID == locationId)
		{
			outClass = class<Archipelago_ShopItem_Base>(shopItem);
			return true;
		}
	}
	
	return false;
}

// way less expensive, but needs the class array upfront
function bool GetShopItemClassFromLocation_Cheap(array<class< Object > > shopItemClasses, int locationId, out class<Archipelago_ShopItem_Base> outClass)
{
	local class<Object> shopItem;
	foreach shopItemClasses(shopItem)
	{
		if (class<Archipelago_ShopItem_Base>(shopItem).default.LocationID <= 0)
			continue;
		
		if (class<Archipelago_ShopItem_Base>(shopItem).default.LocationID == locationId)
		{
			outClass = class<Archipelago_ShopItem_Base>(shopItem);
			return true;
		}
	}
	
	return false;
}

function ShopItemInfo CreateShopItemInfo(class<Archipelago_ShopItem_Base> itemClass, int ItemID, int flags, int player)
{
	local ShopItemInfo shopInfo;
	
	shopInfo.ID = itemClass.default.LocationID;
	shopInfo.ItemClass = itemClass;
	shopInfo.ItemID = itemId;
	shopInfo.ItemFlags = flags;
	shopInfo.Player = player;

	if (class<Archipelago_ShopItem_Metro>(itemClass) != None)
	{
		shopInfo.PonCost = SlotData.MetroMinPonCost + 
			class'Hat_Math'.static.SeededRandWithSeed(SlotData.MetroMaxPonCost-SlotData.MetroMinPonCost+1, SlotData.Seed+SlotData.ShopItemRandStep);
	}
	else
	{
		shopInfo.PonCost = SlotData.MinPonCost + 
			class'Hat_Math'.static.SeededRandWithSeed(SlotData.MaxPonCost-SlotData.MinPonCost+1, SlotData.Seed+SlotData.ShopItemRandStep);
	}
	
	SlotData.ShopItemRandStep++;
	SlotData.ShopItemList.AddItem(shopInfo);
	InitShopItemDisplayName(itemClass);
	
	return shopInfo;
}

function Archipelago_ShopInventory_Base GetShopInventoryFromShopItem(class<Archipelago_ShopItem_Base> itemClass)
{
	local int i, j;
	local array<class<Object > > invClasses;
	local Archipelago_ShopInventory_Base shopInv;
	
	invClasses = class'Hat_ClassHelper'.static.GetAllScriptClasses("Archipelago_ShopInventory_Base");
	for (i = 0; i < invClasses.Length; i++)
	{
		shopInv = new class<Archipelago_ShopInventory_Base>(invClasses[i]);

		for (j = 0; j < shopInv.ItemsForSale.Length; j++)
		{
			if (shopInv.ItemsForSale[j].CollectibleClass == itemClass)
				return shopInv;
		}
	}
	
	return None;
}

function class<Hat_NPC> GetShopItemMerchantClass(class<Archipelago_ShopItem_Base> itemClass)
{
	return GetShopInventoryFromShopItem(itemClass).ShopNPC;
}

function string GetShopItemMerchantName(class<Archipelago_ShopItem_Base> itemClass)
{
	return GetShopInventoryFromShopItem(itemClass).ShopNPCName;
}

function InitShopItemDisplayName(class<Archipelago_ShopItem_Base> itemClass)
{
	local ShopItemInfo shopInfo;
	local string displayName;
	local class<Actor> worldClass;
	
	if (GameData.Length <= 0)
		return;
	
	if (!GetShopItemInfo(itemClass, shopInfo))
		return;
	
	if (class'Archipelago_ItemInfo'.static.GetNativeItemData(shopInfo.ItemID, worldClass))
	{
		itemClass.static.SetHUDIcon(class<Archipelago_RandomizedItem_Base>(worldClass).default.HUDIcon);
	}
	else
	{
		itemClass.static.SetHUDIcon(class'Archipelago_ShopItem_Base'.default.HUDIcon);
	}
	
	displayName = ItemIDToName(shopInfo.ItemID) $" ("$PlayerIdToName(shopInfo.Player)$")";
	itemClass.static.SetDisplayName(displayName);
}

function int GetShopItemID(class<Archipelago_ShopItem_Base> itemClass)
{
	local int i;
	for (i = 0; i < SlotData.ShopItemList.Length; i++)
	{
		if (SlotData.ShopItemList[i].ItemClass == itemClass)
			return SlotData.ShopItemList[i].ItemID;
	}
	
	return 0;
}

function bool GetShopItemInfo(class<Archipelago_ShopItem_Base> itemClass, optional out ShopItemInfo shopInfo)
{
	local int i;
	for (i = 0; i < SlotData.ShopItemList.Length; i++)
	{
		if (SlotData.ShopItemList[i].ItemClass == itemClass)
		{
			shopInfo = SlotData.ShopItemList[i];
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
		return;
	
	for (i = 0; i < ChestArray.Length; i++)
	{
		if (!ChestArray[i].FullOpened)
			continue;
			
		if (bool(DebugMode))
		{
			message = "";
			message = class'Hat_SaveBitHelper'.static.GetCorrectedMapFilename(string(ChestArray[i].GetLevelName()));
			message $= "."$ChestArray[i].Name;
			message $= "("$ObjectToLocationId(ChestArray[i])$")";
			DebugMessage(message);
		}
		
		locationArray.AddItem(ObjectToLocationId(ChestArray[i]));
		ChestArray.RemoveItem(ChestArray[i]);
	}
	
	for (i = 0; i < BulliedNPCArray.Length; i++)
	{
		bitName = class'Hat_SaveBitHelper'.static.GetBitId(BulliedNPCArray[i], 0);
		if (!class'Hat_SaveBitHelper'.static.HasLevelBit(bitName, 1))
			continue;
			
		if (bool(DebugMode))
		{
			message = "";
			message = class'Hat_SaveBitHelper'.static.GetCorrectedMapFilename(string(BulliedNPCArray[i].GetLevelName()));
			message $= "."$BulliedNPCArray[i].Name;
			message $= "("$ObjectToLocationId(BulliedNPCArray[i])$")";
			DebugMessage(message);
		}
		
		locationArray.AddItem(ObjectToLocationId(BulliedNPCArray[i]));
		BulliedNPCArray.RemoveItem(BulliedNPCArray[i]);
	}
	
	if (locationArray.Length > 0)
	{
		SendMultipleLocationChecks(locationArray);
	}
}

function bool IsLocationIDContainer(int id, optional out Actor container)
{
	local Actor a;
	
	foreach DynamicActors(class'Actor', a)
	{
		if (id == SubconBushCheck1 || id == SubconBushCheck2)
		{
			if (a.IsA('Hat_InteractiveFoliage_HarborBush'))
			{
				if (id == SubconBushCheck1 && a.Name == 'Hat_InteractiveFoliage_HarborBush_2'
				|| id == SubconBushCheck2 && a.Name == 'Hat_InteractiveFoliage_HarborBush_3')
				{
					container = a;
					return true;
				}
			}
		}
		else if (a.IsA('Hat_TreasureChest_Base') || a.IsA('Hat_Goodie_Vault_Base') || a.IsA('Hat_NPC_Bullied')
		|| a.IsA('Hat_ImpactInteract_Breakable_ChemicalBadge'))
		{
			if (ObjectToLocationId(a) == id)
			{
				DebugMessage("Found container: "$a.Name $", ID: "$id);
				container = a;
				return true;
			}
		}
	}
	
	return false;
}

// for breakable objects that contain important items
function OnPreBreakableBreak(Actor Breakable, Pawn Breaker)
{
	local Hat_ImpactInteract_Breakable_ChemicalBadge b;
	local class<Actor> spawnClass;
	local Archipelago_RandomizedItem_Base item;
	local int i;
	local bool hasImportantItem;
	local string message;
	local Rotator rot;
	local Vector vel;
	local float rangeMin, rangeMax;
	local LocationInfo locInfo;
	
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
			b.RememberDestroyed = false;
			hasImportantItem = true;
		}
		
		if (hasImportantItem)
		{
			if (bool(DebugMode))
			{
				message = class'Hat_SaveBitHelper'.static.GetCorrectedMapFilename(string(b.GetLevelName()));
				message $= "."$b.Name;
				message $= "("$ObjectToLocationId(b)$")";
				DebugMessage(message);
			}
			
			if (IsLocationChecked(ObjectToLocationId(b)))
				return;
			
			locInfo = GetLocationInfoFromID(ObjectToLocationId(b));
			spawnClass = locInfo.ItemClass;
			item = Archipelago_RandomizedItem_Base(Spawn(spawnClass,,,b.Location + vect(0,0,50),,,true));
			item.LocationId = locInfo.ID;
			item.ItemFlags = locInfo.Flags;
			item.ItemOwner = locInfo.Player;
			item.Init();
			
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
	
	// commit myurder
	message = "[{\"cmd\":\"Bounce\",\"tags\":[\"DeathLink\"],\"data\":{\"time\":" $float(TimeStamp()) $",\"source\":" $"\"" $SlotData.SlotName $"\"" $"}}]";
	client.SendBinaryMessage(message);
}

function OnLoadoutChanged(PlayerController controller, Object loadout, Object backpackItem)
{
	local Hat_BackpackItem item;
	
	if (!IsArchipelagoEnabled() || SlotData.DeathWishOnly)
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
		SetAPBits("UmbrellaCheck", 1);
	}
}

function UpdateZiplineUnlocks()
{
	local Hat_SandTravelNode node;
	
	if (`GameManager.GetChapterInfo().ChapterID != 4)
		return;
	
	foreach DynamicActors(class'Hat_SandTravelNode', node)
	{
		if (node.Name == 'Hat_SandTravelNode_15' || node.Name == 'Hat_SandTravelNode_17'
			|| node.Name == 'Hat_SandTravelNode_43' || node.Name == 'Hat_SandTravelNode_44')
		{
			if (node.HookPoint == None || node.BlockedInFinale && class'Hat_SeqCond_IsAlpineFinale'.static.IsAlpineFinale())
				continue;
			
			if (node.ActivatorHorn == None || !node.ActivatorHorn.IsActivated)
				continue;
			
			if (!HasAPBit("ZiplineUnlock_"$string(node.Name), 1))
			{
				node.HookPoint.Enabled = false;
				node.BlockedMesh.SetHidden(false);
				node.BlockedParticle.SetHidden(false);
				node.BlockedParticle.SetActive(true);
			}
			else
			{
				node.HookPoint.Enabled = true;
				node.BlockedMesh.SetHidden(true);
				node.BlockedParticle.SetHidden(true);
				node.BlockedParticle.SetActive(false);
			}
			
			node.SetTickIsDisabled(false);
		}
	}
}

function OnCollectibleSpawned(Object collectible)
{
	local Archipelago_RandomizedItem_Base item;
	local class<Actor> spawnClass;
	local Vector vel;
	local Rotator rot;
	local float range;
	local LocationInfo locInfo;
	
	if (!IsArchipelagoEnabled() || collectible.IsA('Archipelago_RandomizedItem_Base') || collectible.IsA('Archipelago_ShopItem_Base'))
		return;
	
	if (SlotData.DeathWishOnly)
		return;

	if (IsInSpaceship())
	{
		if (collectible.IsA('Hat_Collectible_BadgePart_Sprint'))
		{
			// Rumbi yarn
			Actor(collectible).Destroy();

			if (!HasAPBit("RumbiYarn", 1))
			{
				SendLocationCheck(RumbiYarnCheck);
				SetAPBits("RumbiYarn", 1);
			}
		}
	}
	else if (Hat_Collectible_Important(collectible) != None && Actor(collectible).CreationTime > 0)
	{
		if (Actor(collectible).Owner != None)
		{
			DebugMessage(collectible.Name $" - Owner Name: " $Actor(collectible).Owner.Name);
			
			if (Actor(collectible).Owner.IsA('Hat_Goodie_Vault_Base'))
			{
				if (IsLocationChecked(ObjectToLocationId(Actor(collectible).Owner)))
				{
					Actor(collectible).Destroy();
					return;
				}
				
				locInfo = GetLocationInfoFromID(ObjectToLocationId(Actor(collectible).Owner));
				
				// failsafe
				if (locInfo.ID <= 0)
				{
					SendLocationCheck(ObjectToLocationId(Actor(collectible).Owner));
					Actor(collectible).Destroy();
					return;
				}
				
				spawnClass = locInfo.ItemClass;
				item = Archipelago_RandomizedItem_Base(Spawn(spawnClass,,,Actor(collectible).Location, Actor(collectible).Rotation,,true));
				item.LocationId = locInfo.ID;
				item.ItemFlags = locInfo.Flags;
				item.ItemOwner = locInfo.Player;
				item.Init();
				
				rot = item.Rotation;
				range = 65536/8;
				rot.Yaw += RandRange(range*-1,range);
				rot.Pitch += RandRange(range*-1,range);
				vel = Vector(rot)*RandRange(150,300) + vect(0,0,1)*RandRange(200,500);
				item.Bounce(vel);
				Actor(collectible).Destroy();
			}
		}
		
		if (`GameManager.GetCurrentMapFilename() ~= "subconforest")
		{
			DebugMessage("Checking for Subcon bush location");
			
			// Subcon bushes
			if (collectible.IsA('Hat_Collectible_BadgePart_FoxMask'))
			{
				SendLocationCheck(SubconBushCheck1);
				Actor(collectible).Destroy();
			}
			else if (collectible.IsA('Hat_Collectible_BadgePart_SuckInOrbs'))
			{
				SendLocationCheck(SubconBushCheck2);
				Actor(collectible).Destroy();
			}
		}
		else if (collectible.IsA('Hat_Collectible_HatPart'))
		{
			Actor(collectible).Destroy();
		}
	}
}

function OnCollectedCollectible(Object collectible)
{
	local string message;
	local Archipelago_RandomizedItem_Base item;
	
	if (bool(DebugMode) && collectible.IsA('Hat_Collectible_Important'))
	{
		// Show location ID
		message = class'Hat_SaveBitHelper'.static.GetCorrectedMapFilename(string(Actor(collectible).GetLevelName()));
		message $= "."$collectible.Name;
		message $= "("$ObjectToLocationId(collectible)$")";
		DebugMessage(message);
	}
	
	if (!IsArchipelagoEnabled() || SlotData.DeathWishOnly)
		return;
	
	// If this is an Archipelago item or a storybook page, send it
	// CreationTime > 0 means it was from a chest, in which case we would send the chest instead
	if (SlotData.ShuffleStorybookPages && collectible.IsA('Hat_Collectible_StoryBookPage')
		&& Actor(collectible).CreationTime <= 0 && !class'Hat_SnatcherContract_DeathWish'.static.IsAnyActive(false))
	{
		SendLocationCheck(ObjectToLocationId(collectible));
		SetAPBits(class'Hat_SaveBitHelper'.static.GetBitID(collectible), 1);
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
	
	if (!SlotData.Initialized || SlotData.DeathWishOnly || SlotData.HatItems)
		return;
	
	foreach DynamicActors(class'Hat_PlayerController', pc)
	{
		loadout = pc.MyLoadout;
		break;
	}
	
	abilityClass = GetNextHat();
	cost = GetHatYarnCost(abilityClass);
	index = GetAPBits("HatCraftIndex", 1);
	
	if (abilityClass != None && index <= 5)
	{
		if (amount > 0)
		{
			ScreenMessage("Yarn: "$count $"/"$cost, 'Warning');
		}
		
		// Stitch our new hat!
		if (count >= cost)
		{
			item = class'Hat_Loadout'.static.MakeLoadoutItem(abilityClass);
			loadout.AddBackpack(item);
			PlayHatStitchAnimation(pc, item);
			ScreenMessage("Got " $GetHatName(abilityClass), 'Warning');
			
			`GameManager.AddBadgePoints(-cost);
			SetAPBits("TotalYarnCollected", 0);
			SetAPBits("HatCraftIndex", index+1);
			
			`SaveManager.GetCurrentSaveData().MyBackpack2017.Hats.Sort(SortHats);
		}
	}
	else if (amount > 0)
	{
		pons = 25 * amount;
		`GameManager.AddEnergyBits(pons);
		ScreenMessage("Got " $pons $" Pons", 'Warning');
	}
}

function class<Hat_Ability> GetNextHat()
{
	return GetHatByIndex(GetAPBits("HatCraftIndex", 1));
}

function class<Hat_Ability> GetHatByIndex(int index)
{
	local EHatType type;
	switch (index)
	{
		case 1:
			type = SlotData.Hat1;
			break;
		
		case 2:
			type = SlotData.Hat2;
			break;
		
		case 3:
			type = SlotData.Hat3;
			break;

		case 4:
			type = SlotData.Hat4;
			break;

		case 5:
			type = SlotData.Hat5;
			break;
	}
	
	switch (type)
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

function SendLocationCheck(int id, optional bool scout, optional bool hint)
{
	local string jsonMessage;
	
	if (!IsFullyConnected())
	{
		if (scout)
		{
			DebugMessage("[WARNING] Tried to scout a location while not connected!", , true);
			return;
		}
		
		ItemResender.AddLocation(id);
		SaveGame();
		return;
	}
	
	if (!scout)
	{
		jsonMessage = "[{\"cmd\":\"LocationChecks\",\"locations\":[" $id $"]}]";
		DebugMessage("Sending location ID: " $id);
		SlotData.CheckedLocations.AddItem(id);
		PartySyncLocations_Single(id, , true);
		SaveGame();
	}
	else
	{
		if (hint)
		{
			jsonMessage = "[{\"cmd\":\"LocationScouts\",\"locations\":[" $id $"],\"create_as_hint\":2}]";
		}
		else
		{
			jsonMessage = "[{\"cmd\":\"LocationScouts\",\"locations\":[" $id $"]}]";
		}
	}
	
	Client.SendBinaryMessage(jsonMessage);
}

function SendMultipleLocationChecks(array<int> locationArray, optional bool scout, optional bool hint)
{
	local string jsonMessage;
	local int i;
	
	if (!IsFullyConnected())
	{
		if (scout || hint)
		{
			DebugMessage("[WARNING] Tried to scout locations while not connected!", , true);
			return;
		}
		
		ItemResender.AddMultipleLocations(locationArray);
		SaveGame();
		return;
	}
	
	if (!scout)
	{
		jsonMessage = "[{\"cmd\":\"LocationChecks\",\"locations\":[";
		for (i = 0; i < locationArray.Length; i++)
		{
			jsonMessage $= locationArray[i];
			DebugMessage("Sending location ID: " $locationArray[i]);
			SlotData.CheckedLocations.AddItem(locationArray[i]);
			
			if (i+1 < locationArray.Length)
				jsonMessage $= ",";
		}
		
		PartySyncLocations(locationArray, , true);
		SaveGame();
	}
	else
	{
		jsonMessage = "[{\"cmd\":\"LocationScouts\",\"locations\":[";
		for (i = 0; i < locationArray.Length; i++)
		{
			jsonMessage $= locationArray[i];
			if (i+1 < locationArray.Length)
			{
				jsonMessage $= ",";
			}
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

function WaitForContractEvent()
{
	local Actor event;

	// Stupid, but sending in the event actor as a timer parameter and checking if it's None/has bDeleteMe doesn't work
	foreach DynamicActors(class'Actor', event)
	{
		if (event.IsA('Hat_SnatcherContractEvent'))
			return;
	}
	
	ClearTimer(NameOf(WaitForContractEvent));
	OnContractEventEnd();
}

function OnContractEventEnd()
{
	local int i;
	local Hat_SaveGame save;
	local Hat_PlayerController ctr;
	
	ContractEventActive = false;
	
	foreach DynamicActors(class'Hat_PlayerController', ctr)
	{
		ctr.bGodMode = false;
	}

	if (SlotData.TakenContracts.Length == 0)
		return;
	
	save = `SaveManager.GetCurrentSaveData();
	for (i = 0; i < SlotData.TakenContracts.Length; i++)
	{
		if (save.SnatcherContracts.Find(SlotData.TakenContracts[i]) == -1)
			save.SnatcherContracts.AddItem(SlotData.TakenContracts[i]);

		if (SlotData.TakenContracts[i].static.IsContractComplete() && save.CompletedSnatcherContracts.Find(SlotData.TakenContracts[i]) == -1)
		{
			save.CompletedSnatcherContracts.AddItem(SlotData.TakenContracts[i]);
		}
		
		DebugMessage("Restored player's contract: " $SlotData.TakenContracts[i]);
	}
	
	SlotData.TakenContracts.Length = 0;
	SaveGame();
}

function CheckContractsForDeletion()
{
	local int i, count;
	if (IsIceBrokenEvent())
		return;
	
	for (i = 0; i < SelectContracts.Length; i++)
	{
		DebugMessage("Contract Class: " $SelectContracts[i].ContractClass);
		if (SelectContracts[i].ContractClass == None ||
			SelectContracts[i].ContractClass == class'Hat_SnatcherContract_IceWall')
			continue;
		
		if (SlotData.CheckedContracts.Find(SelectContracts[i].ContractClass) != -1)
		{
			count++;
			if (count >= SelectContracts.Length) // leave at least one to prevent any edge cases where the player gets softlocked
				break;
			
			SelectContracts[i].Destroy();
		}
	}
	
	SelectContracts.Length = 0;
}

function bool IsIceBrokenEvent()
{
	local Actor a;
	foreach DynamicActors(class'Actor', a)
	{
		if (a.IsA('Hat_SnatcherContractEvent_IceBroken'))
			return true;
	}
	
	return false;
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
	
		if (RandRange(1, 250) == 2)
		{
			stackClass = class'Archipelago_Stackable_Conductor';
		}
		else
		{
			stackClass = class'Archipelago_Stackable_ConductorBaby';
		}
		
		stack = Spawn(stackClass, , , player.Location);
		if (!player.BeginCarry(stack, true))
		{
			stack.Destroy();
			return; // There is no escape from your fate as a babysitter!
		}
	}
	
	BabyCount--;
	if (BabyCount <= 0)
	{
		ClearTimer(NameOf(BabyTrapTimer));
		SetTimer(60.0, false, NameOf(OnBabyTrapEnd));
	}
}

function OnPlayerEnterCannon(Pawn Player, Actor Cannon)
{
	DropAllBabies(Player);
}

function OnBabyTrapEnd()
{
	local Hat_Player player;
	foreach DynamicActors(class'Hat_Player', player)
	{
		DropAllBabies(player);
	}
}

function DropAllBabies(Pawn Player)
{
	local Archipelago_Stackable_Base stack;
	foreach DynamicActors(class'Archipelago_Stackable_Base', stack)
	{
		if (stack.Carrier != Player)
			continue;
		
		stack.ForceDrop();
		stack.Destroy();
	}
	
	Hat_PawnCarryable(Player).SetAnimCarryMode(ECarryMode_None);
	Hat_HUD(PlayerController(player.Controller).MyHUD).CloseHUD(class'Hat_HUDElementCarryHelp');
}

function LaserTrapTimer()
{
	local Hat_Player player;
	
	if (WorldInfo.Pauser != None)
		return;
	
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

function ItemSoundTimer()
{
	ItemSoundCooldown = false;
}

function SpawnDecorationStands()
{
	local Actor stand;
	if (class'Hat_SeqCond_IsMuMission'.static.IsFinaleMuMission() || class'Hat_SaveBitHelper'.static.HasActBit("thefinale_ending", 1))
		return;
	
	foreach DynamicActors(class'Actor', stand)
	{
		if (stand.IsA('Hat_DecorationStand') && stand.bHidden)
		{
			stand.SetHidden(false);
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

function ReplaceUnarmedWeapon()
{
	local Hat_SaveGame save;
	local int i;
	local Hat_BackpackItem item;
	local Hat_PlayerController ctr;
	
	ctr = Hat_PlayerController(GetALocalPlayerController());
	if (ctr.MyLoadout.BackpackHasInventory(class'Archipelago_Weapon_Umbrella', true)
	|| ctr.MyLoadout.BackpackHasInventory(class'Archipelago_Weapon_BaseballBat', true))
		return;
	
	save = `SaveManager.GetCurrentSaveData();
	
	for (i = 0; i < save.MyBackpack2017.Weapons.Length; i++)
	{
		item = save.MyBackpack2017.Weapons[i];
		if (item != None)
		{
			if (class<Hat_Weapon_Umbrella>(item.BackpackClass) != None 
			&& class<Archipelago_Weapon_Umbrella>(item.BackpackClass) == None)
			{
				ctr.MyLoadout.RemoveBackpack(item);
			}
			
			if (SlotData.UmbrellaLogic && class<Hat_Weapon_Unarmed>(item.BackpackClass) != None)
			{
				ctr.MyLoadout.RemoveBackpack(item);
				item.BackpackClass = class'Archipelago_Weapon_Unarmed';
				ctr.MyLoadout.AddBackpack(item, true, true, Hat_Player(ctr.Pawn));
			}
		}
	}
}

function DeleteCameraParticle()
{
	local Emitter e;
	foreach AllActors(class'Emitter', e)
	{
		if (e.Name == 'Emitter_265' || e.Name == 'Emitter_267')
		{
			e.ParticleSystemComponent.KillParticlesForced();
			e.ShutDown();
		}
	}
}

// For recording location IDs
function PrintItemsNearPlayer()
{
	local Hat_Player player;
	local Hat_Collectible_Important collectible;
	local Hat_Collectible_StoryBookPage page;
	
	if (!bool(DebugMode))
		return;

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
	
	foreach DynamicActors(class'Hat_Collectible_StoryBookPage', page)
	{
		if (GetVectorDistance(player.Location, page.Location) <= 1000.0)
		{
			ScreenMessage("[PrintItemsNearPlayer] Found collectible: " $page.Name $"("$ObjectToLocationId(page)$")");
		}
	}
}

function BeatGame()
{
	local JsonObject json;
	
	SetAPBits("HasBeatenGame", 1);
	if (!IsFullyConnected())
		return;
	
	json = new class'JsonObject';
	json.SetStringValue("cmd", "StatusUpdate");
	json.SetIntValue("status", 30);
	client.SendBinaryMessage(EncodeJson2(json));
	json = None;
}

function bool IsDLC1Installed(optional bool AndEnabled)
{
	return class'Hat_GameDLCInfo'.static.IsGameDLCInfoInstalled(class'Hat_GameDLCInfo_DLC1') && (!AndEnabled || SlotData.DLC1);
}

function bool IsDLC2Installed(optional bool AndEnabled)
{
	return class'Hat_GameDLCInfo'.static.IsGameDLCInfoInstalled(class'Hat_GameDLCInfo_DLC2') && (!AndEnabled || SlotData.DLC2);
}

function bool IsOnlineParty()
{
	return class'Hat_GhostPartyPlayerStateBase'.static.ConfigGetUseOnlineFunctionality();
}

function PartySyncLocations(array<int> locIds, optional Hat_GhostPartyPlayerStateBase Receiver, optional bool IsLive)
{
	local JsonObject locSync;
	local int i;
	
	if (!IsOnlineParty())
		return;

	locSync = new class'JsonObject';
	for (i = 0; i < locIds.Length; i++)
	{
		locSync.SetIntValue(string(i), locIds[i]);
	}
	
	if (IsLive)
	{
		locSync.SetBoolValue("IsLive", true);
	}
	
	SendOnlinePartyCommand(locSync.EncodeJson(locSync), 'APLocationSync', GetALocalPlayerController().Pawn, Receiver);
	locSync = None;
}

function PartySyncActs(array<string> hourglasses, optional Hat_GhostPartyPlayerStateBase Receiver)
{
	local JsonObject actSync;
	local int i;

	if (!IsOnlineParty())
		return;
	
	actSync = new class'JsonObject';
	for (i = 0; i < hourglasses.Length; i++)
	{
		actSync.SetStringValue(string(i), hourglasses[i]);
	}
	
	SendOnlinePartyCommand(actSync.EncodeJson(actSync), 'APActSync', GetALocalPlayerController().Pawn, Receiver);
	actSync = None;
}

function PartySyncLocations_Single(int locId, optional Hat_GhostPartyPlayerStateBase Receiver, optional bool IsLive)
{
	local array<int> dummy;
	dummy.AddItem(locId);
	PartySyncLocations(dummy, Receiver, IsLive);
}

function PartySyncActs_Single(string hourglass, optional Hat_GhostPartyPlayerStateBase Receiver)
{
	local array<string> dummy;
	dummy.AddItem(hourglass);
	PartySyncActs(dummy, Receiver);
}

function bool IsArchipelagoEnabled()
{
	if (IsInTitlescreen() || IsCurrentPatch())
		return false;
	
	return HasAPBit("ArchipelagoEnabled", 1);
}

function bool IsCurrentPatch()
{
	local string version;
	version = class'Engine'.static.GetBuildDate();
	
	// 2021 and later is around the time when TcpLink broke, which means we can't function. We only want 2019 or 2020 builds.
	if (InStr(version, "2019") == -1 && InStr(version, "2020") == -1)
		return true;
	
	return false;
}

function bool IsInTitlescreen()
{
	return `GameManager.GetCurrentMapFilename() ~= `GameManager.TitleScreenMapName || `SaveManager.GetCurrentSaveData() == None;
}

// Archipelago requires JSON messages to be encased in []
function string EncodeJson2(JsonObject json)
{
	local string message;
	message = "["$class'JsonObject'.static.EncodeJson(json)$"]";
	return message;
}

function bool IsFullyConnected()
{
	return (client != None && client.FullyConnected && !client.ConnectingToAP && client.LinkState == STATE_Connected);
}

function bool IsDeathLinkEnabled()
{
	return SlotData.DeathLink && !ContractEventActive;
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
	local Hat_ChapterActInfo shuffled;
	
	if (SlotData != None && SlotData.Initialized)
	{
		if (SlotData.DeathWishOnly)
			return true;
		
		if (SlotData.ActRando)
		{
			// Free roam acts are free!
			if (IsChapterActInfoUnlocked(act))
			{
				shuffled = GetShuffledAct(act);
				
				if (shuffled != None && shuffled.hourglass == "")
				{
					if (!HasAPBit("ActComplete"$act.hourglass, 1))
					{
						SetAPBits("ActComplete_"$act.hourglass, 1);
						PartySyncActs_Single(act.hourglass);
					}
					
					return true;
				}
			}
		}
		else if (act.hourglass == "")
		{
			return true;
		}
	}
	
	return HasAPBit("ActComplete_"$act.hourglass, 1);
}

function bool IsActFreeRoam(Hat_ChapterActInfo act)
{
	return (act.ChapterInfo != None && (act.ChapterInfo.IsActless || act.ChapterInfo.HasFreeRoam)
	&& (act.ActID == 99 || (act.ChapterInfo.ActIDAfterIntro > 0 && act.ActID == act.ChapterInfo.ActIDAfterIntro)) && !act.IsBonus);
}

function Hat_ChapterActInfo GetOriginalAct(Hat_ChapterActInfo act, optional out int basement)
{
	local int i;
	for (i = 0; i < SlotData.ShuffledActList.Length; i++)
	{
		if (SlotData.ShuffledActList[i].NewAct != None && SlotData.ShuffledActList[i].NewAct == act)
		{
			basement = int(SlotData.ShuffledActList[i].IsDeadBirdBasementOriginalAct);
			return SlotData.ShuffledActList[i].OriginalAct;
		}
	}
	
	return None;
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

function ScreenMessage(String message, optional Name type)
{
	local PlayerController pc;
	
	if (bool(VerboseLogging))
	{
		// Don't ask.
		DebugMsg = message;
		ConsoleCommand("getall Archipelago_GameMod DebugMsg");
	}
	
	pc = GetALocalPlayerController();
    if (pc == None)
		return;
    
    pc.ClientMessage(message, type, 8);
}

function DebugMessage(String message, optional Name type, optional bool forceLog)
{
	local PlayerController pc;
	
	if (bool(VerboseLogging) || forceLog)
	{
		DebugMsg = message;
		ConsoleCommand("getall Archipelago_GameMod DebugMsg");
	}
	
	if (!bool(DebugMode))
		return;
	
	pc = GetALocalPlayerController();
    if (pc == None)
		return;
    
    pc.ClientMessage(message, type, 8);
}

function string LocationIDToName(int id)
{
	local int i, a;
	
	for (i = 0; i < GameData.Length; i++)
	{
		for (a = 0; a < GameData[i].LocationMappings.Length; a++)
		{
			if (GameData[i].LocationMappings[a].ID == id)
				return GameData[i].LocationMappings[a].Location;
		}
	}

	return "Unknown Location";
}

function string ItemIDToName(int id)
{
	local int i, a;

	for (i = 0; i < GameData.Length; i++)
	{
		for (a = 0; a < GameData[i].ItemMappings.Length; a++)
		{
			if (GameData[i].ItemMappings[a].ID == id)
				return GameData[i].ItemMappings[a].Item;
		}
	}
	
	return "Unknown Item";
}

delegate int SortHats(Hat_LoadoutBackpackItem A, Hat_LoadoutBackpackItem B)
{
	return GetHatPriority(class<Hat_Ability>(A.BackpackClass)) > GetHatPriority(class<Hat_Ability>(B.BackpackClass)) ? -1 : 0;
}

function int GetHatPriority(class<Hat_Ability> hat)
{
	switch (hat)
	{
		case class'Hat_Ability_Help':
			return 0;

		case class'Hat_Ability_Sprint':
			return 1;

		case class'Hat_Ability_Chemical':
			return 2;
		
		case class'Hat_Ability_StatueFall':
			return 3;

		case class'Hat_Ability_FoxMask':
			return 4;
		
		case class'Hat_Ability_TimeStop':
			return 5;
	}
}

function int ObjectToLocationId(Object obj)
{
	local int i, id;
	local string fullName;
	
	if (obj == None)
	{
		DebugMessage("[ObjectToLocationId] obj is None", , true);
		ScriptTrace();
	}
	
	fullName = class'Hat_SaveBitHelper'.static.GetCorrectedMapFilename(string(Actor(obj).GetLevelName()))$"."$obj.Name;
	
	// Convert the object's name to an ID, using the Unicode values of the characters
	for (i = 0; i < Len(fullName); i++)
	{
		id += Asc(Mid(fullName, i, 1));
	}
	
	if (obj.IsA('Hat_Collectible_StoryBookPage'))
	{
		id += StoryBookPageIDRange;
		if (`GameManager.GetChapterInfo().ChapterID == 6)
		{
			id += 1000;
		}
	}
	else
	{
		id += GetChapterIDRange(`GameManager.GetChapterInfo());
	}
	
	return id;
}

function Actor LocationIdToObject(int id, optional class<Actor> TargetClass)
{
	local Actor a;
	foreach DynamicActors(class'Actor', a)
	{
		if (ObjectToLocationId(a) == id && (TargetClass == None || a.Class == TargetClass || ClassIsChildOf(a.class, TargetClass)))
			return a;
	}
	
	return None;
}

function UnlockAlmostEverything()
{
	local Hat_SaveGame save;
	local array<Hat_ChapterInfo> chapterArray;
	local Hat_ChapterInfo chapter;
	local Hat_ChapterActInfo act;
	local Hat_Loadout lo;

	lo = Hat_PlayerController(GetALocalPlayerController()).MyLoadout;
	
	// all Time Pieces
	chapterArray = class'Hat_ChapterInfo'.static.GetAllChapterInfo();
	save = `SaveManager.GetCurrentSaveData();
	
	foreach chapterArray(chapter)
	{
		foreach chapter.ChapterActInfo(act)
		{
			if (act.hourglass == "")
				continue;
			
			if (act.RequiredDLC != None && !class'Hat_GameDLCInfo'.static.IsGameDLCInfoInstalled(act.RequiredDLC))
				continue;
			
			save.GiveTimePiece(act.hourglass, false);
			if (IsPurpleRift(act))
				save.UnlockSecretLevel(act.hourglass);
		}
	}
	
	save.GiveTimePiece("chapter3_secret_finale", false);
	save.GiveTimePiece("Metro_Intro", false);
	
	// all hats
	lo.AddBackpack(class'Hat_Loadout'.static.MakeLoadoutItem(class'Hat_Ability_Sprint'));
	lo.AddBackpack(class'Hat_Loadout'.static.MakeLoadoutItem(class'Hat_Ability_Chemical'));
	lo.AddBackpack(class'Hat_Loadout'.static.MakeLoadoutItem(class'Hat_Ability_StatueFall'));
	lo.AddBackpack(class'Hat_Loadout'.static.MakeLoadoutItem(class'Hat_Ability_FoxMask'));
	lo.AddBackpack(class'Hat_Loadout'.static.MakeLoadoutItem(class'Hat_Ability_TimeStop'));
	
	// umbrella
	if (SlotData.BaseballBat)
		lo.AddBackpack(class'Hat_Loadout'.static.MakeBackpackItem(class'Archipelago_Weapon_BaseballBat'), true);
	else
		lo.AddBackpack(class'Hat_Loadout'.static.MakeBackpackItem(class'Archipelago_Weapon_Umbrella'), true);
	
	// hookshot, camera, one hit hero
	lo.AddBackpack(class'Hat_Loadout'.static.MakeBackpackItem(class'Hat_Ability_Hookshot'), true);
	lo.AddBackpack(class'Hat_Loadout'.static.MakeBackpackItem(class'Hat_Badge_OneHitDeath'));
	lo.AddBackpack(class'Hat_Loadout'.static.MakeBackpackItem(class'Hat_Ability_Camera'));
	
	`GameManager.AddBadgeSlots(2);
	`GameManager.AddEnergyBits(99999);
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
	if (id <= 0)
		return "Archipelago";
	
	if (id >= SlotData.PlayerNames.Length || SlotData.PlayerNames[id] == "")
		return "Unknown Player";
	
	return SlotData.PlayerNames[id];
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

function CleanUpMetro()
{
	local int i;
	local Actor a;
	local array<SequenceObject> seqObjects;
	
	foreach DynamicActors(class'Actor', a)
	{
		// Force open jewelry store door, otherwise player gets trapped inside of it after collecting a Time Piece
		// Force open the barrier near the jewelry store, and remove the crates covering the mud puddle
		if (a.Name == 'InterpActor_10' || a.Name == 'InterpActor_13'
			|| a.Name == 'Hat_DynamicStaticActor_17' || a.Name == 'Hat_DynamicStaticActor_18'
			|| a.Name == 'Hat_DynamicStaticActor_35' || a.Name == 'Hat_DynamicStaticActor_36'
			|| a.Name == 'Hat_DynamicStaticActor_37' || a.Name == 'Hat_DynamicStaticActor_38')
		{
			ConsoleCommand("set " $a.Name $" bnodelete false"); // Fuck you. Die.
			a.Destroy();
		}
		
		// These are the opened jewelery store doors, unhide them
		if (a.Name == 'InterpActor_14' || a.Name == 'InterpActor_17')
		{
			a.SetHidden(false);
		}
		
		// Remove the cat holding the time piece if we already completed the intro
		if (a.IsA('Hat_Goodie_Chaser_Base') && HasAPBit("ActComplete_Metro_Intro", 1))
		{
			a.Destroy();
		}
		
		// Hide the Time Piece as well
		if (a.Name == 'Hat_TimeObject_Metro_2' && HasAPBit("ActComplete_Metro_Intro", 1))
		{
			a.SetHidden(true);
		}
	}
	
	WorldInfo.GetGameSequence().FindSeqObjectsByClass(class'SeqAct_ToggleHidden', true, seqObjects);
	for (i = 0; i < seqObjects.Length; i++)
	{
		// this hides the opened doors in the jewelery store
		if (seqObjects[i].Name == 'SeqAct_ToggleHidden_18')
		{
			SeqAct_ToggleHidden(seqObjects[i]).Targets.Length = 0;
			break;
		}
	}
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
	SpaceshipSpawnLocation = (x=-2011, y=-1808, z=38);
	Camera1Loc = (x=-5367,y=6471,z=-468);
	Camera2Loc = (x=5767,y=6763,z=-496);
	
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
	
	ThugCatShops[0] = "Hat_NPC_NyakuzaShop_0";
	ThugCatShops[1] = "Hat_NPC_NyakuzaShop_1";
	ThugCatShops[2] = "Hat_NPC_NyakuzaShop_2";
	ThugCatShops[3] = "Hat_NPC_NyakuzaShop_5";
	ThugCatShops[4] = "Hat_NPC_NyakuzaShop_13";
	ThugCatShops[5] = "Hat_NPC_NyakuzaShop_12";
	ThugCatShops[6] = "Hat_NPC_NyakuzaShop_14";
	ThugCatShops[7] = "Hat_NPC_NyakuzaShop_4";
	ThugCatShops[8] = "Hat_NPC_NyakuzaShop_6";
	ThugCatShops[9] = "Hat_NPC_NyakuzaShop_7";
}