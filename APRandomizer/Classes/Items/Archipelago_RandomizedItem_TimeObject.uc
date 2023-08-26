class Archipelago_RandomizedItem_TimeObject extends Archipelago_RandomizedItem_Base;

var SkeletalMeshComponent Mesh2;

simulated function bool OnCollected(Actor Collector)
{
	return Super.OnCollected(Collector);
}

defaultproperties
{
   Begin Object Name=Model
      SkeletalMesh=SkeletalMesh'HatInTime_Items.models.timeobject'
      PhysicsAsset=PhysicsAsset'HatInTime_Items.Physics.timeobject_Physics'
      AnimSets(0)=AnimSet'HatInTime_Items.AnimSets.timeobject_Anims'
      AnimTreeTemplate=AnimTree'HatInTime_Items.AnimTrees.timeobject_animtree'
      Translation=(Z=-16.0)
	  bUpdateKinematicBonesFromAnimation=true
   End Object
   Mesh2=Model;
   Components.Add(Model);
	
	Begin Object Name=IdleAudioComponent0
		SoundCue = SoundCue'HatInTime_Items.SoundCues.time_piece_sparkle';
		bAutoPlay=true;
		bStopWhenOwnerDestroyed=true;
		bShouldRemainActiveIfDropped=true;
	End Object
	Components.Add(IdleAudioComponent0);
	IdleAudioComponent = IdleAudioComponent0;
	
	HUDIcon = Texture2D'HatInTime_Hud.Textures.Collectibles.collectible_timepiece';
}