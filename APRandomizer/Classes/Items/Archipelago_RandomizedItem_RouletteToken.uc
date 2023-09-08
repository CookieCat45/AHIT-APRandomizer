class Archipelago_RandomizedItem_RouletteToken extends Archipelago_RandomizedItem_Base;

defaultproperties
{
	Begin Object Class=StaticMeshComponent Name=Mesh1
		StaticMesh = StaticMesh'HatInTime_Items.models.Token';
		bCastDynamicShadow=true;
		CollideActors=false;
		BlockRigidBody=false;
		bAcceptsStaticDecals=false;
		bAcceptsDynamicDecals=false;
		MaxDrawDistance = 99900;
		LightEnvironment=m_hLightEnvironment;
		
        bUsePrecomputedShadows=false;
        LightingChannels=(Static=FALSE,Dynamic=TRUE);
		Rotation = (Roll=-8192);
	End Object
    Components.Add(Mesh1);
	RotationComponents.Add(Mesh1);
	Mesh=Mesh1;
	
	InventoryClass = class'Hat_Collectible_RouletteToken';
}