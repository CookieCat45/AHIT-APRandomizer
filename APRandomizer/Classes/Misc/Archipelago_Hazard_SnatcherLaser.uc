class Archipelago_Hazard_SnatcherLaser extends Hat_Hazard_SnatcherLaser_Base;

defaultproperties
{
   Begin Object Class=ParticleSystemComponent Name=ParticleComponent0
        Template = ParticleSystem'HatinTime_Levels_ToDArena.Particles.SnatcherLaser'
        HiddenEditor=true
        bAutoActivate = false
   End Object
   Components.Add(ParticleComponent0);
   ParticleComponent = ParticleComponent0;
   
   Begin Object Class=ParticleSystemComponent Name=WarningParticleComponent0
        Template = ParticleSystem'HatinTime_Levels_ToDArena.Particles.SnatcherLaser_Warning'
        HiddenEditor=false
        bAutoActivate = true
   End Object
   Components.Add(WarningParticleComponent0);
   WarningParticleComponent = WarningParticleComponent0;
   
	Begin Object Class=AudioComponent Name=OverlayAudioComponent0
		SoundCue=SoundCue'HatinTime_SFX_SnatcherBoss.SoundCues.SlowPillarAttackOverlay_Phase1'
		bAutoPlay=false
		bStopWhenOwnerDestroyed=true
		bShouldRemainActiveIfDropped=false
	End Object
	OverlayAudioComponent=OverlayAudioComponent0
	Components.Add(OverlayAudioComponent0)
   
   AltParticle = ParticleSystem'HatinTime_Levels_ToDArena.Particles.SnatcherLaser_Alt'
   AltWarningParticle = ParticleSystem'HatinTime_Levels_ToDArena.Particles.SnatcherLaser_Warning_Alt'
   ActivateSound = SoundCue'HatinTime_SFX_Subcon.SoundCues.SnatcherLaser'
   //OverlaySound = SoundCue'HatinTime_SFX_SnatcherBoss.SoundCues.SlowPillarAttackOverlay_Phase1'
   AltOverlaySound = SoundCue'HatinTime_SFX_SnatcherBoss.SoundCues.SuperPillarAttackOverlay_Phase2'
   
   WarningTime = 1.0;
}