class Archipelago_Stackable_Conductor extends Archipelago_Stackable_Base;

`if(`isdefined(WITH_DLC1))
defaultproperties
{
	Begin Object Name=SkeletalMeshComponent0
		SkeletalMesh = SkeletalMesh'HatInTime_Characters.models.Conductor'
		PhysicsAsset = PhysicsAsset'HatInTime_Characters.Physics.Conductor_Physics'
		AnimSets(0) = AnimSet'HatInTime_Characters_Conductor.AnimSets.Conductor_Anims'
		AnimSets(1) = AnimSet'HatInTime_Characters_Conduct2.AnimSets.Conductor_Cruise_Anims'
		AnimTreeTemplate = AnimTree'HatInTime_Characters.AnimTree.Conductor_Standing_AnimTree'
	End Object

	StackHeight = 65
	StackOffset = -15
}
`endif