class Archipelago_RandomizedItem_Yarn extends Archipelago_RandomizedItem_Base;

var ParticleSystem BadgeSnapParticle;
var ParticleSystem BadgeSnapParticle2;

event Destroyed()
{
	if (ShouldDoSpinEffect())
		SnapBadgeDisappear();
		
	Super.Destroyed();
}

simulated function SnapBadgeDisappear()
{
	local ParticleSystemComponent p;
	
	p = WorldInfo.MyEmitterPool.SpawnEmitter(BadgeSnapParticle, Mesh.GetPosition());
	p.SetDepthPriorityGroup(SDPG_Foreground);
	p = WorldInfo.MyEmitterPool.SpawnEmitter(BadgeSnapParticle2, Mesh.GetPosition());
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
	
	HUDIcon = Texture2D'HatInTime_Hud_ItemIcons.Yarn.yarn_ui_sprint';
	
	BadgeSnapParticle = ParticleSystem'HatInTime_PlayerAssets.Particles.BadgePointSnap';
	BadgeSnapParticle2 = ParticleSystem'HatInTime_PlayerAssets.Particles.ClothPointSnap';
	CollectSound = SoundCue'HatinTime_SFX_UI.Badge_Pickup_SnappingCoin_cue';
	
	SaveGameOnCollect = true;
}