class Archipelago_RandomizedItem_Contract extends Archipelago_RandomizedItem_Base;

defaultproperties
{
	Begin Object Name=m_hLightEnvironment
	
	End Object
	m_hLightEnvironment = m_hLightEnvironment;
	Components.Add(m_hLightEnvironment)
	
	Begin Object Class=AnimNodeSequence Name=AnimNodeSeq0
	End Object
	
	Begin Object Class=SkeletalMeshComponent Name=Model2
		SkeletalMesh = SkeletalMesh'HatInTime_Levels_DarkForest_V.models.ContractPen'
		PhysicsAsset = PhysicsAsset'HatInTime_Levels_DarkForest_V.Physics.ContractPen_Physics'
		AnimSets(0) = AnimSet'HatInTime_Levels_DarkForest_V.AnimSet.ContractPen_Anims'
		AnimTreeTemplate = None
		Animations=AnimNodeSeq0
		
		LightEnvironment=m_hLightEnvironment
		MaxDrawDistance = 9000;
		bDisableFaceFX = true;
		bDisableAllRigidBody = true;
		Scale=2
	End Object
	Mesh=Model2;
	Components.Add(Model2);
	RotationComponents.Add(Model2);
}