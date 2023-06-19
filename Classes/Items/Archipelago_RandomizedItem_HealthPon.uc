class Archipelago_RandomizedItem_HealthPon extends Archipelago_RandomizedItem_Base;

var StaticMeshComponent Capsule;

defaultproperties
{
	Begin Object Class=StaticMeshComponent Name=Model2
		StaticMesh=StaticMesh'HatInTime_Items.models.healthrecovery'
		Scale=3;
		Translation=(Z=-2);
		MaxDrawDistance = 2500;
	End Object
	Mesh=Model2;
	Components.Add(Model2);
	RotationComponents.Add(Model2);
	
	Begin Object Class=StaticMeshComponent Name=CapsuleMesh
		StaticMesh=StaticMesh'HatInTime_Items.Capsules.Meshes.capsule'
		Materials(0)=MaterialInstanceConstant'HatInTime_Items.Capsules.Materials.Capsules_Red_WhiteBottom'
		Materials(1)=MaterialInstanceConstant'HatInTime_Items.Capsules.Materials.Capsules_Inner_Red_WhiteBottom'
		Scale=3;
		CastShadow=false
		bAcceptsLights=false
		bAcceptsDynamicDominantLightShadows=false
		CollideActors=false
		BlockRigidBody=false
		bAcceptsStaticDecals=false
		bAcceptsDynamicDecals=false
		MaxDrawDistance = 3500;
		LightEnvironment=m_hLightEnvironment
		
        bUsePrecomputedShadows=false
        LightingChannels=(Static=FALSE,Dynamic=TRUE)
		Rotation = (Pitch = 24576);
		bDisableAllRigidBody = true;
		UseBoundsForDrawDistance = false;
		bAllowCullDistanceVolume = false;
		bUseAsOccluder = false;
	End Object
    Components.Add(CapsuleMesh);
	RotationComponents.Add(CapsuleMesh);
	Capsule=CapsuleMesh;
	
	HUDIcon = Texture2D'HatInTime_Hud2.Textures.health_pon';
	ScaleOnCollect = 0.25;
}