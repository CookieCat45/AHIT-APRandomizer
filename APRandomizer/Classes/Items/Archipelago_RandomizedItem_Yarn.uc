class Archipelago_RandomizedItem_Yarn extends Archipelago_RandomizedItem_Base;

`include(APRandomizer\Classes\Globals.uci);

var ParticleSystem BadgeSnapParticle;

simulated function bool OnCollected(Actor Collector)
{
	if (WasFromServer())
	{
		`AP.OnYarnCollected();
	}
	
	// don't show +1 yarn effect unless we are connected,
	// because we're not actually getting an item if we aren't
	if (ShouldDoSpinEffect() && `AP.IsFullyConnected())
	{
		SetTimer(0.304, false, NameOf(SnapBadgeDisappear));
	}
	
	return Super.OnCollected(Collector);
}

function SnapBadgeDisappear()
{
	local ParticleSystemComponent p;
	
	SetHidden(true);
	p = WorldInfo.MyEmitterPool.SpawnEmitter(BadgeSnapParticle, Mesh.GetPosition());
	p.SetDepthPriorityGroup(SDPG_Foreground);
}

defaultproperties
{
	Begin Object Class=StaticMeshComponent Name=Model2
		StaticMesh = StaticMesh'HatinTime_Items_Z.models.yarn_ui_hover';
		Scale = 2;
		Rotation = (Pitch=0);
	End Object
	Mesh=Model2;
	Components.Add(Model2);
	RotationComponents.Add(Model2);
	
	InventoryClass = None;
	
	BadgeSnapParticle = ParticleSystem'HatInTime_PlayerAssets.Particles.ClothPointSnap';
	CollectSound = SoundCue'HatinTime_SFX_UI.Badge_Pickup_SnappingCoin_cue';
	HUDIcon = Texture2D'HatInTime_Hud_Loadout.Overview.cloth_points';
}