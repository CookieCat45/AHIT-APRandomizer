class Archipelago_HUDMenuDeathWish extends Hat_HUDMenuDeathWish;

`include(APRandomizer\Classes\Globals.uci);
var array<Hat_DeathWishIcon> IconCache;
var Archipelago_GameMod mod;

simulated function OnOpenHUD(HUD H, optional string command)
{
	mod = `AP;
	Super.OnOpenHUD(H, command);
}

// remove act complete requirements
function bool IsActIncomplete(Hat_DeathWishIcon icon)
{
	return false;
}

function RenderStampCounter(HUD H, float posx)
{
	local string StampString;
	local float XL, YL, posy, IconSize, space;
	local Color C;
	
	StampString = mod.SlotData.DeathWishShuffle ? string(mod.SlotData.ShuffledDeathWishes.Length) : NumStamps $ " / " $ TotalStamps;
	H.Canvas.Font = class'Hat_FontInfo'.static.GetDefaultFont(StampString);
	H.Canvas.StrLen(StampString, XL, YL);
	XL *= H.Canvas.ClipY*0.00111;
	IconSize = H.Canvas.ClipY*0.08;
	posy = H.Canvas.ClipY*0.09 - class'Hat_Math'.static.InterpolationEaseInEaseOutJonas(H.Canvas.ClipY*0.2, 0, IntroOutro);
	space = IconSize*0.11;
	
	C = class'Hat_SnatcherContract_DeathWish'.default.CompleteColor;
	
	H.Canvas.SetDrawColor(255, 255, 255);
	DrawCenter(H, posx, posy, IconSize*4.6, IconSize*2.1, StampTotalBackground);
	
	H.Canvas.SetDrawColor(255, 255, 255);
	DrawCenter(H, posx + space/2 + XL/2, posy, IconSize, IconSize, NumStamps >= TotalStamps ? class'Hat_SnatcherContract_DeathWish'.default.PerfectIcon : class'Hat_SnatcherContract_DeathWish'.default.CompleteIcon);
	
	if (NumStamps >= TotalStamps)
		H.Canvas.SetDrawColor(C.R, C.G, C.B);
	
	DrawBorderedText(H.Canvas, StampString, posx - space/2 - IconSize/2, posy - IconSize*0.04, IconSize*0.0138, true, TextAlign_Center);
}

function bool Tick(HUD H, float d)
{
	if (!Super.Tick(H, d)) 
		return false;
	
	if (mod.SlotData.DeathWishShuffle)
	{
		ForceUpdateIcons();
	}

	return true;
}

function bool IsDeathWishAvailable(class<Hat_SnatcherContract_DeathWish> DeathWish, optional bool UseTargetValue = false)
{
	local bool result;
	local int locId, index;
	local array<int> locIds;
	local class<Hat_SnatcherContract_DeathWish> prevDw;
	
	if (mod.SlotData.DeathWishShuffle)
	{
		if (AvailableDWCache.Find(DeathWish) != INDEX_NONE)
		{
			result = true;
		}
		else if (UnavailableDWCache.Find(DeathWish) != INDEX_NONE)
		{
			result = false;
		}
		else
		{
			// check if previous death wish is complete
			index = mod.SlotData.ShuffledDeathWishes.Find(DeathWish);
			if (index == -1)
			{
				// not in list, do not unlock
				result = false;
			}
			else if (index == 0)
			{
				// first Death Wish
				result = true;
			}
			else
			{
				prevDw = mod.SlotData.ShuffledDeathWishes[index-1];
				result = prevDw.static.IsContractComplete();
			}
		}
	}
	else
	{
		result = Super.IsDeathWishAvailable(DeathWish, UseTargetValue);
	}
	
	if (result)
	{
		if (mod.SlotData.DeathWishShuffle)
			AvailableDWCache.AddItem(DeathWish);
		
		locId = class'Archipelago_ItemInfo'.static.GetDeathWishLocationID(DeathWish);
		
		if (mod.SlotData.ExcludedContracts.Find(DeathWish) != -1)
		{
			DeathWish.static.ForceUnlockObjective(0);
			DeathWish.static.ForceUnlockObjective(1);
			DeathWish.static.ForceUnlockObjective(2);
			
			locIds.AddItem(locId);
			if (mod.SlotData.BonusRewards && mod.SlotData.CheckedLocations.Find(locId+1) == -1)
			{
				locIds.AddItem(locId+1);
			}
		}
		else if (DeathWish.static.IsContractComplete() && mod.SlotData.ExcludedBonuses.Find(DeathWish) != -1)
		{
			DeathWish.static.ForceUnlockObjective(1);
			DeathWish.static.ForceUnlockObjective(2);
			
			if (mod.SlotData.BonusRewards && mod.SlotData.CheckedLocations.Find(locId+1) == -1)
			{
				locIds.AddItem(locId+1);
			}
		}
	}
	else if (mod.SlotData.DeathWishShuffle)
	{
		UnavailableDWCache.AddItem(DeathWish);
	}
	
	if (locIds.Length > 0)
	{
		mod.SendMultipleLocationChecks(locIds);
	}
	
	return result;
}

function bool IsRequestingStamps(class<Hat_SnatcherContract_DeathWish> DeathWish, optional bool UseTargetValue = false)
{
	if (mod.SlotData.DeathWishShuffle)
		return false;
	
	return Super.IsRequestingStamps(DeathWish, UseTargetValue);
}

function bool IsDeathWishCompleted(class<Hat_SnatcherContract_DeathWish> DeathWish, optional bool UseTargetValue = false)
{
	if (mod.SlotData.DeathWishShuffle)
		return true;

	return Super.IsDeathWishCompleted(DeathWish, UseTargetValue);
}

function ForceUpdateIcons()
{
	local int i, index;
	local Hat_DeathWishIcon icon;
	local DeathWishParent p;
	
	for (i = 0; i < DeathWishes.Length; i++)
	{
		index = mod.slotData.ShuffledDeathWishes.Find(DeathWishes[i].DeathWish);
		if (index == -1)
		{
			DeathWishes[i].IsHidden = true;
			continue;
		}
		
		icon = GetIcon(DeathWishes[i].DeathWish);
		if (IconCache.Find(icon) == -1)
		{
			DeathWishes[i].Parents.Length = 0;
			if (index > 0)
			{
				p.Icon = GetIcon(mod.slotData.ShuffledDeathWishes[index-1]);
				p.LineInstance = new class'MaterialInstanceConstant';
				p.LineInstance.SetParent(icon.DeathWishParentLine);
				DeathWishes[i].Parents.AddItem(p);
			}
			
			IconCache.AddItem(icon);
		}
		
		DeathWishes[i].IsHidden = (AvailableDWCache.Find(DeathWishes[i].DeathWish) == -1);
	}
}

function SetDeathWishNew(class<Hat_SnatcherContract_DeathWish> DeathWish, optional bool b = true)
{
	if (!mod.SlotData.DeathWishShuffle)
	{
		Super.SetDeathWishNew(DeathWish, b);
		return;	
	}
	
	if (b && !IsDeathWishAttempted(DeathWish))
		class'Hat_SaveBitHelper'.static.AddLevelBit(DeathWish.static.GetObjectiveBitID()$"_MenuNew", 1, `GameManager.HubMapName);
	else
		class'Hat_SaveBitHelper'.static.RemoveLevelBit(DeathWish.static.GetObjectiveBitID()$"_MenuNew", 1, `GameManager.HubMapName);
}