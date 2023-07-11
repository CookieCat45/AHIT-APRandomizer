class Archipelago_HUDMenuActSelect extends Hat_HUDMenuActSelect;

`include(APRandomizer\Classes\Globals.uci);

simulated function BuildActs(HUD H)
{
	local int i,j, InventoryIndex, actid, total_num, basement, context;
	local float angle, angle_radians;
	local Array<Hat_ChapterActInfo> UnlockedActIDs;
	local Array< class<Inventory> > InventoryClasses;
	local MenuSelectHourglass s;
	local Hat_ChapterActInfo shuffledAct;
	
	UnlockedActIDs = GetUnlockedActIDs(ChapterInfo,, ModChapterPackageName);
	// Remove act 99 since its already going to be present as free roam if actless
	if (ChapterInfo.IsActless)
	{
		for (i = UnlockedActIDs.Length-1; i >= 0; i--)
		{
			if (UnlockedActIDs[i].ActID != 99 && (ChapterInfo.ActIDAfterIntro <= 0 || UnlockedActIDs[i].ActID != ChapterInfo.ActIDAfterIntro)) continue;
			UnlockedActIDs.Remove(i,1);
		}
	}
	
	if (UnlockedActIDs.Length == 0) return;

	if (ChapterInfo.FinaleActID > 0)
	{
		for (i = 0; i < UnlockedActIDs.Length; i++)
		{
			if (UnlockedActIDs[i].ActID != ChapterInfo.FinaleActID) continue;
			UnlockedActIDs.Remove(i,1);
			break;
		}
	}
	angle = 0;
	for (j = 0; j < UnlockedActIDs.Length; j++)
	{
		i = UnlockedActIDs[j].ActID;
		s.StandoffOffset = 0;
		s.IsUncanny = false;
		s.IsMissingItem = false;
		
		if (IsActiveStandoff)
		{
			if (i <= 1)
			{
				s.PosX = IconsCenterLocation.X;
				s.PosY = IconsCenterLocation.Y + 0.3;
				
				// This will lock the player out of Act 1, big no no
				//s.IsUncanny = class'Hat_GameManager'.static.IsChapterUncannyFinaleEnabled(ChapterInfo);
			}
			else
			{
				s.StandoffOffset = ((i-2) % 2 == 0) ? -1 : 1;
				s.PosX = IconsCenterLocation.X + s.StandoffOffset*0.1;
				s.PosY = IconsCenterLocation.Y + 0.2 - ((i-2)/2)*0.2;
			}
		}
		else if (UnlockedActIDs.Length == 2 && !ChapterInfo.IsActless)
		{
			s.PosX = IconsCenterLocation.X + (Planet_Radius*0.3 * (j == 0 ? -1 : 1));
			s.PosY = IconsCenterLocation.Y + 0.05;
		}
		else if (j == 0 && !ChapterInfo.IsActless)
		{
			s.PosX = IconsCenterLocation.X;
			s.PosY = IconsCenterLocation.Y + 0.05;
		}
		else
		{
			total_num = UnlockedActIDs.Length-1;
			if (ChapterInfo.IsActless)
				total_num = UnlockedActIDs.Length;
			angle += 360.0 / float(total_num);
			angle_radians = angle*2.0*Pi/360.0;
			
			s.PosX = IconsCenterLocation.X + sin(angle_radians)*Planet_Radius*0.58;
			s.PosY = IconsCenterLocation.Y + 0.05 + cos(angle_radians)*Planet_Radius;
		}
		
		s.Hourglass =  ChapterInfo.GetActHourglass(i);
		s.ID = ActSelectType_Act;
		
		if (ChapterInfo.IsActBigBoss(i) || ChapterInfo.IsActMiniBoss(i))
			s.ID = ActSelectType_Boss;
		
		s.IsUnlocked = true;
		s.ChapterActInfo = UnlockedActIDs[j];
        s.IsComplete = `AP.IsActReallyCompleted(s.ChapterActInfo);
		
		if (`AP.SlotData.ActRando)
		{
			if (ChapterInfo.ChapterID == 2 && s.ActID == 6 && `AP.IsAwardCeremonyCompleted())
			{
				shuffledAct = `AP.GetDeadBirdBasementShuffledAct();
			}
			else
			{
				shuffledAct = `AP.GetShuffledAct(s.ChapterActInfo, basement);
			}
		}
		else
		{
			shuffledAct = s.ChapterActInfo;
		}
		
		context = shuffledAct.IsBonus ? 1 : `AP.IsActFreeRoam(shuffledAct) ? 2 : 0;
		
		s.ActInfoboxName = basement == 0 ? GetLocalizedActName(shuffledAct, context) : 
			GetLocalizedActName(Hat_ChapterActInfo(DynamicLoadObject(
				"hatintime_chapterinfo.BattleOfTheBirds.BattleOfTheBirds_AwardCeremony", class'Hat_ChapterActInfo')), 0);
		
		if (ChapterInfo.IsActless)
		{
			s.ActInfoboxTitle = (ChapterInfo.ActlessPrefix != "") ? class'Hat_Localizer'.static.GetSystem("levels", ChapterInfo.ActlessPrefix) : "";
		}
		else
		{
			s.ActInfoboxTitle = class'Hat_Localizer'.static.GetSystem("levels", "Act") $ " " $ i;
		}
		s.ActDisplayLabel = s.ActInfoboxName;
			
		s.PlanetRotation = ChapterInfo.GetActPlanetRotation(i);
		s.IsDefault = (j == 0);
		s.Photo = None;
		actid = ChapterInfo.GetActIDFromHourglass(s.Hourglass);
		s.MapName = ChapterInfo.GetActMap(actid, s.IsComplete);
		s.ActID = actid;
		
		InventoryClasses = shuffledAct.RequiredItems;
		s.IsMissingItem = false;
		s.SupportsCoop = ChapterInfo.GetSupportsCoop(s.Hourglass);
		if (InventoryClasses.Length > 0 && !s.IsComplete)
		{
			for (InventoryIndex = 0; InventoryIndex < InventoryClasses.Length; InventoryIndex++)
			{
				if (Hat_PlayerController(H.PlayerOwner).GetLoadout().BackpackHasInventory(InventoryClasses[InventoryIndex], true)) continue;
				s.IsMissingItem = true;
				break;
			}
		}
		
		s.Highscore = GetTimePieceHighscore(s.Hourglass);
			
		s.PonPayCost = 0;
		s.DeathWishPayCost = 0;
		if (!s.IsComplete && !HasPaidTimePiece(s.Hourglass))
		{
			s.PonPayCost = ChapterInfo.GetActOrbCost(actid);
			s.DeathWishPayCost = ChapterInfo.GetActDeathWishCost(actid);
		}
		s.RenderPriority = ChapterInfo.GetActRenderPriority(actid);
		
		if (s.IsComplete && 
			((GetWorldInfo().Role == Role_Authority && !class'Hat_SaveBitHelper'.static.HasLevelBit("ActSelectAnimation_Complete_"$GetChapterBitID(), i))))
		{
			s.SpecialAnimation = class'Hat_HUDActSelectAnimation_CompleteAct';
			if (GetWorldInfo().Role == Role_Authority)
				class'Hat_SaveBitHelper'.static.AddLevelBit("ActSelectAnimation_Complete_"$GetChapterBitID(), i);
		}
		else if (!s.IsComplete &&
					((GetWorldInfo().Role == Role_Authority && !class'Hat_SaveBitHelper'.static.HasLevelBit("ActSelectAnimation_Unlock_"$GetChapterBitID(), i))))
		{
			s.SpecialAnimation = class'Hat_HUDActSelectAnimation_UnlockAct';
			if (GetWorldInfo().Role == Role_Authority)
				class'Hat_SaveBitHelper'.static.AddLevelBit("ActSelectAnimation_Unlock_"$GetChapterBitID(), i);
		}
		else
			s.SpecialAnimation = None;
		s.IsValid = true;

		Hourglasses.AddItem(s);
	}
	
	DesiredPlanetRotation = Hourglasses[0].PlanetRotation;
	UpdatePlanetRotation(1);
}

simulated function SetChapterInfo(HUD H, Hat_ChapterInfo i, optional String InModChapterPackageName)
{
	local Hat_DynamicStaticActor sa;

	local Array<Hat_ChapterActInfo> UnlockedActIDs;
	ChapterInfo = i;
	ModChapterPackageName = InModChapterPackageName;
	
	UnlockedActIDs = GetUnlockedActIDs(ChapterInfo,,ModChapterPackageName);
	
	IsActiveStandoff = ChapterInfo.IsStandoff && UnlockedActIDs.Length > 1;
	
	if (IsActiveStandoff)
	{
		IconsCenterLocation.X = 0.5f;
		IconsCenterLocation.Y = 0.4f;
	}
	BuildHourglasses(H);
	
	if (ActSelectStandoffEmitter != None)
		ActSelectStandoffEmitter.ParticleSystemComponent.SetActive(IsActiveStandoff);
	
	UpdateColorSchemes(H);
	if (IsActiveStandoff)
		UpdateStandoffPoints(H);

	if (PlanetActor != None)
		PlanetActor.SetHidden(ChapterInfo.HasLavaPlanet);

	foreach GetWorldInfo().AllActors(class'Hat_DynamicStaticActor',sa)
	{
		if (sa.Tag == 'ActSelectLavaPlanetActor')
		{
			sa.SetHidden(!ChapterInfo.HasLavaPlanet);
			break;
		}
	}
}

function Array<Hat_ChapterActInfo> GetUnlockedActIDs(Hat_ChapterInfo ci, optional bool IncludePreviewFinale = false, optional string ModPackageName, optional bool bShouldSort)
{
	local Array<Hat_ChapterActInfo> UnlockedActIDs;
	local int i, actid;
	local bool ChapterFinaleIsUnlocked;
	local Hat_ChapterActInfo FinaleChapterActInfo;
	
	ChapterFinaleIsUnlocked = false;
	UnlockedActIDs.Length = 0;
	FinaleChapterActInfo = None;
	ci.ConditionalUpdateActList();
	for (i = 0; i < ci.ChapterActInfo.Length; i++)
	{
		if (ci.ChapterActInfo[i].IsBonus) continue;
		
		// Finale act should show up even if its not complete
		if (ci.FinaleActID == actid)
			FinaleChapterActInfo = ci.ChapterActInfo[i];
		
		if (!`AP.IsChapterActInfoUnlocked(ci.ChapterActInfo[i], ModPackageName)) continue;
		UnlockedActIDs.AddItem(ci.ChapterActInfo[i]);
		actid = ci.ChapterActInfo[i].ActID;
		if (ci.FinaleActID == actid) ChapterFinaleIsUnlocked = true;
	}
	
	if (IncludePreviewFinale && FinaleChapterActInfo != None && ci.FinaleActID > 0 && UnlockedActIDs.Length > 1 && !ChapterFinaleIsUnlocked)
	{
		// always show up
		UnlockedActIDs.AddItem(FinaleChapterActInfo);
	}
	
	if (bShouldSort)
		UnlockedActIDs.Sort(SortChapterActInfoByActID);
	
	return UnlockedActIDs;
}

// Makes the assumption both ChapterActInfo are from the same ChapterInfo
function int SortChapterActInfoByActID(Hat_ChapterActInfo a, Hat_ChapterActInfo b)
{
	local int AdjustedActIDA, AdjustedActIDB;
	local Hat_ChapterInfo ci;
	
	AdjustedActIDA = a.ActID;
	AdjustedActIDB = b.ActID;
	
	ci = a.ChapterInfo;
	if (ci != None)
	{
		if (a.ActID == ci.FinaleActID) AdjustedActIDA = 999; // finale is always last
		if (b.ActID == ci.FinaleActID) AdjustedActIDB = 999; // finale is always last
		
		if (a.ActID == 99) AdjustedActIDA = -2; // free roam is always first
		if (b.ActID == 99) AdjustedActIDB = -2; // free roam is always first
		
		if (ci.ActIDAfterIntro > 0)
		{
			if (a.ActID == ci.ActIDAfterIntro) AdjustedActIDA = -1; // ActIDAfterIntro is right after free roam in the list
			if (b.ActID == ci.ActIDAfterIntro) AdjustedActIDB = -1; // ActIDAfterIntro is right after free roam in the list
		}
	}
	
	return AdjustedActIDB-AdjustedActIDA;
}

simulated function BuildSpecialHourglasses(HUD H)
{
	local MenuSelectHourglass s;
	local MaterialInterface minf;
	local MaterialInstanceConstant matinst;
	local int FinaleFillBit, TotalRequired, CompletedRequiredActsLength, i, basement, context;
	local float finalefill;
	local bool HasFinale, HasFreeRoam;
	local Hat_ChapterActInfo shuffledAct;
	
	HasFreeRoam = false;
	if (!class'Hat_SeqCond_HasUntouchedChapter'.static.IsUntouched(ChapterInfo, 4, false) && ChapterInfo.HasFreeRoam)
		HasFreeRoam = true;
	
	if (GetFinaleInfo(H, TotalRequired, CompletedRequiredActsLength))
	{
		HasFinale = true;
		
		s.ID = ActSelectType_Finale;
		s.PosX = IconsCenterLocation.X + (HasFreeRoam ? 0.07 : 0.0);
		s.PosY = IconsCenterLocation.Y - (bHasActiveBlockingFinale ? 0.f : (IsActiveStandoff ? 0.2 : (ChapterInfo.ChapterID == 6 ? 0.2 : 0.4)));
		s.Hourglass = ChapterInfo.GetActHourglass(ChapterInfo.FinaleActID);		
		s.ActInfoboxTitle = "";
		s.ActInfoboxName = "";
		s.ActDisplayLabel = "";
		s.IsDefault = false;
		s.PonPayCost = 0;
		s.DeathWishPayCost = 0;
		s.ActID = ChapterInfo.FinaleActID;
		s.PlanetRotation = ChapterInfo.GetActPlanetRotation(ChapterInfo.FinaleActID);
		s.SupportsCoop = ChapterInfo.GetSupportsCoop(s.Hourglass);
		
		s.ChapterActInfo = None;
		ChapterInfo.ConditionalUpdateActList();
		for (i = 0; i < ChapterInfo.ChapterActInfo.Length; i++)
			if (!ChapterInfo.ChapterActInfo[i].IsBonus && ChapterInfo.ChapterActInfo[i].ActID == s.ActID)
			{
				s.ChapterActInfo = ChapterInfo.ChapterActInfo[i];
				break;
			}
			
		if (s.ChapterActInfo != None && s.ChapterActInfo.ActIDBeforeComplete > 0 && !s.IsComplete)
		{
			s.ActID = s.ChapterActInfo.ActIDBeforeComplete;
			// Update the ChapterActInfo as well
			for (i = 0; i < ChapterInfo.ChapterActInfo.Length; i++)
				if (!ChapterInfo.ChapterActInfo[i].IsBonus && ChapterInfo.ChapterActInfo[i].ActID == s.ActID)
				{
					s.ChapterActInfo = ChapterInfo.ChapterActInfo[i];
					break;
				}
		}
		
		s.IsComplete = `AP.IsActReallyCompleted(s.ChapterActInfo);
		
		if (IsActiveStandoff &&
			HasTimePiece(ChapterInfo.GetActHourglass(s.ActID)) &&
			HasTimePiece(ChapterInfo.GetActHourglass(s.ActID, true)) )
		{
			s.MapName = ChapterInfo.GetActMap(1, s.IsComplete);
		}
		else
			s.MapName = ChapterInfo.GetActMap(s.ActID, s.IsComplete);
		

		FinaleFillBit = class'Hat_SaveBitHelper'.static.GetLevelBits("ActSelectAnimation_FinaleFill_" $ GetChapterBitID());
		
		if (TotalRequired > 0)
			finalefill = float(FinaleFillBit) / float(TotalRequired);
		else
			finalefill = 1;
		
		if (s.IsComplete)
		{
			s.SpecialAnimation = None;
			if (GetWorldInfo().Role == Role_Authority && !class'Hat_SaveBitHelper'.static.HasLevelBit("ActSelectAnimation_Complete_"$GetChapterBitID(), s.ActID))
			{
				s.SpecialAnimation = class'Hat_HUDActSelectAnimation_CompleteAct';
				if (GetWorldInfo().Role == Role_Authority)
					class'Hat_SaveBitHelper'.static.AddLevelBit("ActSelectAnimation_Complete_"$GetChapterBitID(), s.ActID);
			}
		}
		else if (GetWorldInfo().Role == Role_Authority && !class'Hat_SaveBitHelper'.static.HasLevelBit("ActSelectAnimation_Unlock_" $ GetChapterBitID(), ChapterInfo.FinaleActID))
		{
			s.SpecialAnimation = class'Hat_HUDActSelectAnimation_UnlockAct';
			
			class'Hat_SaveBitHelper'.static.AddLevelBit("ActSelectAnimation_Unlock_" $ GetChapterBitID(), ChapterInfo.FinaleActID);
			class'Hat_SaveBitHelper'.static.SetLevelBits("ActSelectAnimation_FinaleFill_" $ GetChapterBitID(), CompletedRequiredActsLength);
			
			s.TargetFinaleFill[0] = finalefill;
			s.TargetFinaleFill[1] = float(CompletedRequiredActsLength) / float(TotalRequired);
			s.AdditionalSpecialAnimations = 2;
		}
		else if (FinaleFillBit != CompletedRequiredActsLength && TotalRequired > 0)
		{
			s.SpecialAnimation = class'Hat_HUDActSelectAnimation_FillFinale';
			
			class'Hat_SaveBitHelper'.static.SetLevelBits("ActSelectAnimation_FinaleFill_" $ GetChapterBitID(), CompletedRequiredActsLength);
			
			s.TargetFinaleFill[0] = finalefill;
			s.TargetFinaleFill[1] = float(CompletedRequiredActsLength) / float(TotalRequired);
		}
		else
			s.SpecialAnimation = None;
		
		s.IsValid = true;
		s.IsUnlocked = CompletedRequiredActsLength >= TotalRequired;
		
		if (`AP.SlotData.ActRando)
		{
			if (ChapterInfo.ChapterID == 2 && s.ActID == 6 && `AP.IsAwardCeremonyCompleted())
			{
				shuffledAct = `AP.GetDeadBirdBasementShuffledAct();
			}
			else
			{
				shuffledAct = `AP.GetShuffledAct(s.ChapterActInfo, basement);
			}
		}
		else
		{
			shuffledAct = s.ChapterActInfo;
		}
		
		context = shuffledAct.IsBonus ? 1 : `AP.IsActFreeRoam(shuffledAct) ? 2 : 0;
		
		s.ActInfoboxName = basement == 0 ? GetLocalizedActName(shuffledAct, context) : 
			GetLocalizedActName(Hat_ChapterActInfo(DynamicLoadObject(
				"hatintime_chapterinfo.BattleOfTheBirds.BattleOfTheBirds_AwardCeremony", class'Hat_ChapterActInfo')), 0);
		
		if (s.IsUnlocked || s.IsComplete)
		{
			if (!ChapterInfo.IsActless)
				s.ActInfoboxTitle = class'Hat_Localizer'.static.GetSystem("levels", "Act") $ " " $ s.ActID;
			s.ActInfoboxName = GetLocalizedActName(shuffledAct, context);
		}
		
		s.InstancedIcon = None;
		if (!s.IsComplete)
		{
			minf = MaterialInterface(GetHourglassIcon(s));
			matinst = new class'MaterialInstanceConstant';
			matinst.SetParent(minf);
			s.InstancedIcon = matinst;
			matinst.SetScalarParameterValue('Value', finalefill);
		}
		
		Hourglasses.AddItem(s);
	}
	
	if (bHasActiveBlockingFinale) return;
	
	if (ChapterInfo.IsActless)
	{
		s.ID = ActSelectType_FreeRoam;
		s.PosX = IconsCenterLocation.X;
		s.PosY = IconsCenterLocation.Y + 0.05;
		s.Hourglass =  "freeroam";
		s.ActInfoboxTitle = class'Hat_Localizer'.static.GetSystem("levels", "FreeRoamDesc");
		s.ActInfoboxName = Caps(class'Hat_Localizer'.static.GetGame("levels", "FreeRoam"));
		s.ActDisplayLabel = "";
		s.IsDefault = true;
		s.IsUnlocked = true;
		s.PonPayCost = 0;
		s.DeathWishPayCost = 0;
		s.ActID = 99;
		s.MapName = ChapterInfo.GetActMap(s.ActID);
		if (s.MapName == "" && ChapterInfo.ActIDAfterIntro > 0)
			s.MapName = ChapterInfo.GetActMap(ChapterInfo.ActIDAfterIntro);
		s.SupportsCoop = TRUE;
		
		s.ChapterActInfo = None;
		ChapterInfo.ConditionalUpdateActList();
		for (i = 0; i < ChapterInfo.ChapterActInfo.Length; i++)
			if (!ChapterInfo.ChapterActInfo[i].IsBonus && ChapterInfo.ChapterActInfo[i].ActID == s.ActID)
				s.ChapterActInfo = ChapterInfo.ChapterActInfo[i];
		
		// Called in AlpsAndSails.umap's intro mountain
		if (ChapterInfo.ActIDAfterIntro > 0)
		{
			//if (class'Hat_SaveBitHelper'.static.HasLevelBit("Actless_FreeRoam_Intro_Complete", 1, s.MapName))
				//s.ActID = ChapterInfo.ActIDAfterIntro;
		}
		
		s.PlanetRotation = ChapterInfo.GetActPlanetRotation(1);
		s.InstancedIcon = None;
		
		if (GetWorldInfo().Role == Role_Authority && !class'Hat_SaveBitHelper'.static.HasLevelBit("ActSelectAnimation_Unlock_Freeroam_" $ GetChapterBitID(), 1))
		{
			s.SpecialAnimation = class'Hat_HUDActSelectAnimation_UnlockAct';
			class'Hat_SaveBitHelper'.static.AddLevelBit("ActSelectAnimation_Unlock_Freeroam_" $ GetChapterBitID(), 1);
		}
		else
			s.SpecialAnimation = None;
		s.IsValid = true;
		
		Hourglasses.AddItem(s);
	}
	else if (HasFreeRoam)
	{
		s.ID = ActSelectType_FreeRoam;
		s.PosX = IconsCenterLocation.X - (HasFinale ? 0.07 : 0.0);
		s.PosY = IconsCenterLocation.Y - 0.4;
		s.Hourglass =  "freeroam";
		s.ActInfoboxTitle = class'Hat_Localizer'.static.GetSystem("levels", "FreeRoamDesc");
		s.ActInfoboxName = Caps(class'Hat_Localizer'.static.GetGame("levels", "FreeRoam"));
		s.ActDisplayLabel = "";
		s.IsDefault = false;
		s.IsUnlocked = true;
		s.PonPayCost = 0;
		s.DeathWishPayCost = 0;
		s.ActID = 99;
		s.MapName = ChapterInfo.GetActMap(1);
		s.PlanetRotation = ChapterInfo.GetActPlanetRotation(1);
		s.InstancedIcon = None;
		s.SupportsCoop = TRUE;
		
		s.ChapterActInfo = None;
		ChapterInfo.ConditionalUpdateActList();
		for (i = 0; i < ChapterInfo.ChapterActInfo.Length; i++)
			if (!ChapterInfo.ChapterActInfo[i].IsBonus && ChapterInfo.ChapterActInfo[i].ActID == s.ActID)
				s.ChapterActInfo = ChapterInfo.ChapterActInfo[i];
		
		if (!class'Hat_SaveBitHelper'.static.HasLevelBit("ActSelectAnimation_Unlock_Freeroam_" $ GetChapterBitID(), 1))
		{
			s.SpecialAnimation = class'Hat_HUDActSelectAnimation_UnlockAct';
			class'Hat_SaveBitHelper'.static.AddLevelBit("ActSelectAnimation_Unlock_Freeroam_" $ GetChapterBitID(), 1);
		}
		if (GetWorldInfo().Role == Role_Authority && !class'Hat_SaveBitHelper'.static.HasLevelBit("ActSelectAnimation_Unlock_Freeroam_" $ GetChapterBitID(), 1))
		{
			s.SpecialAnimation = class'Hat_HUDActSelectAnimation_UnlockAct';
			class'Hat_SaveBitHelper'.static.AddLevelBit("ActSelectAnimation_Unlock_Freeroam_" $ GetChapterBitID(), 1);
		}
		else
			s.SpecialAnimation = None;
		s.IsValid = true;
		
		Hourglasses.AddItem(s);
	}
}

simulated function BuildBonusHourglasses(HUD H)
{
	local int i;
	local Array<Hat_ChapterActInfo> BonusUnlocked, ColumnA, ColumnB;
	local bool IsCaveRift, HasCompletedEverythingExceptCaveRifts;
	
	BonusUnlocked.Length = 0;
	ColumnA.Length = 0;
	ColumnB.Length = 0;

	HasCompletedEverythingExceptCaveRifts = class'Hat_GameManager'.static.AreAllActsComplete(ChapterInfo, false, false);

	ChapterInfo.ConditionalUpdateActList();
	for (i = 0; i < ChapterInfo.ChapterActInfo.Length; i++)
	{
		if (!ChapterInfo.ChapterActInfo[i].IsBonus) continue;
		
		IsCaveRift = ChapterInfo.ChapterActInfo[i].RequiredActID.Length <= 0;
		
		if (!`AP.IsChapterActInfoUnlocked(ChapterInfo.ChapterActInfo[i], ModChapterPackageName))
		{
			// Always allow it to pass if its a cave rift, and we're only missing cave rifts
			if (!IsCaveRift || !HasCompletedEverythingExceptCaveRifts) continue;
		}
		
		BonusUnlocked.AddItem(ChapterInfo.ChapterActInfo[i]);
		if (IsCaveRift)
			ColumnA.AddItem(ChapterInfo.ChapterActInfo[i]);
		else
			ColumnB.AddItem(ChapterInfo.ChapterActInfo[i]);
	}
	if (BonusUnlocked.Length <= 0) return;
	
	BuildBonusHourglassesSide(H, ColumnA, 120, false);
	BuildBonusHourglassesSide(H, ColumnB, 120, true);

}

simulated function BuildBonusHourglassesSide(HUD H, Array<Hat_ChapterActInfo> HourglassList, float max_angle, bool invertX)
{
	local float angle, angle_radians, posx, posy;
	local int i, basement, context;
	local MenuSelectHourglass s;
	local bool IsCompleted;
	local Hat_ChapterActInfo shuffledAct;
	
	if (HourglassList.Length <= 0) return;
	
	angle = 0;
	if (HourglassList.Length % 2 == 0)
		angle = max_angle / float(HourglassList.Length) / 2;
	i = 0;
	while (angle < max_angle)
	{
		if (HourglassList.Length <= 1)
			angle_radians = 0;
		else
			angle_radians = (angle-(max_angle/2))*2.0*Pi/360.0;
		
		posx = IconsCenterLocation.X + cos(angle_radians)*0.29;
		posy = IconsCenterLocation.Y + sin(angle_radians)*0.29;
		posy += sin(GetWorldInfo().TimeSeconds + angle*3 + (invertX ? 0 : 1))*0.009;
		
		if (invertX) posx = (posx - IconsCenterLocation.X)*-1 + IconsCenterLocation.X;
		
		s.Hourglass =  HourglassList[i].Hourglass;
		s.ChapterActInfo = HourglassList[i];
        IsCompleted = `AP.IsActReallyCompleted(s.ChapterActInfo);
		s.ID = invertX ? ActSelectType_TimeRift_Water : ActSelectType_TimeRift_Cave;
		// The cave rift was shown even if we don't have it unlocked - this happens if everything is cleared except the cave rift. In that case, we only want to remind them that it exists.
		if (s.ID == ActSelectType_TimeRift_Cave && !IsCompleted && !`AP.IsChapterActInfoUnlocked(s.ChapterActInfo, ModChapterPackageName))
			s.ID = ActSelectType_TimeRift_Cave_Reminder;
		
		if (`AP.SlotData.ActRando)
		{
			if (ChapterInfo.ChapterID == 2 && s.ActID == 6 && `AP.IsAwardCeremonyCompleted())
			{
				shuffledAct = `AP.GetDeadBirdBasementShuffledAct();
			}
			else
			{
				shuffledAct = `AP.GetShuffledAct(s.ChapterActInfo, basement);
			}
		}
		else
		{
			shuffledAct = s.ChapterActInfo;
		}
		
		context = shuffledAct.IsBonus ? 1 : `AP.IsActFreeRoam(shuffledAct) ? 2 : 0;
		
		s.ActInfoboxName = basement == 0 ? GetLocalizedActName(shuffledAct, context) : 
			GetLocalizedActName(Hat_ChapterActInfo(DynamicLoadObject(
				"hatintime_chapterinfo.BattleOfTheBirds.BattleOfTheBirds_AwardCeremony", class'Hat_ChapterActInfo')), 0);

		s.PosX = posx;
		s.PosY = posy;
		s.ActInfoboxTitle = class'Hat_Localizer'.static.GetGame("levels", s.ID == ActSelectType_TimeRift_Water ? "Location_DreamWorld_Water" : "Location_DreamWorld_Cave");
		s.ActInfoboxName = IsCompleted ? GetLocalizedActName(shuffledAct, context) : "???";
		s.ActDisplayLabel = s.ActInfoboxName;
		s.IsDefault = false;
		s.Photo = s.ID != ActSelectType_TimeRift_Cave_Reminder ? HourglassList[i].Photo : None;
		s.MapName = s.ID != ActSelectType_TimeRift_Cave_Reminder ? HourglassList[i].MapName : "";
		s.ActID = 1;
		s.IsComplete = IsCompleted;
		s.IsUnlocked = true;
		s.PonPayCost = 0;
		s.DeathWishPayCost = 0;
		s.SupportsCoop = HourglassList[i].SupportsCoop;
		s.StandoffOffset = IsActiveStandoff ? (s.ID == ActSelectType_TimeRift_Water ? -1 : 1) : 0;
		s.SpecialAnimation = None;
		
		if (s.ID != ActSelectType_TimeRift_Cave_Reminder)
		{
			if (IsCompleted && 
				((GetWorldInfo().Role == Role_Authority && !class'Hat_SaveBitHelper'.static.HasLevelBit("ActSelectAnimation_Complete_"$GetChapterBitID(s.Hourglass), 2))))
			{
				s.SpecialAnimation = class'Hat_HUDActSelectAnimation_CompleteAct';
				if (GetWorldInfo().Role == Role_Authority)
					class'Hat_SaveBitHelper'.static.AddLevelBit("ActSelectAnimation_Complete_"$GetChapterBitID(s.Hourglass), 2);
			}
			else if (!IsCompleted && 
				((GetWorldInfo().Role == Role_Authority && !class'Hat_SaveBitHelper'.static.HasLevelBit("ActSelectAnimation_Unlock_"$GetChapterBitID(s.Hourglass), 1))))
			{
				s.SpecialAnimation = class'Hat_HUDActSelectAnimation_UnlockTimeRift';
				if (GetWorldInfo().Role == Role_Authority)
					class'Hat_SaveBitHelper'.static.AddLevelBit("ActSelectAnimation_Unlock_"$GetChapterBitID(s.Hourglass), 1);
			}
			else
				s.SpecialAnimation = None;
		}

		s.IsValid = true;
		Hourglasses.AddItem(s);
		
		if (HourglassList.Length <= 1)
			break;

		angle += max_angle / float(HourglassList.Length);
		i++;
	}
}

simulated function bool HasActiveBlockingFinale(HUD H)
{
	local int TotalRequired, CompletedRequiredActsLength;
	if (!ChapterInfo.FinaleIsBlocking) return false;
	if (!GetFinaleInfo(H, TotalRequired, CompletedRequiredActsLength)) return false;
	
	if (`AP.IsChapterActInfoUnlocked(ChapterInfo.GetChapterActInfoFromActID(ChapterInfo.FinaleActID))) return false;
	
	return (CompletedRequiredActsLength >= TotalRequired);
}

simulated function bool GetFinaleInfo(HUD H, out int TotalRequired, out int CompletedRequiredActsLength)
{
	local Array<Hat_ChapterActInfo> CompletedRequiredActs;
	if (ChapterInfo.FinaleActID <= 0) return false;
	
	//if (ChapterInfo.FinaleDisappearOnCompletion && `AP.IsChapterActInfoUnlocked(ChapterInfo.GetChapterActInfoFromActID(ChapterInfo.FinaleActID))) return false;
	
	CompletedRequiredActs = GetCompletedRequiredActs(ChapterInfo, ChapterInfo.FinaleActID, TotalRequired, ModChapterPackageName);
	CompletedRequiredActsLength = CompletedRequiredActs.length;
	
	// Need at least 1 required act completed before finale shows up
	return CompletedRequiredActsLength > 0;
}

function Array<Hat_ChapterActInfo> GetCompletedRequiredActs(Hat_ChapterInfo ci, int InActID, optional out int TotalRequired, optional string ModPackageName)
{
	local int j, ActIndex, ActID;
	local Array<Hat_ChapterActInfo> Results;
	local string hourglass;
	local bool IsFinale, IsFinaleWithNORequiredActIDs;
	ci.ConditionalUpdateActList();
	
	ActIndex = ci.GetActIndex(InActID);
	if (ActIndex == INDEX_NONE) return Results;
	
	IsFinale = ci.FinaleActID == InActID;
	// if true, then the finale wants ALL acts except its own
	IsFinaleWithNoRequiredActIDs = IsFinale && ci.ChapterActInfo[ActIndex].RequiredActID.Length == 0;
	TotalRequired = 0;
	
	for (j = 0; j < IsFinaleWithNoRequiredActIDs ? ci.ChapterActInfo.Length : ci.ChapterActInfo[ActIndex].RequiredActID.Length; j++)
	{
		if (IsFinaleWithNoRequiredActIDs) 
			ActID = ci.ChapterActInfo[j].ActID;
		else 
			ActID = ci.ChapterActInfo[ActIndex].RequiredActID[j];
		
		hourglass = ci.GetActHourglass(ActID);
		if (hourglass == "") continue;
		if (hourglass == ci.ChapterActInfo[ActIndex].Hourglass) continue; // Don't include ourselves
		
		/*
		InDevelopmentOrUnavailable = false;
		for (k = 0; k < ChapterInfo.ChapterActInfo.Length; k++)
		{
			if (ChapterInfo.ChapterActInfo[k].Hourglass != hourglass) continue;
			InDevelopmentOrUnavailable = ChapterInfo.ChapterActInfo[k].InDevelopment;
			break;
		}
		if (InDevelopmentOrUnavailable) continue;
		*/
		
		TotalRequired++;
		
		//if (ModPackageName != "")
		//	hourglass = class'Hat_TimeObject_Base'.static.GetModTimePieceIdentifier(ModPackageName, hourglass);
		
		if (!`AP.IsActReallyCompleted(ci.GetChapterActInfoFromActID(ActID))) continue;
		
		Results.AddItem(ci.ChapterActInfo[j]);
	}
	
	return Results;
}

function bool PayTimePiece(string TimePieceID)
{
	local Hat_SaveGame save;
    local SaveGameTimeObjectInfo t;
	local int i;
    if (TimePieceID == "") return false;
    //if (HasTimePiece(TimePieceID)) return false;
    if (HasPaidTimePiece(TimePieceID)) return false;
	
	save = `SaveManager.GetCurrentSaveData();
	
	for (i = 0; i < save.TimeObjects.Length; i++)
	{
		if (Locs(save.TimeObjects[i].ID) != Locs(TimePieceID)) continue;
		save.TimeObjects[i].Paid = true;
		return true;
	}
	//if (!HasPaid) return false;
    
    t.ID = TimePieceID;
	t.Paid = true;
    save.TimeObjects.AddItem(t);
    return true;
}