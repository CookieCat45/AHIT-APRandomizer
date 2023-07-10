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
	local int bestindx, i, mode;
	local bool HasAnyDeathWishLevelTokens, onlyImportant;
	local Hat_ImpactInteract_Breakable_ChemicalBadge b;
	local Archipelago_GameMod m;
	local Actor a;
	
	m = `AP;
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
		if (!CanReachLocation(m.ObjectToLocationId(chest))) continue;
		if (onlyImportant && m.ImportantContainers.Find(chest) == -1) continue;
		
		UpdateClosestMarker_Actor(H, chest, closest_distance, bestindx);
	}
	
	// pages ignore onlyImportant, since they're the only items to collect in rifts
	foreach H.PlayerOwner.DynamicActors(class'Hat_Collectible_StoryBookPage', page)
	{
		if (!CanReachLocation(m.ObjectToLocationId(page))) continue;
		UpdateClosestMarker_Actor(H, page, closest_distance, bestindx);
	}
	
	if (class'Hat_Loadout'.static.BackpackHasInventory(class'Hat_Ability_Chemical'))
	{
		foreach H.PlayerOwner.DynamicActors(class'Hat_ImpactInteract_Breakable_ChemicalBadge', b)
		{
			if (!CanReachLocation(m.ObjectToLocationId(b))) continue;
			if (onlyImportant && m.ImportantContainers.Find(b) == -1) continue;
			
			for (i = 0; i < b.Rewards.Length; i++)
			{
				if (class<Hat_Collectible_Important>(b.Rewards[i]) != None)	
				{
					UpdateClosestMarker_Actor(H, b, closest_distance, bestindx);
					break;
				}
			}
		}
	}
	
	foreach H.PlayerOwner.DynamicActors(class'Actor', a)
	{
		if (a.IsA('Hat_Goodie_Vault_Base') || a.IsA('Hat_NPC_Bullied'))
		{
			if (!CanReachLocation(m.ObjectToLocationId(a))) continue;
			if (m.SlotData.OpenedContainerIDs.Find(m.ObjectToLocationId(a)) != -1) continue;
			if (onlyImportant && m.ImportantContainers.Find(a) == -1) continue;
			
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
		ArrowMaterialInstance.SetScalarParameterValue('PurpleAlpha', HasAnyDeathWishLevelTokens ? 1 : 0);
	}
}

function bool Tick(HUD H, float d)
{
	IdleTime = 10.0;
	return Super.Tick(H, d);
}

function bool AreImportantItemsLeft(HUD H, optional bool traps=true)
{
	local Archipelago_RandomizedItem_Base item;
	
	foreach H.PlayerOwner.DynamicActors(class'Archipelago_RandomizedItem_Base', item)
	{
		if (item.ItemFlags != ItemFlag_Garbage && (traps || item.ItemFlags != ItemFlag_Trap))
			return false;
	}
	
	return `AP.ImportantContainers.Length > 0;
}

function bool UpdateClosestMarker_Actor(HUD H, Actor item, out float closest_distance, out int bestindx)
{
	local float distance;
	local Vector itemloc;
	
	itemloc = item.Location;
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
	// Mafia Town secret cave location, just points to bottom of map.
	if (id == 305220)
		return false;
	
	// Chest behind Mafia HQ
	if (id == 303486)
	{
		return (`GameManager.GetCurrentAct() == 4 || `GameManager.GetCurrentAct() == 6);
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
	DwellerMaskRequiredLocs[2] = 324709;
	DwellerMaskRequiredLocs[3] = 324855;
	DwellerMaskRequiredLocs[4] = 325082;
	DwellerMaskRequiredLocs[5] = 324463;
	DwellerMaskRequiredLocs[6] = 324766;
	DwellerMaskRequiredLocs[7] = 336497;
	DwellerMaskRequiredLocs[8] = 336395;
	DwellerMaskRequiredLocs[9] = 323734;
	
	BrewingHatRequiredLocs[0] = 305701;
}