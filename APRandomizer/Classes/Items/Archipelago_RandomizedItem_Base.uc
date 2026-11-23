/**
 * Base collectible class for randomized Archipelago items.
 * Generally serves as a proxy to send locations to the server and a visual to show what the item is, 
 * but is also used to play item collection effects as well.
 */
class Archipelago_RandomizedItem_Base extends Hat_Collectible_Important
	abstract
	dependson(Archipelago_ItemInfo);
	
`include(APRandomizer\Classes\Globals.uci);

var int LocationId;
var string ItemId;
var string DisplayName;
var string Desc;
var int ItemOwner;
var int ItemFlags;
var bool DoSpinEffect;
var class<Object> InvClass;
var string OriginalCollectibleName;

var AudioComponent IdleAudioComponent;
var ParticleSystemComponent ImportantItemParticle;
var ParticleSystemComponent JunkItemParticle;
var PointLightComponent LightComponent;

function bool Init()
{
	if (ItemFlags == ItemFlag_Garbage)
	{
		// No flashy effects for garbage items (still for traps though :v)
		if (!IsA('Archipelago_RandomizedItem_Yarn'))
		{
			if (IdleAudioComponent != None)
				IdleAudioComponent.VolumeMultiplier = 0;
	
			if (ImportantItemParticle != None)
			{
				ImportantItemParticle.SetActive(false);
				ImportantItemParticle.KillParticlesForced();
			}
		}
	}
	else
	{
		JunkItemParticle.SetActive(false);
		JunkItemParticle.KillParticlesForced();
	}
	
	return true;
}

simulated function bool OnCollected(Actor Collector)
{
	local Hat_PlayerController pc;
	local Hat_Loadout loadout;
	local Hat_LoadoutBackpackItem item;
	local bool autoEquip;
	local int i, count;
	
	if (LightComponent != None)
		LightComponent.SetEnabled(false);
	
	if (IdleAudioComponent != None)
		IdleAudioComponent.VolumeMultiplier = 0;
	
	if (ImportantItemParticle != None)
		ImportantItemParticle.SetActive(false);
	
	if (ShouldDoSpinEffect())
	{
		if (`AP.ItemSoundCooldown)
		{
			CollectSound = None;
		}
		else
		{
			`AP.ItemSoundCooldown = true;
			`AP.SetTimer(0.7, false, NameOf(`AP.ItemSoundTimer));
		}
	}
	
	if (WasFromServer())
	{
		if (InvClass != None)
		{
			pc = Hat_PlayerController(Pawn(Collector).controller);
			item = class'Hat_Loadout'.static.MakeLoadoutItem(InvClass);
			loadout = pc.GetLoadout();
			autoEquip = true;
			
			if (class'Hat_Loadout'.static.IsClassBadge(InvClass))
			{
				for (i = 0; i < loadout.MyLoadout.Badges.Length; i++)
				{
					if (loadout.MyLoadout.Badges[i] != None)
					{
						count += 1;
					}
				}
				
				autoEquip = (count < `SaveManager.GetNumberOfBadgeSlots());
			}
			else if (class'Hat_Loadout'.static.IsClassHat(InvClass))
			{
				autoEquip = false;
			}
			
			if (loadout.AddBackpack(item, autoEquip, true, Hat_Player(Collector)) || loadout.AddCollectible(InvClass))
			{
				OnAddedToInventory();
			}
			else
			{
				`AP.ScreenMessage("Failed to create inventory item for " $InvClass $", please report");
			}
		}
	}
	else if (!`AP.IsFullyConnected())
	{
		CollectSound = None;
	}
	
	// Save
	if (OriginalCollectibleName != "")
	{
		SetOriginalLevelBit();
	}
	
	//return Super.OnCollected(Collector);
	if (AttractActor != None) UpdateAttractActorIndices(AttractActor);
	AttractActor = None;
    PickupActor = Collector;
	SetCollision(false,false);
	bCollideWorld = false;
    
	CallCollectMiniMission();
    CallInteractionEvent(Collector);
	if (TickOptimize == TickOptimize_None)
		SetTickIsDisabled(false);
	`NPCManager.SetIsInTickSensitiveAction(self, true);
	Moving = false;
	TriggerCollectedDelegates();

	`if(`isdefined(WITH_GHOSTPARTY))
	ConditionalSyncGhostParty(Collector);
	ConditionalAwardGhostPartyScore(Collector);
	`endif
    OnCollectedDisappear(Collector);
	
	if (ScaleOnCollect > 0)
		Mesh.SetScale(ScaleOnCollect);
	
	`if(`isdefined(WITH_DLC1))
	if (Pawn(Collector) != None && Pawn(Collector).Controller != None)
	{
		class'Hat_HUDElementCoopVersus'.static.AddPoints(Pawn(Collector).Controller, class);
	}
	`endif

	return false;
}

function OnAddedToInventory()
{
	`AP.SetAPBits(string(InvClass), 1);
}

function SetOriginalLevelBit()
{
	if (OriginalCollectibleName == "")
		return;
	
	if (InStr(OriginalCollectibleName, "AP_Camera") != -1)
	{
		`AP.SetAPBits(OriginalCollectibleName, 1);
		return;
	}
	
	class'Hat_SaveBitHelper'.static.SetLevelBits(OriginalCollectibleName, 1, class'Hat_SaveBitHelper'.static.GetCorrectedMapFilename(string(GetLevelName())), `SaveManager.GetCurrentSaveData());
}

function bool WasFromServer()
{
	return LocationId == 0;
}

function bool IsOwnItem()
{
	return ItemOwner == `AP.SlotData.PlayerSlot;
}

simulated function OnCollectedDisappear(Actor a)
{
	if (!ShouldDoSpinEffect())
	{
		Destroy();
		return;
	}
	
	RemoveNPCManagement();
    DisappearingActor = a;
    Disappearing = true;
    DisappearingTime = 0;
    SetPhysics(Phys_None);
    PickupActor = a;
	SetBase(none);
	
    SetTimer(ItemSpinDisappearTime, false, NameOf(Destroy2));
	DoCollectEffects(a);
}

simulated static function string GetLocalizedItemName()
{
	if (default.DisplayName != "")
	{
		return default.DisplayName;
	}
	else if (class<Hat_Collectible_Important>(default.InvClass) != None)
	{
		return GetLocalizedString(default.Header, class<Hat_Collectible_Important>(default.InvClass).default.ItemName);
	}
	else if (class<Hat_Ability>(default.InvClass) != None)
	{
		return class<Hat_Ability>(default.InvClass).static.GetLocalizedName();
	}
	
	return "???";
}

simulated static function Array<string> GetLocalizedItemDesc()
{
	local array<string> r;
	local int i;
	if (default.Desc != "")
	{
		r.AddItem(default.Desc);
		return r;
	}
	else if (class<Hat_Collectible_Important>(default.InvClass) != None)
	{
		for (i = 0; i < default.ItemDescription.Length; i++)
		{
			r.AddItem(GetLocalizedString(default.Header, class<Hat_Collectible_Important>(default.InvClass).default.ItemDescription[i]));
		}
	}
	else if (class<Hat_Ability>(default.InvClass) != None)
	{
		return class<Hat_Ability>(default.InvClass).static.GetLocalizedDescription();
	}
	
	return r;
}

function Destroy2()
{
	Destroy();
}

simulated function DoCollectEffects(Actor a)
{
	local Hat_Player ply;
    if (CollectSound != None && ((WorldInfo != None && WorldInfo.NetMode == NM_Standalone) || Role == Role_Authority))
		PlaySound(CollectSound, false, false, false);
	ply = Hat_Player(GetPlayerFromActor(a));
    if (ply != None && CollectParticle != None)
	{
		ply.DoCollectEffects(self,CollectParticle,Location);
	}
}

function bool ShouldDoSpinEffect()
{
	return DoSpinEffect && (!IsOwnItem() || WasFromServer());
}

simulated function bool WantsToSkipMessage(Actor Collector)
{
	return true;	
}

function bool CanCollect(Actor A)
{
	local Controller MyController;
	local bool IsNonPlayer;
    if (!Enabled) return false;
    if (bHidden) return false;
	if (PickupActor != None) return false;
    if (GetPlayerFromActor(A) == None) return false;
	if (a.IsA('Hat_GhostPartyPlayerBase')) return false;
	if (A.IsA('Vehicle')) return false;
	if (!A.IsA('Hat_Player') && A.Physics != Phys_Walking && A.Physics != Phys_Falling && A.Physics != Phys_Swimming) return false; // this prevents hookshot collect if enabled on Hat_Player
	MyController = Pawn(A) != None ? PlayerController(Pawn(A).Controller) : None;
	if (MyController == None && Pawn(A) != None && Pawn(A).DrivenVehicle != None)
		MyController = Pawn(A).DrivenVehicle.Controller;
	if (MyController != None && MyController.IsA('PlayerController') && PlayerController(MyController).bCinematicMode && AttractActor != A) return false;
	if (Pawn(A) != None && Pawn(A).Health <= 0) return false;
	if (Hat_Player(A) != None && Hat_Player(A).IsDead) return false;
	IsNonPlayer = MyController == None || !MyController.IsA('PlayerController');
	if (Hat_Player(A) != None && (!Hat_Player(A).CanCollectCollectiblesEvenIfNotPlayer && IsNonPlayer)) return false;
    if (SpawnWaitTime < 1.0 && AttractActor != A) return false;
	if (Base != None && Base.IsA('Hat_Enemy')) return false;
	if (CollectedByCoopPlayer && AttractActor == A) return false;
    return true;
}

simulated function bool GiveCollectible(Pawn p)
{
	return false;	
}

defaultproperties
{
	Begin Object Name=CollisionCylinder
		CollisionRadius=30;
		CollisionHeight=30;
		BlockActors=false;
		CollideActors=true;
		bDisableAllRigidBody = true;
		bAlwaysRenderIfSelected=true;
		bDrawBoundingBox=false;
	End Object
	bCollideActors=true;
	CollisionComponent = CollisionCylinder;
	Components.Add(CollisionCylinder);
	
	Begin Object Class=AudioComponent Name=IdleAudioComponent0
		SoundCue = SoundCue'HatinTime_SFX_Player4.SoundCues.Yarn_Attract_Sound';
		bAutoPlay=true;
		bStopWhenOwnerDestroyed=true;
		bShouldRemainActiveIfDropped=true;
	End Object
	Components.Add(IdleAudioComponent0);
	IdleAudioComponent = IdleAudioComponent0;
	
    Begin Object Class=ParticleSystemComponent Name=hParticle0
        Template = ParticleSystem'HatInTime_Items.ParticleSystems.BadgeAttentionParticle';
		Translation=(Z=10);
		MaxDrawDistance = 99999;
		bSelectable = false;
    End Object 
    Components.Add(hParticle0);
	RotationComponents.Add(hParticle0);
    ImportantItemParticle = hParticle0;
	
	Begin Object Class=ParticleSystemComponent Name=hParticle1
        Template = ParticleSystem'HatInTime_Items.ParticleSystems.ImportantItem';
		Translation=(Z=10);
		MaxDrawDistance = 99999;
		bSelectable = false;
    End Object 
    Components.Add(hParticle1);
	RotationComponents.Add(hParticle1);
    JunkItemParticle = hParticle1;
	
	Begin Object Class=PointLightComponent Name=PointLightComponent0
	    LightAffectsClassification=LAC_STATIC_AFFECTING
		CastShadows=TRUE
		CastStaticShadows=TRUE
		CastDynamicShadows=FALSE
		bEnabledInEditor=FALSE
		bForceDynamicLight=FALSE
		UseDirectLightMap=TRUE
		bAffectCompositeShadowDirection = FALSE
		CullDistance=5000
		LightingChannels=(BSP=TRUE,Static=TRUE,Dynamic=TRUE,bInitialized=TRUE)
		Brightness=2
		LightColor=(R=250,G=250,B=201)
		Radius=128
	End Object
	LightComponent=PointLightComponent0;
	Components.Add(PointLightComponent0);
	
	CollectSound = SoundCue'HatinTime_SFX_Player3.SoundCues.Pon_Chain1';
	ScaleOnCollect = 0.65;
	RotationAnimation = true;
	DoSpinEffect = true;
	bAlwaysTick = true;
	bNoDelete = false;
	bCanBeDamaged = false;
	IsBackpackItem = false;
	bUseLevelBit = false;
	TickOptimize = TickOptimize_Distance;
	LocationId = 0;
}