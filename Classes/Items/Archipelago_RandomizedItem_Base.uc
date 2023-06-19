/**
 * Base collectible class for randomized Archipelago items.
 * Generally serves as a proxy to send locations to the server and a visual to show what the item is, 
 * but is also used to play item collection effects as well.
 */
class Archipelago_RandomizedItem_Base extends Hat_Collectible
	abstract
	dependson(Archipelago_ItemInfo);
	
`include(APRandomizer\Classes\Globals.uci);

var int LocationId;
var int ItemId;
var int ItemOwner;
var int ItemFlags;
var bool OwnItem;
var string ItemDisplayName;
var string ItemDesc;
var Surface HUDIcon;
var bool SaveGameOnCollect;
var bool DoSpinEffect;
var class<object> InventoryClass;
var string OriginalCollectibleName; // the "Name" variable, NOT the display name!

var AudioComponent IdleAudioComponent;
var ParticleSystemComponent ImportantItemParticle;
var PointLightComponent LightComponent;

function Init()
{
	if (HasOriginalLevelBit()) // Already collected
	{
		Destroy();
	}
	else if (ItemFlags == ItemFlag_Garbage) // No flashy effects for garbage items (still for traps though :v)
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

simulated function bool OnCollected(Actor Collector)
{
	local Hat_PlayerController pc;
	local Hat_Loadout loadout;
	local Hat_LoadoutBackpackItem item;
	
	// Don't do anything if we aren't connected 
	// TODO: add something to send pending items when player reconnects
	if (!WasFromServer() && !`AP.IsFullyConnected())
		return false;
	
	if (LightComponent != None)
		LightComponent.SetEnabled(false);
	
	if (IdleAudioComponent != None)
		IdleAudioComponent.VolumeMultiplier = 0;

	if (ImportantItemParticle != None)
		ImportantItemParticle.SetActive(false);
	
	if (WasFromServer())
	{
		if (IsA('Archipelago_RandomizedItem_Yarn'))
		{
			`AP.OnYarnCollected();
		}
		else if (InventoryClass != None)
		{
			pc = Hat_PlayerController(Pawn(Collector).controller);
			item = class'Hat_Loadout'.static.MakeLoadoutItem(InventoryClass);
			
			if (item != None)
			{
				loadout = pc.GetLoadout();
				
				if (!loadout.AddBackpack(item, true, true, Hat_Player(Collector)))
				{
					loadout.AddCollectible(InventoryClass);
				}
			}
			else
			{
				`AP.ScreenMessage("Failed to create inventory item for " $InventoryClass $", please report");
			}
		}
	}
	else
	{
		CollectSound = None;
	}
	
	// Save
	if (OriginalCollectibleName != "")
		SetOriginalLevelBit();
		
	if (SaveGameOnCollect)
		`SaveManager.SaveToFile();
	
	return Super.OnCollected(Collector);
}

function SetOriginalLevelBit()
{
	class'Hat_SaveBitHelper'.static.SetLevelBits(OriginalCollectibleName, 1, class'Hat_SaveBitHelper'.static.GetCorrectedMapFilename(string(GetLevelName())), `SaveManager.GetCurrentSaveData());
}

function bool HasOriginalLevelBit()
{
	return class'Hat_SaveBitHelper'.static.HasLevelBit(OriginalCollectibleName, 1, class'Hat_SaveBitHelper'.static.GetCorrectedMapFilename(string(GetLevelName())), `SaveManager.GetCurrentSaveData());
}

function bool WasFromServer()
{
	return LocationId == 0;
}

function bool IsOwnItem()
{
	return OwnItem;
}

simulated function OnCollectedDisappear(Actor a)
{
	if (!ShouldDoSpinEffect())
	{
		if (bNoDelete) SetHidden(true);
		else Destroy();
		return;
	}
		
	RemoveNPCManagement();
    DisappearingActor = a;
    Disappearing = true;
    DisappearingTime = 0;
    SetPhysics(Phys_None);
    PickupActor = a;
	SetBase(none);
	
    SetTimer(ItemSpinDisappearTime, false, NameOf(Destroy));
	DoCollectEffects(a);
}

function bool ShouldDoSpinEffect()
{
	return DoSpinEffect && (!IsOwnItem() || WasFromServer());
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
		MaxDrawDistance = 6000;
		bSelectable = false;
    End Object 
    Components.Add(hParticle0);
	RotationComponents.Add(hParticle0);
    ImportantItemParticle = hParticle0;
	
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
	LocationId = 0;
}