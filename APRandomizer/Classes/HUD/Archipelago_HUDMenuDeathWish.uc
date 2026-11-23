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
	
	StampString = NumStamps $ " / " $ TotalStamps;
	if (mod.SlotData.DeathWishShuffle)
	{
		StampString $= " (" $ string(mod.SlotData.ShuffledDeathWishes.Length) $ ")";
	}
	
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

function bool IsDeathWishAvailable(class<Hat_SnatcherContract_DeathWish> DeathWish, optional bool UseTargetValue = false)
{
	local bool result, itemUnlock;
	local int locId, index;
	local array<int> locIds;
	local class<Hat_SnatcherContract_DeathWish> prevDw;
	if (DeathWish.default.TimedEvent != ETimedEvent_None)
	{
		// ignore event death wishes
		return false;
	}
	
	// for death wish unlocks, the item id is the same
	locId = class'Archipelago_ItemInfo'.static.GetDeathWishLocationID(DeathWish);
	if (locId <= 0)
		return false;
	
	if (mod.SlotData.LockDeathWishes > 0)
	{
		if (mod.SlotData.DeathWishShuffle)
		{
			if (mod.SlotData.LockDeathWishes == 1)
			{
				// Progressive mode
				index = mod.SlotData.ShuffledDeathWishes.Find(DeathWish);
				if (index == -1 || mod.GetAPBits("ProgressiveDeathWish") < index+1)
				{
					return false;
				}
			}
			else
			{
				itemUnlock = true;
			}
		}
		else
		{
			itemUnlock = true;
		}
	}
	
	if (itemUnlock && mod.GetAPBits("DeathWishUnlocked_"$locId) == 0)
	{
		return false;
	}
	
	if (mod.SlotData.DeathWishShuffle && mod.SlotData.LockDeathWishes != 2)
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
	else if (!mod.SlotData.DeathWishShuffle)
	{
		// use vanilla dw map rules
		result = Super.IsDeathWishAvailable(DeathWish, UseTargetValue);
	}
	else
	{
		// this means we're in open shuffle mode, so the only thing blocking us would be unlock items
		result = true;
	}
	
	if (result)
	{
		if (mod.SlotData.DeathWishShuffle)
			AvailableDWCache.AddItem(DeathWish);
		
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

function Vector GetDeathWishHUDPosition(HUD H, class<Hat_SnatcherContract_DeathWish> DeathWish)
{
	local class<Hat_SnatcherContract_DeathWish> dw;
	local int count;
	local float x, y;
	x = -0.8;
	y = -0.5;
	if (mod.SlotData.DeathWishShuffle)
	{
		foreach mod.SlotData.ShuffledDeathWishes(dw)
		{
			if (count > 0)
			{
				if (count % 12 == 0)
				{
					y += 0.18;
					x = -0.8;
				}
				else
				{
					x += 0.15;
				}
			}
			
			count++;
			if (dw == DeathWish)
			{
				return ConvertPosToScreenSpace(x, y);
			}
		}
	}
	
	return Super.GetDeathWishHUDPosition(H, DeathWish);
}

// Non-screenspace
function Vector2D GetDeathWishHUDPosition2(HUD H, class<Hat_SnatcherContract_DeathWish> DeathWish)
{
	local class<Hat_SnatcherContract_DeathWish> dw;
	local int count;
	local float x, y;
	x = -0.8;
	y = -0.5;
	if (mod.SlotData.DeathWishShuffle)
	{
		foreach mod.SlotData.ShuffledDeathWishes(dw)
		{
			if (count > 0)
			{
				if (count % 12 == 0)
				{
					y += 0.18;
					x = -0.8;
				}
				else
				{
					x += 0.15;
				}
			}
			
			count++;
			if (dw == DeathWish)
			{
				return vect2d(x, y);
			}
		}
	}
	
	return DeathWish.static.GetUIPos();
}

function bool OnClick(HUD H, bool release)
{
	local bool NewState;
	local Array<string> ObjectiveWorkshopRemoteIDs;
	local bool bInstallAny;
	
	IsHoldingClick = !release;

	if (!CanControl(H))
		return false;
	if (release) return false;
	
	// Toggle active
	if (SelectedDeathWish != None)
	{
		if (SelectedDeathWish.DeathWish != None && (SelectedDeathWish.DeathWish.static.IsHidden() || !SelectedDeathWish.DeathWish.static.IsOnlineItemAvailable() || !SelectedDeathWish.DeathWish.static.ConsiderForDeathWishTotal()))
		{
			CameraShake = 0.4;
			PlayOwnerSound(H, ErrorSound);
			return false;
		}
		
		if (CanClaimCompletionReward(SelectedDeathWish))
		{
			// Requires workshop mods for reward
			if (SelectedDeathWish.DeathWish.default.RewardWorkshopRemoteIDs.Length > 0)
			{
				SelectedDeathWish.UpdateDownloadState();
				if (SelectedDeathWish.RequiresDownloadingRewardContent && InstallMods(H, 'Reward'))
				{
					PlayOwnerSound(H, SelectDeathWishSound);
					bActivateOnInstall = true;
					SelectedDeathWish.UpdateDownloadState();
					return true;
				}
			}
			
			if (AwardRewardDeathWish == None && mod.SlotData.ObtainedDeathWishRewards.Find(SelectedDeathWish.DeathWish) == -1)
			{
				if (SelectedDeathWish.DeathWish.default.CompletionReward != None || SelectedDeathWish.DeathWish.default.RewardWorkshopRemoteIDs.Length > 0)
				{
					SelectedDeathWish.Animation = PlayIconAnimation(SelectedDeathWish, class'Hat_HUDDeathWishAnimation_RewardGet');
					AwardRewardDeathWish = SelectedDeathWish;
					return false;
				}
			}
		}

		if (IsLockedByCompletion(SelectedDeathWish))
		{
			CameraShake = 0.4;
			PlayOwnerSound(H, ErrorSound);
			return false;
		}

		if (IsActIncomplete(SelectedDeathWish) && !DebugMakeAllAvailable)
		{
			CameraShake = 0.4;
			PlayOwnerSound(H, ErrorSound);
			DoSnatcherTip(H, class'Hat_Localizer'.static.Localize("DeathWishMap", "TimePieceLocked", "sequences/snatcher_deathwish"));
			return false;
		}
		
		// Requires selecting user choices
		if (SelectedDeathWish.DeathWish != None && SelectedDeathWish.DeathWish.static.GetNumRemainingUserChoices() > 0)
		{
			if (OnDeathWishUserChoiceRequested(H, 'FirstAvailableChoice', SelectedDeathWish))
			{
				PlayOwnerSound(H, SelectDeathWishSound);
				return true;
			}			
		}
		
		// Requires workshop mods for objective
		if (SelectedDeathWish.DeathWish != None)
			ObjectiveWorkshopRemoteIDs = SelectedDeathWish.DeathWish.static.GetObjectiveWorkshopRemoteIDs();
		if (ObjectiveWorkshopRemoteIDs.Length > 0)
		{
			if (!class'Hat_SeqCond_SupportsModding'.static.HasModdingSupport(true))
			{
				// No modding support, can't activate
				CameraShake = 0.4;
				PlayOwnerSound(H, ErrorSound);
				return false;
			}
			SelectedDeathWish.UpdateDownloadState();
			if (SelectedDeathWish.RequiresDownloadingObjectiveContent || SelectedDeathWish.RequiresDownloadingObjectiveContent)
			{
				if (SelectedDeathWish.IsDownloadingContent)
					return false;
				bInstallAny = false;
				if (InstallMods(H, 'Objective'))
					bInstallAny = true;
				if (InstallMods(H, 'Optional'))
					bInstallAny = true;
				if (bInstallAny)
				{
					PlayOwnerSound(H, SelectDeathWishSound);
					bActivateOnInstall = true;
					SelectedDeathWish.UpdateDownloadState();
					return true;
				}
			}
		}

		NewState = !SelectedDeathWish.IsActive;

		if (SelectedDeathWish.IsLockedOut)
		{
			if (SelectedDeathWish.WaitTime > 0)
				return false;
			if (SelectedDeathWish.CanClearLockOut())
				PlayIconAnimation(SelectedDeathWish, class'Hat_HUDDeathWishAnimation_Unlock');
			else
				PlayOwnerSound(H, ErrorSound);

			return true;
		}
		else if (NewState)
		{
			if (SelectedDeathWish.CanJumpToMap())
				SetMouseHidden(H, true);

			PlayIconAnimation(SelectedDeathWish, class'Hat_HUDDeathWishAnimation_Stamper');

			SetDeathWishAttempted(SelectedDeathWish.DeathWish, true);
			bActiveDeathWishesChanged = true;
		}
		else if (!IsLoadingMap)
		{
			SelectedDeathWish.SetActive(H, false);
			PlayOwnerSound(H, DeactivateSound);
			CameraShake = 0.4f;
			bActiveDeathWishesChanged = true;
		}
		return true;
	}
	else if (HoverDeathWish != None)
	{
		if (HoverDeathWish.HasEnoughStamps)
		{
			HoverDeathWish.DoStampUnlock();
			if (!IsGamePad(H))
				HoverDeathWish = None;
			return true;
		}

		if (!DebugMakeAllAvailable && !DebugShowHidden && (HoverDeathWish.IsLockedOut || !HoverDeathWish.IsAvailable))
		{
			PlayOwnerSound(H, ErrorSound);
			return true;
		}
		
		if (HoverDeathWish.OnClick(H, release))
			return true;
		
		PlayOwnerSound(H, SelectDeathWishSound);
		SelectedDeathWish = HoverDeathWish;
		if (!SelectedDeathWish.IsMainCompleted)
			TimeUntilTip = SelectedDeathWish.IsAttempted ? 3.0 : 7.0;
		if (SelectedDeathWish != None)
		{
			LastSelectedDeathWish = SelectedDeathWish;
			if (SelectedDeathWish.DeathWish != None)
				SelectedDeathWishPos = GetDeathWishHUDPosition2(H, SelectedDeathWish.DeathWish);
			else
			{
				SelectedDeathWishPos.X = SelectedDeathWish.Position.X;
				SelectedDeathWishPos.Y = SelectedDeathWish.Position.Y;
			}
		}
		SelectedDeathWish.UpdateDownloadState();
		return true;
	}
	return Super.OnClick(H, release);
}

function bool Tick(HUD H, float d)
{
	local Hat_DeathWishIcon icon;
	local int i;
	local bool DoSpeedUp, CheckForMoreAnims;
	local float prev;
	
	if (!IsEnabled()) return false;
	if (H.PlayerOwner == None) return false;
	
	if (IntroOutro > IntroOutroTarget)
	{
		IntroOutro = FMax(IntroOutroTarget, IntroOutro - d/OutroTime);
		if (IntroOutro == 0)
			Super.CloseHUD(H, Class);
	}
	else if (IntroOutro < IntroOutroTarget)
		IntroOutro = FMin(IntroOutroTarget, IntroOutro + d/IntroTime);

	if (!IsLoadingMap && IsInEasyModeMenu < 0)
		ReactivateMouseCheck(H);
	
	if (IsGamePad(H) && UseGamepadCursor)
	{
		ControllerMousePosition.X += H.PLayerOwner.PlayerInput.RawJoyRight *0.4*d;
		ControllerMousePosition.Y -= H.PLayerOwner.PlayerInput.RawJoyUp *0.4*d;
		ControllerMousePosition.X = FClamp(ControllerMousePosition.X, 0, 1);
		ControllerMousePosition.Y = FClamp(ControllerMousePosition.Y, 0, 1);
	}
	else if (SelectedDeathWish == None)
		SelectInGamepadDirection(H);
	
	if (EasyModeReminder > 0)
		EasyModeReminder -= d/1.5;
	
	if (SelectedDeathWish != None)
	{
		if (ZoomAlpha < 1.f)
		{
			prev = ZoomAlpha;
			ZoomAlpha = FMin(ZoomAlpha+d/ZoomTime, 1.f);
			if (ZoomAlpha >= 1.f
			&& prev < 1.f
			&& EasyModeReminder <= 0
			&& SelectedDeathWish.DeathWish != None
			&& SelectedDeathWish.DeathWish.static.IsEasyModeAvailable() != INDEX_NONE
			&& SelectedDeathWish.DeathWish.static.ConditionalRemindEasyMode())
			{
				EasyModeReminder = 1;
			}
			// only unobscure when revisited on the map screen
			if (ZoomAlpha >= 1.f && prev < 1.f && SelectedDeathWish.DeathWish != None && SelectedDeathWish.DeathWish.static.TryUnobscureDeathwish())
			{
				PlayOwnerSound(H, ObjectiveUnlockSound);
				UnobscureProgress = 1;
			}
		}
	}
	else if (FocusAnimDeathWish != None)
	{
		ZoomAlpha = FMax(ZoomAlpha-d/(ZoomTime*0.85f), 0.65f);
	}
	else
	{
		ZoomAlpha = FMax(ZoomAlpha-d/(ZoomTime*0.75f), 0.f);
	}
	
	if (CameraShake > 0)
		CameraShake -= d/0.2f;
	
	if (ShouldShowCurrencyCounter())
	{
		CurrencyFadeIn = FMin(CurrencyFadeIn + d*5.f, 1.0f);
	}
	else
	{
		CurrencyFadeIn = FMax(CurrencyFadeIn - d*5.f, 0.0f);
	}

	if (CurrencyError >= 0)
	{
		CurrencyError += d;
		if (CurrencyError >= 1.0f)
			CurrencyError = -1.f;
	}

	for (i = 0; i < DeathWishes.length; i++)
	{
		DeathWishes[i].Tick(d);
	}

	CheckForMoreAnims = Animations.length > 0;

	while (Animations.length > 0)
	{
		DoSpeedUp = IsHoldingClick && Animations[0].CanBeSpedUp;

		/*if (SelectedDeathWish == None && Animations[0].Progress >= 0.2f && Animations[0].PrevProgress < 0.2f)
		{
			FocusAnimDeathWish = Animations[0].Icon;
			SelectedDeathWishPos.X = Animations[0].Icon.GetUIPos().X;
			SelectedDeathWishPos.Y = Animations[0].Icon.GetUIPos().Y;
		}
		else if (FocusAnimDeathWish != None && Animations[0].Progress >= 1.5f && Animations[0].PrevProgress < 1.5f)
		{
			LastFocusAnimDeathWish = FocusAnimDeathWish;
			FocusAnimDeathWish = None;
		}*/
		
		if (Animations[0].Tick(H, d * (DoSpeedUp ? 4.f : 1.f)))
			Animations.Remove(0, 1);
		else
			break;
	}

	if (Animations.length == 0 && CheckForMoreAnims)
	{
		if (AwardRewardDeathWish != None && AwardRewardDeathWish.DeathWish != None && mod.SlotData.ObtainedDeathWishRewards.Find(AwardRewardDeathWish.DeathWish) == -1)
		{
			AwardRewardDeathWish.DeathWish.static.AwardReward(H.PlayerOwner, false, true);
			GiveModReward(H, 'Reward');
			mod.SlotData.ObtainedDeathWishRewards.AddItem(AwardRewardDeathWish.DeathWish);
			mod.SendLocationCheck(class'Archipelago_ItemInfo'.static.GetDeathWishLocationID(AwardRewardDeathWish.DeathWish) + class'Archipelago_GameMod'.const.DWRewardIDOffset);
			AwardRewardDeathWish.RewardObtained = true;
			AwardRewardDeathWish = None;
		}

		CountStamps();

		class'Hat_DeathWishIcon'.static.TriggerAllAnimations(self);

		// validate if animations are finishing up
		DidPostAnimationValidation = false;
	}

	// update everything after animations are finished to fix any bugs that may have occurred.
	if (Animations.length == 0 && !DidPostAnimationValidation)
	{
		// delay finalization until after manual stamp unlock animations are finished.
		if (!IsMenuWaitingForStampUnlock())
			class'Hat_DeathWishIcon'.static.FinalizeAnimations(self);

		if (DeathWishes.Length > 0 && DeathWishes[0].DeathWish != None)
			DeathWishes[0].DeathWish.static.PrepareGratz();
		if (!DebugAlwaysShowComplete)
			PlayAllDoneAnimation();

		DidPostAnimationValidation = true;
	}
	
	if (AutoSnatcherTips && !IsActIncomplete(SelectedDeathWish) && !IsLoadingMap)
	{
		if (SelectedDeathWish != None && SelectedDeathWish.DeathWish != None && !SelectedDeathWish.DeathWish.static.IsContractComplete() && SelectedDeathWish.DeathWish.default.TipLocalizedMessage != "" && EasyModeReminder <= 0)
		{
			prev = InTipAlpha;
			InTipAlpha += d;
			if (TimeUntilTip > 0 && prev < TimeUntilTip && InTipAlpha >= TimeUntilTip)
				DoSnatcherTip(H);
		}
		else
			InTipAlpha = 0;
	}
	else
	{
		if (IsInTip)
			InTipAlpha = FMin(InTipAlpha+d/0.2,1);
		else
			InTipAlpha = FMax(InTipAlpha-d/0.2,0);
	}
	
	if (IsInEasyModeMenu >= 0)
	{
		if (EasyModeFadeOut)
		{
			IsInEasyModeMenu = FMax(IsInEasyModeMenu-d/0.3, 0);
			if (IsInEasyModeMenu <= 0)
				IsInEasyModeMenu = -1;
		}
		else
			IsInEasyModeMenu = FMin(IsInEasyModeMenu+d/0.3, 1);
	}

	if (UnobscureProgress > 0)
		UnobscureProgress = FMax(0, UnobscureProgress-d/0.8);

	if (bActivateOnInstall && ActivateOnInstallFrameDelay > 0)
	{
		ActivateOnInstallFrameDelay--;
		if (ActivateOnInstallFrameDelay <= 0)
		{
			OnModInstalledDelayed(H);
		}
	}
	
	if (LeaderboardHUD != None)
	{
		LeaderboardHUD.Opacity = FClamp(1.f - (ZoomAlpha/0.2f), 0.f, 1.f);
	}
	
	if (mod.SlotData.DeathWishShuffle)
	{
		ForceUpdateIcons();
	}
	
	foreach DeathWishes(icon)
	{
		if (!icon.RewardObtained && icon.DeathWish != None && mod.SlotData.ObtainedDeathWishRewards.Find(icon.DeathWish) != -1)
		{
			icon.RewardObtained = true;
		}
	}

	return true;
}
