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
	
	if (m.IsInSpaceship() && !m.HasAPBit("RumbiYarn", 1))
	{
		// Point to Rumbi, most players don't realize that she is a check.
		if ((!m.SlotData.UmbrellaLogic || CanHitObjects(false)) && `SaveManager.GetNumberOfTimePieces() >= 4)
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
	
	hasBrewing = class'Hat_Loadout'.static.BackpackHasInventory(class'Hat_Ability_Chemical');
	if (hasBrewing)
	{
		foreach H.PlayerOwner.DynamicActors(class'Hat_ImpactInteract_Breakable_ChemicalBadge', b)
		{
			valid = false;

			for (i = 0; i < b.Rewards.Length; i++)
			{
				if (class<Hat_Collectible_Important>(b.Rewards[i]) != None)	
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
		if (mapName ~= "subconforest" && a.IsA('Hat_InteractiveFoliage_HarborBush') && hasBrewing)
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
	mapName = class'Hat_SaveBitHelper'.static.GetCorrectedMapFilename();
	m = `AP;
	
	for (i = 0; i < m.SlotData.LocationInfoArray.Length; i++)
	{
		if (m.SlotData.LocationInfoArray[i].MapName ~= mapName 
		&& m.SlotData.LocationInfoArray[i].Flags != ItemFlag_Garbage 
		&& !m.SlotData.LocationInfoArray[i].IsStatic)
		{
			if (!m.IsLocationChecked(m.SlotData.LocationInfoArray[i].ID))
				return true;
		}
	}
	
	return false;
}

function bool UpdateClosestMarker_Actor(HUD H, Actor item, out float closest_distance, out int bestindx)
{
	local float distance;
	local Vector itemloc;
	
	// Mafia Town secret cave location
	if (Archipelago_RandomizedItem_Base(item) != None && Archipelago_RandomizedItem_Base(item).LocationId == 305220)
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
	local bool finale, cannon, nobonk, hookshot;
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
	nobonk = lo.BackpackHasInventory(class'Hat_Ability_NoBonk');
	
	// Mafia Town secret cave item
	if (id == 305220)
	{
		return act == 6 || lo.BackpackHasInventory(class'Hat_Ability_Chemical');
	}
	
	if (`GameManager.IsCurrentChapter(1))
	{
		cannon = act == 4 || act == 5 || act == 6 && CanHitObjects() || act == 7;
	}
	
	// Chest behind Mafia HQ
	if (id == 303486)
	{
		return cannon;
	}
	else if ((id == 303481 || id == 304607) && m.SlotData.KnowledgeTricks)
	{
		if (act == 5 || act == 6 || act == 7)
		{
			return act == 6 && CanHitObjects() || true;
		}
	}
	
	// Subcon boss arena chest
	if (id == 323735)
	{
		if (difficulty >= 2)
			return true;

		if (difficulty >= 1)
		{
			if (CanSDJ() && lo.BackpackHasInventory(class'Hat_Ability_NoBonk'))
				return true;
		}
		
		if (act == 3)
		{
			return hookshot && (!m.SlotData.ShuffleSubconPaintings || m.GetPaintingUnlocks() >= 1);
		}
		
		return act == 6;
	}
	
	// Manor rooftop item
	if (id == 325466)
	{
		if (difficulty >= 2)
		{
			return !m.SlotData.ShuffleSubconPaintings || m.GetPaintingUnlocks() >= 1 || CanHitObjects(true); 
		}
		
		return (!m.SlotData.ShuffleSubconPaintings || m.SlotData.KnowledgeTricks && nobonk || m.GetPaintingUnlocks() >= 1) && CanHitObjects(true);
	}
	
	if (mapName ~= "DeadBirdStudio")
	{
		if (act == 6 || !CanHitObjects(false))
		{
			return id == 304874 || id == 305024 || id == 305248 || id == 305247;
		}
	}
	else if (mapName ~= "dlc_metro" && act == 8)
	{
		return false;
	}
	else if (mapName ~= "ship_main" && act == 1)
	{
		if (!hookshot)
			return id == 305321 || id == 304313;
	}
	else if (m.SlotData.ShuffleSubconPaintings && mapName ~= "subconforest")
	{
		paintingUnlock = m.GetPaintingUnlocks();
		
		if (VillagePaintingLocs.Find(id) != -1)
			return paintingUnlock >= 1 || m.SlotData.KnowledgeTricks && nobonk || difficulty >= 2;
		
		if (SwampPaintingLocs.Find(id) != -1)
			return paintingUnlock >= 2 || m.SlotData.KnowledgeTricks && nobonk || difficulty >= 2;
		
		if (CourtyardPaintingLocs.Find(id) != -1)
			return paintingUnlock >= 3 || m.SlotData.KnowledgeTricks || difficulty >= 2;
	}
	
	if (mapName ~= "alpsandsails")
	{
		finale = class'Hat_SeqCond_IsAlpineFinale'.static.IsAlpineFinale();
		
		if (!class'Hat_SaveBitHelper'.static.HasLevelBit("Actless_FreeRoam_Intro_Complete", 1, "AlpsAndSails") && !finale)
			return false;
		
		if (!hookshot)
			return id == 334855 || id == 334856;
		
		if (m.SlotData.ShuffleZiplines)
		{
			if (BirdhousePathLocs.Find(id) != -1 && !m.HasZipline(Zipline_Birdhouse))
				return false;

			if (LavaCakePathLocs.Find(id) != -1 && !m.HasZipline(Zipline_LavaCake))
				return false;
			
			if (WindmillPathLocs.Find(id) != -1 && !m.HasZipline(Zipline_Windmill))
				return false;
			
			if (BellPathLocs.Find(id) != -1 && !m.HasZipline(Zipline_Bell))
				return false;
		}
		
		if (finale)
		{
			return id == 334855 || id == 334856 || id == 335911 
			|| id == 335756 || id == 336311 || id == 334760 || id == 334776;
		}
	}
	
	// HUMT
	if (InStr(mapName, "mafia_town") != -1 && act == 6)
	{
		return id == 334758 ||
		id == 304214 ||
		id == 303529 ||
		id == 304610 ||
		id == 303535 ||
		id == 304459 ||
		id == 304213 && hookshot ||
		id == 304608 ||
		id == 304462 ||
		id == 303489 ||
		id == 303530 ||
		id == 304456 ||
		id == 304457 ||
		id == 304606 ||
		id == 303481 && lo.BackpackHasInventory(class'Hat_Ability_Hookshot') ||
		id == 304607 && lo.BackpackHasInventory(class'Hat_Ability_StatueFall') ||
		id == 304212 ||
		id == 302003 ||
		id == 302004 ||
		id == 303532 ||
		id == 304829 && lo.BackpackHasInventory(class'Hat_Ability_StatueFall') ||
		id == 305218; 
	}
	
	if (id == 323734
	|| id == 336497)
	{
		if (CanSDJ())
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
	
	// Nyakuza Metro
	if (id == 305111)
	{
		// Green or blue ticket
		return lo.HasCollectible(class'Hat_Collectible_MetroTicket_RouteB')
			|| lo.HasCollectible(class'Hat_Collectible_MetroTicket_RouteC');
	}
	else if (id == 305110)
	{
		if (m.SlotData.KnowledgeTricks && hookshot)
			return true;
		
		// Pink or yellow+blue ticket
		return lo.HasCollectible(class'Hat_Collectible_MetroTicket_RouteD') 
			|| lo.HasCollectible(class'Hat_Collectible_MetroTicket_RouteA')
			&& lo.HasCollectible(class'Hat_Collectible_MetroTicket_RouteC');
	}
	else if (id == 304106)
	{
		if (m.SlotData.KnowledgeTricks && hookshot)
			return true;

		// Pink or yellow+blue AND Time Stop
		return (lo.HasCollectible(class'Hat_Collectible_MetroTicket_RouteD')
			|| lo.HasCollectible(class'Hat_Collectible_MetroTicket_RouteA')
			&& lo.HasCollectible(class'Hat_Collectible_MetroTicket_RouteC'))
			&& lo.BackpackHasInventory(class'Hat_Ability_TimeStop');
	}
	
	return true;
}

static function bool CanHitObjects(optional bool MaskBypass)
{
	if (!`AP.SlotData.UmbrellaLogic)
		return true;
	
	return class'Hat_Loadout'.static.BackpackHasInventory(class'Archipelago_Weapon_Umbrella', true)
	|| class'Hat_Loadout'.static.BackpackHasInventory(class'Archipelago_Weapon_BaseballBat', true)
	|| class'Hat_Loadout'.static.BackpackHasInventory(class'Hat_Ability_Chemical')
	|| MaskBypass && class'Hat_Loadout'.static.BackpackHasInventory(class'Hat_Ability_FoxMask');
}

static function bool CanSDJ()
{
	return class'Hat_Loadout'.static.BackpackHasInventory(class'Hat_Ability_Sprint') && `AP.SlotData.LogicDifficulty >= 1;
}

defaultproperties
{
	IceHatRequiredLocs[0] = 304607;
	IceHatRequiredLocs[1] = 304831;
	IceHatRequiredLocs[2] = 304829;
	IceHatRequiredLocs[3] = 304979;
	
	HookshotRequiredLocs[0] = 305218;
	HookshotRequiredLocs[1] = 303481;
	HookshotRequiredLocs[2] = 304213;
	HookshotRequiredLocs[3] = 324766;
	HookshotRequiredLocs[4] = 324856;
	HookshotRequiredLocs[5] = 305432;
	HookshotRequiredLocs[6] = 305059;
	HookshotRequiredLocs[7] = 305057;
	HookshotRequiredLocs[8] = 305061;
	HookshotRequiredLocs[9] = 304813;
	HookshotRequiredLocs[10] = 305058;
	HookshotRequiredLocs[11] = 305431;
	HookshotRequiredLocs[12] = 305819;
	HookshotRequiredLocs[13] = 305110;
	HookshotRequiredLocs[14] = 304106;
	
	DwellerMaskRequiredLocs[0] = 324767;
	DwellerMaskRequiredLocs[1] = 324464;
	DwellerMaskRequiredLocs[2] = 324855;
	DwellerMaskRequiredLocs[3] = 324463;
	DwellerMaskRequiredLocs[4] = 324766;
	DwellerMaskRequiredLocs[5] = 336497;
	DwellerMaskRequiredLocs[6] = 336395;
	DwellerMaskRequiredLocs[7] = 323734;
	DwellerMaskRequiredLocs[8] = 334434;
	DwellerMaskRequiredLocs[9] = 336478;
	DwellerMaskRequiredLocs[10] = 335826;
	DwellerMaskRequiredLocs[11] = 305110;
	DwellerMaskRequiredLocs[12] = 304106;
	
	BrewingHatRequiredLocs[0] = 305701;
	BrewingHatRequiredLocs[1] = 334758;
	BrewingHatRequiredLocs[2] = 335756;
	BrewingHatRequiredLocs[3] = 336497;
	BrewingHatRequiredLocs[4] = 336496;
	BrewingHatRequiredLocs[5] = 335885;
	BrewingHatRequiredLocs[6] = 335886;
	BrewingHatRequiredLocs[7] = 335492;
	
	BirdhousePathLocs[0] = 335911;
	BirdhousePathLocs[1] = 335756;
	BirdhousePathLocs[2] = 335561;
	BirdhousePathLocs[3] = 334831;
	BirdhousePathLocs[4] = 334758;
	BirdhousePathLocs[5] = 336497;
	BirdhousePathLocs[6] = 336496;
	BirdhousePathLocs[7] = 335885;
	BirdhousePathLocs[8] = 335886;
	BirdhousePathLocs[9] = 335492;
	
	LavaCakePathLocs[0] = 337058;
	LavaCakePathLocs[1] = 336052;
	LavaCakePathLocs[2] = 335448;
	LavaCakePathLocs[3] = 334291;
	LavaCakePathLocs[4] = 335417;
	LavaCakePathLocs[5] = 335418;
	LavaCakePathLocs[6] = 336311;
	
	WindmillPathLocs[0] = 334760;
	WindmillPathLocs[1] = 334776;
	WindmillPathLocs[2] = 336395;
	WindmillPathLocs[3] = 335783;
	WindmillPathLocs[4] = 335815;
	WindmillPathLocs[5] = 335389;
	
	BellPathLocs[0] = 334434;
	BellPathLocs[1] = 336478;
	BellPathLocs[2] = 335826;

	VillagePaintingLocs[0] = 326296;
	VillagePaintingLocs[1] = 324762;
	VillagePaintingLocs[2] = 324763;
	VillagePaintingLocs[3] = 324764;
	VillagePaintingLocs[4] = 324706;
	VillagePaintingLocs[5] = 325468;
	VillagePaintingLocs[6] = 323728;
	VillagePaintingLocs[7] = 323730;
	VillagePaintingLocs[8] = 324465;
	VillagePaintingLocs[9] = 325466;

	SwampPaintingLocs[0] = 324710;
	SwampPaintingLocs[1] = 325079;
	SwampPaintingLocs[2] = 323731;
	SwampPaintingLocs[3] = 325467;
	SwampPaintingLocs[4] = 324462;
	SwampPaintingLocs[5] = 325080;
	SwampPaintingLocs[6] = 324765;
	SwampPaintingLocs[7] = 324856;
	SwampPaintingLocs[8] = 325478;
	SwampPaintingLocs[9] = 323734;
	
	CourtyardPaintingLocs[0] = 325479;
	CourtyardPaintingLocs[1] = 324767;
	CourtyardPaintingLocs[2] = 324464;
	CourtyardPaintingLocs[3] = 324709;
	CourtyardPaintingLocs[4] = 324855;
	CourtyardPaintingLocs[5] = 325473;
	CourtyardPaintingLocs[6] = 325472;
	CourtyardPaintingLocs[7] = 325082;
	CourtyardPaintingLocs[8] = 324463;
	CourtyardPaintingLocs[9] = 324766;
}