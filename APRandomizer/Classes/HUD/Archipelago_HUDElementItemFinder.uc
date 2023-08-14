class Archipelago_HUDElementItemFinder extends Hat_HUDElementRelicMap;

`include(APRandomizer\Classes\Globals.uci);

var array<int> HookshotRequiredLocs;
var array<int> IceHatRequiredLocs;
var array<int> DwellerMaskRequiredLocs;
var array<int> BrewingHatRequiredLocs;

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
	
	if (`GameManager.IsMidMapTransition || `SaveManager == None || `SaveManager.GetCurrentSaveData() == None)
		return;
	
	m = `AP;
	if (m == None || m.SlotData == None || m.IsInSpaceship())
		return;
	
	bestindx = INDEX_NONE;
	MarkerPositions.Length = 0;
	MarkerClasses.Length = 0;
	closest_distance = 0;
	
	// Depending on our mode, we either point to the closest item, point to only important items, or point to important items first.
	mode = m.SlotData.CompassBadgeMode;
	onlyImportant = (mode == 2 || mode == 3 && AreImportantItemsLeft(H));
	
	// Iterations
	foreach H.PlayerOwner.DynamicActors(class'Archipelago_RandomizedItem_Base', item)
	{
		if (item.PickupActor != None) continue;
		if (!CanReachLocation(item.LocationId)) continue;
		if (onlyImportant && item.ItemFlags == ItemFlag_Garbage) continue;
		
		UpdateClosestMarker_Actor(H, item, closest_distance, bestindx);
	}
	
	foreach H.PlayerOwner.DynamicActors(class'Hat_TreasureChest_Base', chest)
	{
		if (chest.Content == None) continue;
		if (chest.Opened) continue;
		if (m.ChestArray.Find(chest) == -1) continue;
		
		locId = m.ObjectToLocationId(chest);
		if (!CanReachLocation(locId) || m.IsLocationChecked(locId)) continue;
		
		locInfo = m.GetLocationInfoFromID(locId);
		
		if (class<Hat_Collectible_StoryBookPage>(chest.Content) == None)
			if (locInfo.ID <= 0 || onlyImportant && locInfo.Flags == ItemFlag_Garbage) continue;
		
		UpdateClosestMarker_Actor(H, chest, closest_distance, bestindx);
	}
	
	// pages ignore onlyImportant, since they're the only items to collect in rifts
	foreach H.PlayerOwner.DynamicActors(class'Hat_Collectible_StoryBookPage', page)
	{
		locId = m.ObjectToLocationId(page);
		if (!CanReachLocation(locId)) continue;
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
				if (!CanReachLocation(locId) || m.IsLocationChecked(locId)) continue;
				
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
				if (!CanReachLocation(locId) || m.IsLocationChecked(locId)) continue;
				
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
			if (!CanReachLocation(locId) || m.IsLocationChecked(locId)) continue;
			
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
	local array<LocationInfo> locInfoArray;
	mapName = class'Hat_SaveBitHelper'.static.GetCorrectedMapFilename();
	locInfoArray = `AP.SlotData.LocationInfoArray;
	
	for (i = 0; i < locInfoArray.Length; i++)
	{
		if (locInfoArray[i].MapName ~= mapName && locInfoArray[i].Flags != ItemFlag_Garbage)
		{
			if (!locInfoArray[i].Checked)
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

function bool CanReachLocation(int id)
{
	// Mafia Town secret cave item
	if (id == 305220)
	{
		return (`GameManager.IsCurrentAct(6) || class'Hat_Loadout'.static.BackpackHasInventory(class'Hat_Ability_Chemical'));
	}
	
	// Chest behind Mafia HQ
	if (id == 303486)
	{
		return (`GameManager.IsCurrentAct(4) || `GameManager.IsCurrentAct(5) || `GameManager.IsCurrentAct(6) || `GameManager.IsCurrentAct(7));
	}
	
	// Subcon boss arena chest
	if (id == 323735)
	{
		return `GameManager.IsCurrentAct(3) && class'Hat_Loadout'.static.BackpackHasInventory(class'Hat_Ability_Hookshot') || `GameManager.IsCurrentAct(6);
	}
	
	// Manor rooftop item
	if (id == 325466 && `AP.SlotData.UmbrellaLogic)
	{
		return CanHitDwellerBells(true);
	}
	
	if (`GameManager.IsCurrentChapter(4))
	{
		if (!class'Hat_Loadout'.static.BackpackHasInventory(class'Hat_Ability_Hookshot'))
			return id == 334855 || id == 334856;
	}
	
	// HUMT
	if (`GameManager.IsCurrentChapter(1) && `GameManager.IsCurrentAct(6))
	{
		return id == 334758 ||
		id == 304214 ||
		id == 303529 ||
		id == 304610 ||
		id == 303535 ||
		id == 304459 ||
		id == 304213 && class'Hat_Loadout'.static.BackpackHasInventory(class'Hat_Ability_Hookshot') ||
		id == 304608 ||
		id == 304462 ||
		id == 303489 ||
		id == 303530 ||
		id == 304456 ||
		id == 304457 ||
		id == 304606 ||
		id == 303481 && class'Hat_Loadout'.static.BackpackHasInventory(class'Hat_Ability_Hookshot') ||
		id == 304607 && class'Hat_Loadout'.static.BackpackHasInventory(class'Hat_Ability_StatueFall') ||
		id == 304212 ||
		id == 302003 ||
		id == 302004 ||
		id == 305218; 
	}
	
	if (HookshotRequiredLocs.Find(id) != -1 && !class'Hat_Loadout'.static.BackpackHasInventory(class'Hat_Ability_Hookshot'))
		return false;
	
	if (IceHatRequiredLocs.Find(id) != -1 && !class'Hat_Loadout'.static.BackpackHasInventory(class'Hat_Ability_StatueFall'))
		return false;
	
	if (DwellerMaskRequiredLocs.Find(id) != -1 && !class'Hat_Loadout'.static.BackpackHasInventory(class'Hat_Ability_FoxMask'))
		return false;
	
	if (BrewingHatRequiredLocs.Find(id) != -1 && !class'Hat_Loadout'.static.BackpackHasInventory(class'Hat_Ability_Chemical'))
		return false;
	
	return true;
}

function bool CanHitDwellerBells(optional bool MaskBypass)
{
	return class'Hat_Loadout'.static.BackpackHasInventory(class'Archipelago_Weapon_Umbrella', true)
	|| class'Hat_Loadout'.static.BackpackHasInventory(class'Hat_Ability_Chemical')
	|| MaskBypass && class'Hat_Loadout'.static.BackpackHasInventory(class'Hat_Ability_FoxMask');
}

defaultproperties
{
	IceHatRequiredLocs[0] = 304607;
	IceHatRequiredLocs[1] = 304831;
	IceHatRequiredLocs[2] = 304829;
	IceHatRequiredLocs[3] = 335826;
	IceHatRequiredLocs[4] = 304979;
	
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
	
	DwellerMaskRequiredLocs[0] = 324767;
	DwellerMaskRequiredLocs[1] = 324464;
	DwellerMaskRequiredLocs[2] = 324855;
	DwellerMaskRequiredLocs[3] = 325082;
	DwellerMaskRequiredLocs[4] = 324463;
	DwellerMaskRequiredLocs[5] = 324766;
	DwellerMaskRequiredLocs[6] = 336497;
	DwellerMaskRequiredLocs[7] = 336395;
	DwellerMaskRequiredLocs[8] = 323734;
	DwellerMaskRequiredLocs[9] = 334434;
	DwellerMaskRequiredLocs[10] = 336478;
	DwellerMaskRequiredLocs[11] = 335826;
	
	BrewingHatRequiredLocs[0] = 305701;
	BrewingHatRequiredLocs[1] = 334758;
	BrewingHatRequiredLocs[2] = 335756;
	BrewingHatRequiredLocs[3] = 336497;
	BrewingHatRequiredLocs[4] = 336496;
	BrewingHatRequiredLocs[5] = 335885;
	BrewingHatRequiredLocs[6] = 335886;
	BrewingHatRequiredLocs[7] = 335492;
}