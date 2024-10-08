class Archipelago_HUDElementItemFinder extends Hat_HUDElementRelicMap
	dependson(Archipelago_ItemInfo);

`include(APRandomizer\Classes\Globals.uci);

var array<int> HookshotRequiredLocs;
var array<int> IceHatRequiredLocs;
var array<int> DwellerMaskRequiredLocs;
var array<int> BrewingHatRequiredLocs;

// For zipline logic
var array<int> BirdhousePathLocs;
var array<int> LavaCakePathLocs;
var array<int> WindmillPathLocs;
var array<int> BellPathLocs;

// Subcon painting logic
var array<int> VillagePaintingLocs;
var array<int> SwampPaintingLocs;
var array<int> CourtyardPaintingLocs;

function OnOpenHUD(HUD H, optional String command)
{
	local Archipelago_GameMod m;
	local int difficulty;
	
	Super.OnOpenHUD(H, command);
	m = `AP;
	difficulty = m.SlotData.LogicDifficulty;
	if (difficulty >= `MODERATE)
	{
		// Subcon Well without Hookshot
		HookshotRequiredLocs.RemoveItem(2000324311);
		
		// Birdhouse without Brewers
		BrewingHatRequiredLocs.RemoveItem(2000335756);
		BrewingHatRequiredLocs.RemoveItem(2000336497);
		BrewingHatRequiredLocs.RemoveItem(2000334758);
		BrewingHatRequiredLocs.RemoveItem(2000335885);
		BrewingHatRequiredLocs.RemoveItem(2000335886);
		BrewingHatRequiredLocs.RemoveItem(2000335492);
		
		// The Birdhouse - Dweller Platforms Relic without Dwellers
		DwellerMaskRequiredLocs.RemoveItem(2000336497);
		
		// Rock the Boat without Ice
		IceHatRequiredLocs.RemoveItem(2000304049);
		
		// Clock Tower + Ruined Tower with nothing
		HookshotRequiredLocs.RemoveItem(2000303481);
		IceHatRequiredLocs.RemoveItem(2000304607);
		
		// Pink Paw Cat Vaccuum + Fan without Hookshot/Dweller
		HookshotRequiredLocs.RemoveItem(2000305110);
		HookshotRequiredLocs.RemoveItem(2000304106);
		DwellerMaskRequiredLocs.RemoveItem(2000305110);
		DwellerMaskRequiredLocs.RemoveItem(2000304106);
	}
	
	if (difficulty >= `HARD)
	{
		// Dweller Floating Rocks
		DwellerMaskRequiredLocs.RemoveItem(2000324464);
		
		// Dweller Platforming Tree B
		DwellerMaskRequiredLocs.RemoveItem(2000324855);
	}
	
	if (difficulty >= `EXPERT)
	{
		// Mafia Town - Above Boats without Hookshot
		HookshotRequiredLocs.RemoveItem(2000305218);
		
		// Mafia Town - Hot Air Balloon without Ice Hat
		IceHatRequiredLocs.RemoveItem(2000304829);
		
		// Mafia Town - Top of Lighthouse without Hookshot
		HookshotRequiredLocs.RemoveItem(2000304213);
		
		// Some Subcon locations without Hookshot
		HookshotRequiredLocs.RemoveItem(2000324766);
		HookshotRequiredLocs.RemoveItem(2000324856);
		
		// Twilight Bell without Dwellers
		DwellerMaskRequiredLocs.RemoveItem(2000334434);
		DwellerMaskRequiredLocs.RemoveItem(2000336478);
		DwellerMaskRequiredLocs.RemoveItem(2000335826);
		
		// Some Subcon locations without Dwellers
		DwellerMaskRequiredLocs.RemoveItem(2000324766);
		
		// Subcon magnet badge bush without Brewing using cherries
		BrewingHatRequiredLocs.RemoveItem(2000325479);
	}
}

function UpdateClosestMarker(HUD H)
{
	local Archipelago_RandomizedItem_Base item;
	local Hat_Collectible_StoryBookPage page;
	local Hat_TreasureChest_Base chest;
	local Hat_Collectible_DeathWishLevelToken dwlt;
	local float closest_distance;
	local int bestindx, i, mode, locId;
	local bool HasAnyDeathWishLevelTokens, onlyImportant, hasBrewing, valid;
	local string mapName;
	local Hat_ImpactInteract_Breakable_ChemicalBadge b;
	local Archipelago_ShopInventory_Base shop;
	local Archipelago_GameMod m;
	local LocationInfo locInfo;
	local Actor a;
	
	m = `AP;
	if (m == None || m.SlotData == None)
		return;
	
	bestindx = INDEX_NONE;
	MarkerPositions.Length = 0;
	MarkerClasses.Length = 0;
	closest_distance = 0;
	
	// Depending on our mode, we either point to the closest item, point to only important items, or point to important items first.
	mode = m.SlotData.CompassBadgeMode;
	onlyImportant = (mode == 2 || mode == 3 && AreImportantItemsLeft(H));
	
	if (m.IsInSpaceship() && !m.IsLocationChecked(m.const.RumbiYarnCheck))
	{
		// Point to Rumbi, most players don't realize that she is a check.
		if (CanHitObjects())
		{
			foreach H.PlayerOwner.DynamicActors(class'Actor', a)
			{
				if (a.IsA('Hat_Vacuum'))
				{
					UpdateClosestMarker_Actor(H, a, closest_distance, bestindx);
					break;
				}
			}
		}
	}
	
	// Iterations
	foreach H.PlayerOwner.DynamicActors(class'Archipelago_RandomizedItem_Base', item)
	{
		if (item.PickupActor != None) continue;
		if (!CanReachLocation(item.LocationId, H)) continue;
		if (onlyImportant && item.ItemFlags == ItemFlag_Garbage) continue;
		
		UpdateClosestMarker_Actor(H, item, closest_distance, bestindx);
	}
	
	foreach H.PlayerOwner.DynamicActors(class'Hat_TreasureChest_Base', chest)
	{
		if (chest.Content == None) continue;
		if (chest.Opened) continue;
		if (m.ChestArray.Find(chest) == -1) continue;
		
		locId = m.ObjectToLocationId(chest);
		if (!CanReachLocation(locId, H) || m.IsLocationChecked(locId)) continue;
		
		locInfo = m.GetLocationInfoFromID(locId);
		
		if (class<Hat_Collectible_StoryBookPage>(chest.Content) == None)
			if (locInfo.ID <= 0 || onlyImportant && locInfo.Flags == ItemFlag_Garbage) continue;
		
		UpdateClosestMarker_Actor(H, chest, closest_distance, bestindx);
	}
	
	foreach H.PlayerOwner.DynamicActors(class'Hat_Collectible_StoryBookPage', page)
	{
		locId = m.ObjectToLocationId(page);
		if (!CanReachLocation(locId, H) || m.IsLocationChecked(locId)) continue;
		
		locInfo = m.GetLocationInfoFromID(locId);
		if (locInfo.ID <= 0 || onlyImportant && locInfo.Flags == ItemFlag_Garbage) continue;
		
		UpdateClosestMarker_Actor(H, page, closest_distance, bestindx);
	}
	
	hasBrewing = class'Hat_Loadout'.static.BackpackHasInventory(class'Hat_Ability_Chemical', true);
	if (hasBrewing)
	{
		foreach H.PlayerOwner.DynamicActors(class'Hat_ImpactInteract_Breakable_ChemicalBadge', b)
		{
			valid = false;
			
			for (i = 0; i < b.Rewards.Length; i++)
			{
				if (class<Archipelago_RandomizedItem_Base>(b.Rewards[i]) != None)	
				{
					valid = true;
					break;
				}
			}
			
			if (valid)
			{
				locId = m.ObjectToLocationId(b);
				if (!CanReachLocation(locId, H) || m.IsLocationChecked(locId)) continue;
				
				locInfo = m.GetLocationInfoFromID(locId);
				if (locInfo.ID <= 0 || onlyImportant && locInfo.Flags == ItemFlag_Garbage) continue;
				
				UpdateClosestMarker_Actor(H, b, closest_distance, bestindx);
			}
		}
	}
	
	mapName = `GameManager.GetCurrentMapFilename();
	
	foreach H.PlayerOwner.DynamicActors(class'Actor', a)
	{
		if (mapName ~= "subconforest" && a.IsA('Hat_InteractiveFoliage_HarborBush'))
		{
			if (a.Name == 'Hat_InteractiveFoliage_HarborBush_2' || a.Name == 'Hat_InteractiveFoliage_HarborBush_3')
			{
				locId = a.Name == 'Hat_InteractiveFoliage_HarborBush_2' ? m.SubconBushCheck1 : m.SubconBushCheck2;
				if (!CanReachLocation(locId, H) || m.IsLocationChecked(locId)) continue;
				
				locInfo = m.GetLocationInfoFromID(locId);
				if (locInfo.ID <= 0 || onlyImportant && locInfo.Flags == ItemFlag_Garbage) continue;
				UpdateClosestMarker_Actor(H, a, closest_distance, bestindx);
			}
		}
		else if (a.IsA('Hat_Goodie_Vault_Base') || a.IsA('Hat_NPC_Bullied'))
		{
			if (a.Name == 'Hat_Goodie_Vault_1') // golden vault
				continue;
			
			locId = m.ObjectToLocationId(a);
			if (!CanReachLocation(locId, H) || m.IsLocationChecked(locId)) continue;
			
			locInfo = m.GetLocationInfoFromID(locId);
			if (locInfo.ID <= 0 || onlyImportant && locInfo.Flags == ItemFlag_Garbage) continue;
			
			UpdateClosestMarker_Actor(H, a, closest_distance, bestindx);
		}
		else if (a.IsA('Hat_NPC_NyakuzaShop') || a.IsA('Hat_MetroTicketBooth_Base'))
		{
			if (m.HasAPBit("TalkedTo_"$a.Name, 1))
				continue;
			
			if (a.IsA('Hat_NPC_NyakuzaShop') && m.GetAPBits(string(a.Name)) <= 0)
				continue;
			
			if (!IsShopReachable(H, a))
				continue;

			shop = m.GetShopInventoryFromName(a.Name);
			if (shop != None)
			{
				if (!onlyImportant || m.DoesShopHaveImportantItems(shop, true))
				{
					UpdateClosestMarker_Actor(H, a, closest_distance, bestindx);
				}
			}
		}
	}
	
	HasAnyDeathWishLevelTokens = false;
	foreach H.PlayerOwner.DynamicActors(class'Hat_Collectible_DeathWishLevelToken', dwlt)
	{
		if (dwlt.IsLocked) continue;
		if (dwlt.bDeleteMe) continue;
		if (dwlt.PickupActor != None) continue;
		
		// All other token DW inherit from Mafia Town
		if (!HasAnyDeathWishLevelTokens)
		{
			HasAnyDeathWishLevelTokens = true;
			// Clear anything else, since if the DW is active, the player only wants the tokens
			closest_distance = 0;
			bestindx = INDEX_NONE;
			MarkerPositions.Length = 0;
			MarkerClasses.Length = 0;
		}
		
		UpdateClosestMarker_Actor(H, dwlt, closest_distance, bestindx);
	}
	
	TargetMarkerPosition = bestindx;
	RecalculateMarkersCountdown = 0.2f;
	
	if (ArrowMaterialInstance != None)
	{
		ArrowMaterialInstance.SetScalarParameterValue('PurpleAlpha', closest_distance >= 12000 ? 1 : 0);
	}
}

function bool IsShopReachable(HUD H, Actor a)
{
	local Hat_Loadout lo;
	local int difficulty;
	lo = Hat_PlayerController(H.PlayerOwner).MyLoadout;
	difficulty = `AP.SlotData.LogicDifficulty;
	
	if (`GameManager.GetCurrentAct() == 8) // Rush Hour
		return false;
	
	switch (a.Name)
	{
		// Green Clean Station below the Ice Hat trap door
		case 'Hat_NPC_NyakuzaShop_6':
			return lo.HasCollectible(class'Hat_Collectible_MetroTicket_RouteA') || lo.BackpackHasInventory(class'Hat_Ability_StatueFall');
		
		// Bluefin Tunnel
		case 'Hat_NPC_NyakuzaShop_7':  case 'Hat_MetroTicketBooth_2':
			return difficulty >= 0 && TicketSkipsAllowed()
			|| lo.HasCollectible(class'Hat_Collectible_MetroTicket_RouteB') 
			|| lo.HasCollectible(class'Hat_Collectible_MetroTicket_RouteC');
		
		// Pink Paw Station
		case 'Hat_NPC_NyakuzaShop_12': case 'Hat_MetroTicketBooth_3':
			return difficulty >= `MODERATE && TicketSkipsAllowed()
			|| (lo.HasCollectible(class'Hat_Collectible_MetroTicket_RouteD') || 
			lo.HasCollectible(class'Hat_Collectible_MetroTicket_RouteA') && 
			lo.HasCollectible(class'Hat_Collectible_MetroTicket_RouteC'))
			&& (difficulty >= `MODERATE || lo.BackpackHasInventory(class'Hat_Ability_Hookshot') && lo.BackpackHasInventory(class'Hat_Ability_FoxMask'));
	}
	
	return true;
}

function bool Tick(HUD H, float d)
{
	IdleTime = 10.0;
	return Super.Tick(H, d);
}

function bool AreImportantItemsLeft(HUD H, optional bool traps=true)
{
	local int i;
	local string mapName;
	local Archipelago_GameMod m;
	local Actor a;
	local Archipelago_ShopInventory_Base shop;
	mapName = class'Hat_SaveBitHelper'.static.GetCorrectedMapFilename();
	m = `AP;
	
	for (i = 0; i < m.SlotData.LocationInfoArray.Length; i++)
	{
		if (m.SlotData.LocationInfoArray[i].MapName ~= mapName 
		&& m.SlotData.LocationInfoArray[i].Flags != ItemFlag_Garbage 
		&& !m.SlotData.LocationInfoArray[i].IsStatic)
		{
			if (!m.IsLocationChecked(m.SlotData.LocationInfoArray[i].ID) && CanReachLocation(m.SlotData.LocationInfoArray[i].ID, H))
				return true;
		}
	}
	
	if (`GameManager.GetCurrentMapFilename() ~= "dlc_metro")
	{
		foreach H.PlayerOwner.DynamicActors(class'Actor', a)
		{
			if (a.IsA('Hat_NPC_NyakuzaShop') || a.IsA('Hat_MetroTicketBooth_Base'))
			{
				if (m.HasAPBit("TalkedTo_"$a.Name, 1))
					continue;
				
				if (a.IsA('Hat_NPC_NyakuzaShop') && m.GetAPBits(string(a.Name)) <= 0)
					continue;
				
				if (!IsShopReachable(H, a))
					continue;
				
				shop = m.GetShopInventoryFromName(a.Name);
				if (shop != None)
				{
					if (m.DoesShopHaveImportantItems(shop, true))
						return true;
				}
			}
		}
	}
	
	return false;
}

function bool UpdateClosestMarker_Actor(HUD H, Actor item, out float closest_distance, out int bestindx)
{
	local float distance;
	local Vector itemloc;
	
	// Mafia Town secret cave location
	if (Archipelago_RandomizedItem_Base(item) != None && Archipelago_RandomizedItem_Base(item).LocationId == 2000305220)
	{
		itemloc = vect(-3810, 460, 660);
	}
	else
	{
		itemloc = item.Location;
	}
	
	distance = VSize((H.PlayerOwner.Pawn.Location - itemloc)*vect(1,1,4));
	
	if (bestindx >= 0 && distance >= closest_distance) return false;
	
	closest_distance = distance;
	
	MarkerPositions.AddItem(itemloc);
	MarkerClasses.AddItem(item.Class);
	bestindx = MarkerPositions.Length - 1;
	return true;
}

function bool CanReachLocation(int id, HUD H)
{
	local bool hookshot, cannon, finale;
	local int paintingUnlock, difficulty, act;
	local Archipelago_GameMod m;
	local string mapName;
	local Hat_Loadout lo;
	
	m = `AP;
	mapName = `GameManager.GetCurrentMapFilename();
	lo = Hat_PlayerController(H.PlayerOwner).MyLoadout;
	difficulty = m.SlotData.LogicDifficulty;
	act = `GameManager.GetCurrentAct();
	hookshot = lo.BackpackHasInventory(class'Hat_Ability_Hookshot');

	// Mafia Town secret cave item (crate blocking the cave is removed in act 6)
	if (id == 2000305220)
	{
		return act == 6 || lo.BackpackHasInventory(class'Hat_Ability_Chemical');
	}
	
	// Is the cannon to Mafia HQ accessible?
	if (`GameManager.IsCurrentChapter(1))
	{
		cannon = act == 4 || act == 5 || act == 6 && CanHitObjects(false, true) || act == 7;
	}
	
	// Chest behind Mafia HQ
	if (id == 2000303486)
	{
		return cannon;
	}
	
	// Mafia Town - Above Boats
	if (id == 2000305218)
	{
		// Ice hat slide?
		if (difficulty >= `MODERATE && lo.BackpackHasInventory(class'Hat_Ability_StatueFall'))
		{
			return true;
		}
	}
	
	// Subcon boss arena chest
	if (id == 2000323735)
	{
		// Cherry hover
		if (difficulty >= `EXPERT && CanSkipPaintings())
			return true;
		
		// Cherry bridge
		if (difficulty >= `HARD)
		{
			return !m.SlotData.ShuffleSubconPaintings || m.GetPaintingUnlocks() >= 1;
		}
		
		// Hookshot
		if (act == 3)
		{
			return hookshot && (!m.SlotData.ShuffleSubconPaintings || m.GetPaintingUnlocks() >= 1);
		}
		
		// Always accessible here
		return act == 6;
	}
	
	if (mapName ~= "subconforest" && act == 6)
	{
		// If below Hard, we can't cross the gap between the arena and the village
		if (difficulty < `HARD)
			return false;
	}
	
	// Manor rooftop item
	if (id == 2000325466)
	{
		// Can we skip the big dweller wall?
		if (difficulty >= `MODERATE)
		{
			return CanSkipPaintings() || m.GetPaintingUnlocks() >= 1;
		}
		
		return (CanSkipPaintings() || m.GetPaintingUnlocks() >= 1) && CanHitObjects(true);
	}
	
	if (mapName ~= "alpsandsails")
	{
		finale = class'Hat_SeqCond_IsAlpineFinale'.static.IsAlpineFinale();
		
		// Wait until intro is complete (intro is skipped in Illness)
		if (!class'Hat_SaveBitHelper'.static.HasLevelBit("Actless_FreeRoam_Intro_Complete", 1, "AlpsAndSails") && !finale)
			return false;
		
		// Goat Refinery
		if (id == 2000333635)
		{
			if (finale)
			{
				// In Illness, we start in Goat Village, so we can possibly cross the gap to the Goat Refinery item
				return difficulty >= `HARD || difficulty >= `MODERATE && lo.BackpackHasInventory(class'Hat_Ability_Sprint');
			}
		}
		
		// If we're in Illness and have no hookshot, Goat Village items only
		if (!hookshot)
			return id == 2000334855 || id == 2000334856;
		
		if (finale)
		{
			// Only these locations can be reached in Illness with hookshot
			if (id != 2000334855 && id != 2000334856 && id != 2000335911 
				&& id != 2000335756 && id != 2000336311 && id != 2000334760 && id != 2000334776)
			{
				return false;
			}
		}
			
		if (m.SlotData.ShuffleZiplines)
		{
			if (BirdhousePathLocs.Find(id) != -1 && (!hookshot || !m.HasZipline(Zipline_Birdhouse)))
				return false;
			
			if (LavaCakePathLocs.Find(id) != -1 && (!hookshot || !m.HasZipline(Zipline_LavaCake)))
				return false;
			
			if (WindmillPathLocs.Find(id) != -1 && (!hookshot || !m.HasZipline(Zipline_Windmill)))
				return false;
			
			if (BellPathLocs.Find(id) != -1 && (!hookshot || !m.HasZipline(Zipline_Bell)))
				return false;
		}
	}
	else if (mapName ~= "DeadBirdStudio")
	{
		if (!m.SlotData.UmbrellaLogic)
		{
			// Can we cross the pit over to the second DJ Grooves area?
			if (difficulty < `MODERATE && !lo.BackpackHasInventory(class'Archipelago_Weapon_Umbrella', true) 
				&& !lo.BackpackHasInventory(class'Archipelago_Weapon_BaseballBat', true)
				&& !lo.BackpackHasInventory(class'Hat_Ability_Chemical', true))
			{
				return id == 2000304874 || id == 2000305024 || id == 2000305248 || id == 2000305247 || id == 2000303898;
			}
			else
			{
				// We can, but if we're in the basement instead, check if we can get past the lever near the elevator
				if (act == 6)
				{
					return difficulty >= `EXPERT || id == 2000304874 || id == 2000305024 || id == 2000305248 || id == 2000305247;
				}
				else
				{
					// We can get everything here
					return true;
				}
			}
		}
		
		// If UmbrellaLogic is on and we need a weapon to hit the lever near the elevator, see if we can skip that requirement
		if (difficulty >= `EXPERT)
		{
			return true;
		}
		else if (act == 6 || !CanHitObjects())
		{
			return id == 2000304874 || id == 2000305024 || id == 2000305248 || id == 2000305247;
		}
	}
	else if (mapName ~= "TimeRift_Cave_Aquarium")
	{
		if (!hookshot)
		{
			// Nearly impossible without Hookshot
			return id == 2000346454 || id == 2000346452 || id == 2000346449;
		}
	}
	else if (mapName ~= "dlc_metro" && act == 8)
	{
		// We can't grab anything from Rush Hour
		return false;
	}
	else if (mapName ~= "ship_main" && act == 1)
	{
		// Bon Voyage is impossible without Hookshot, so only the items at the docks are available
		if (!hookshot)
			return id == 2000305321 || id == 2000304313;
	}
	
	// Mystifying Time Mesa buttons
	if (id == 2000337058 && m.HasZipline(Zipline_LavaCake))
	{
		if (difficulty >= `MODERATE) // Can we skip the gap?
			return true;
		
		return lo.BackpackHasInventory(class'Hat_Ability_TimeStop') || lo.BackpackHasInventory(class'Hat_Ability_Sprint');
	}

	// HUMT
	if (InStr(mapName, "mafia_town") != -1 && act == 6)
	{
		return id == 2000334758 ||
		id == 2000304214 ||
		id == 2000303529 ||
		id == 2000304610 ||
		id == 2000303535 ||
		id == 2000304459 ||
		id == 2000304213 && hookshot ||
		id == 2000304608 ||
		id == 2000304462 ||
		id == 2000303489 ||
		id == 2000303530 ||
		id == 2000304456 ||
		id == 2000304457 ||
		id == 2000304606 ||
		id == 2000303481 && (hookshot || difficulty >= `MODERATE) ||
		id == 2000304607 && (difficulty >= `MODERATE || lo.BackpackHasInventory(class'Hat_Ability_StatueFall')) ||
		id == 2000304212 ||
		id == 2000302003 ||
		id == 2000302004 ||
		id == 2000303532 ||
		id == 2000304829 && lo.BackpackHasInventory(class'Hat_Ability_StatueFall') ||
		id == 2000305218; 
	}
	
	// Subcon long tree climb chest
	if ((id == 2000323734) && (CanSkipPaintings() || m.GetPaintingUnlocks() >= 2))
	{
		// Can we skip the climb?
		if (difficulty >= `EXPERT || CanSDJ())
			return true;
	}
	
	if (HookshotRequiredLocs.Find(id) != -1 && !hookshot)
		return false;
	
	if (IceHatRequiredLocs.Find(id) != -1 && !lo.BackpackHasInventory(class'Hat_Ability_StatueFall'))
		return false;
	
	if (DwellerMaskRequiredLocs.Find(id) != -1 && !lo.BackpackHasInventory(class'Hat_Ability_FoxMask'))
		return false;
	
	if (BrewingHatRequiredLocs.Find(id) != -1 && !lo.BackpackHasInventory(class'Hat_Ability_Chemical'))
		return false;
	
	if (m.SlotData.ShuffleSubconPaintings && mapName ~= "subconforest")
	{
		paintingUnlock = m.GetPaintingUnlocks();
		
		if (VillagePaintingLocs.Find(id) != -1)
			return paintingUnlock >= 1 || CanSkipPaintings();
		
		if (SwampPaintingLocs.Find(id) != -1)
			return paintingUnlock >= 2 || CanSkipPaintings();
		
		if (CourtyardPaintingLocs.Find(id) != -1)
			return paintingUnlock >= 3 || CanSkipPaintings();
	}
	
	// Nyakuza Metro
	if (id == 2000305111) // Bluefin Tunnel item
	{
		if (difficulty >= `MODERATE && TicketSkipsAllowed())
			return true;
		
		// Green or blue ticket
		return lo.HasCollectible(class'Hat_Collectible_MetroTicket_RouteB')
			|| lo.HasCollectible(class'Hat_Collectible_MetroTicket_RouteC');
	}
	else if (id == 2000305110) // Pink Paw cat vaccuum
	{
		if (difficulty >= `MODERATE && TicketSkipsAllowed())
			return true;
		
		// Pink or yellow+blue ticket and Dweller+Hookshot
		return (lo.HasCollectible(class'Hat_Collectible_MetroTicket_RouteD') 
			|| lo.HasCollectible(class'Hat_Collectible_MetroTicket_RouteA')
			&& lo.HasCollectible(class'Hat_Collectible_MetroTicket_RouteC'))
			&& (difficulty >= `MODERATE || hookshot && lo.BackpackHasInventory(class'Hat_Ability_FoxMask'));
	}
	else if (id == 2000304106) // Pink Paw Station fan
	{
		if (difficulty >= `MODERATE && TicketSkipsAllowed())
			return true;
		
		// Pink or yellow+blue AND Time Stop
		return (lo.HasCollectible(class'Hat_Collectible_MetroTicket_RouteD')
			|| lo.HasCollectible(class'Hat_Collectible_MetroTicket_RouteA')
			&& lo.HasCollectible(class'Hat_Collectible_MetroTicket_RouteC'))
			&& (difficulty >= `MODERATE || lo.BackpackHasInventory(class'Hat_Ability_TimeStop'));
	}
	
	return true;
}

static function bool CanHitObjects(optional bool MaskBypass, optional bool UmbrellaOnly)
{
	if (!`AP.SlotData.UmbrellaLogic)
		return true;
	
	if (UmbrellaOnly)
	{
		return class'Hat_Loadout'.static.BackpackHasInventory(class'Archipelago_Weapon_Umbrella', true)
		|| class'Hat_Loadout'.static.BackpackHasInventory(class'Archipelago_Weapon_BaseballBat', true);
	}
	
	return class'Hat_Loadout'.static.BackpackHasInventory(class'Archipelago_Weapon_Umbrella', true)
	|| class'Hat_Loadout'.static.BackpackHasInventory(class'Archipelago_Weapon_BaseballBat', true)
	|| class'Hat_Loadout'.static.BackpackHasInventory(class'Hat_Ability_Chemical')
	|| MaskBypass && class'Hat_Loadout'.static.BackpackHasInventory(class'Hat_Ability_FoxMask');
}

static function bool TicketSkipsAllowed()
{
	return `AP.SlotData.NoTicketSkips == 0;
}

static function bool CanSDJ()
{
	return class'Hat_Loadout'.static.BackpackHasInventory(class'Hat_Ability_Sprint') && `AP.SlotData.LogicDifficulty >= `HARD;
}

static function bool CanSkipPaintings()
{
	local Archipelago_GameMod m;
	m = `AP;
	
	if (!m.SlotData.ShuffleSubconPaintings)
		return true;
	
	if (m.SlotData.LogicDifficulty < `MODERATE || m.SlotData.NoPaintingSkips)
		return false;
	
	return true;
}

defaultproperties
{
	IceHatRequiredLocs[0] = 2000304607;
	IceHatRequiredLocs[1] = 2000304831;
	IceHatRequiredLocs[2] = 2000304829;
	IceHatRequiredLocs[3] = 2000304979;
	IceHatRequiredLocs[4] = 2000304049;
	
	HookshotRequiredLocs[0] = 2000305218;
	HookshotRequiredLocs[1] = 2000303481;
	HookshotRequiredLocs[2] = 2000304213;
	HookshotRequiredLocs[3] = 2000324766;
	HookshotRequiredLocs[4] = 2000324856;
	HookshotRequiredLocs[5] = 2000305432;
	HookshotRequiredLocs[6] = 2000305059;
	HookshotRequiredLocs[7] = 2000305057;
	HookshotRequiredLocs[8] = 2000305061;
	HookshotRequiredLocs[9] = 2000304813;
	HookshotRequiredLocs[10] = 2000305058;
	HookshotRequiredLocs[11] = 2000305431;
	HookshotRequiredLocs[12] = 2000305819;
	HookshotRequiredLocs[13] = 2000305110;
	HookshotRequiredLocs[14] = 2000304106;
	HookshotRequiredLocs[15] = 2000324311;
	
	DwellerMaskRequiredLocs[0] = 2000324767;
	DwellerMaskRequiredLocs[1] = 2000324464;
	DwellerMaskRequiredLocs[2] = 2000324855;
	DwellerMaskRequiredLocs[3] = 2000324463;
	DwellerMaskRequiredLocs[4] = 2000324766;
	DwellerMaskRequiredLocs[5] = 2000336497;
	DwellerMaskRequiredLocs[6] = 2000336395;
	DwellerMaskRequiredLocs[7] = 2000323734;
	DwellerMaskRequiredLocs[8] = 2000334434;
	DwellerMaskRequiredLocs[9] = 2000336478;
	DwellerMaskRequiredLocs[10] = 2000335826;
	DwellerMaskRequiredLocs[11] = 2000305110;
	DwellerMaskRequiredLocs[12] = 2000304106;
	
	BrewingHatRequiredLocs[0] = 2000305701;
	BrewingHatRequiredLocs[1] = 2000334758;
	BrewingHatRequiredLocs[2] = 2000335756;
	BrewingHatRequiredLocs[3] = 2000336497;
	BrewingHatRequiredLocs[4] = 2000336496;
	BrewingHatRequiredLocs[5] = 2000335885;
	BrewingHatRequiredLocs[6] = 2000335886;
	BrewingHatRequiredLocs[7] = 2000335492;
	BrewingHatRequiredLocs[8] = 2000325479;
	BrewingHatRequiredLocs[9] = 2000325478;
	
	BirdhousePathLocs[0] = 2000335911;
	BirdhousePathLocs[1] = 2000335756;
	BirdhousePathLocs[2] = 2000335561;
	BirdhousePathLocs[3] = 2000334831;
	BirdhousePathLocs[4] = 2000334758;
	BirdhousePathLocs[5] = 2000336497;
	BirdhousePathLocs[6] = 2000336496;
	BirdhousePathLocs[7] = 2000335885;
	BirdhousePathLocs[8] = 2000335886;
	BirdhousePathLocs[9] = 2000335492;
	
	LavaCakePathLocs[0] = 2000337058;
	LavaCakePathLocs[1] = 2000336052;
	LavaCakePathLocs[2] = 2000335448;
	LavaCakePathLocs[3] = 2000334291;
	LavaCakePathLocs[4] = 2000335417;
	LavaCakePathLocs[5] = 2000335418;
	LavaCakePathLocs[6] = 2000336311;
	
	WindmillPathLocs[0] = 2000334760;
	WindmillPathLocs[1] = 2000334776;
	WindmillPathLocs[2] = 2000336395;
	WindmillPathLocs[3] = 2000335783;
	WindmillPathLocs[4] = 2000335815;
	WindmillPathLocs[5] = 2000335389;
	
	BellPathLocs[0] = 2000334434;
	BellPathLocs[1] = 2000336478;
	BellPathLocs[2] = 2000335826;

	VillagePaintingLocs[0] = 2000326296;
	VillagePaintingLocs[1] = 2000324762;
	VillagePaintingLocs[2] = 2000324763;
	VillagePaintingLocs[3] = 2000324764;
	VillagePaintingLocs[4] = 2000324706;
	VillagePaintingLocs[5] = 2000325468;
	VillagePaintingLocs[6] = 2000323728;
	VillagePaintingLocs[7] = 2000323730;
	VillagePaintingLocs[8] = 2000324465;

	SwampPaintingLocs[0] = 2000324710;
	SwampPaintingLocs[1] = 2000325079;
	SwampPaintingLocs[2] = 2000323731;
	SwampPaintingLocs[3] = 2000325467;
	SwampPaintingLocs[4] = 2000324462;
	SwampPaintingLocs[5] = 2000325080;
	SwampPaintingLocs[6] = 2000324765;
	SwampPaintingLocs[7] = 2000324856;
	SwampPaintingLocs[8] = 2000325478;
	SwampPaintingLocs[9] = 2000323734;
	
	CourtyardPaintingLocs[0] = 2000325479;
	CourtyardPaintingLocs[1] = 2000324767;
	CourtyardPaintingLocs[2] = 2000324464;
	CourtyardPaintingLocs[3] = 2000324709;
	CourtyardPaintingLocs[4] = 2000324855;
	CourtyardPaintingLocs[5] = 2000325473;
	CourtyardPaintingLocs[6] = 2000325472;
	CourtyardPaintingLocs[7] = 2000325082;
	CourtyardPaintingLocs[8] = 2000324463;
	CourtyardPaintingLocs[9] = 2000324766;
}