class Archipelago_RandomizedItem_TimeStop extends Archipelago_RandomizedItem_Base;

defaultproperties
{
    InventoryClass = class'Hat_Ability_TimeStop';
	HUDIcon = Texture2D'HatInTime_Hud_ItemIcons.Hats.widow_hat';
    Begin Object Class=StaticMeshComponent Name=Mesh0
		StaticMesh = StaticMesh'HatInTime_Costumes.models.time_stop_hat_static'
		bOnlyOwnerSee=false
		CastShadow=true
		bCastDynamicShadow=true
		CollideActors=false
		BlockRigidBody=false
		bAcceptsStaticDecals=false
		bAcceptsDynamicDecals=false
		
        bUsePrecomputedShadows=false
        LightingChannels=(Static=FALSE,Dynamic=TRUE)
	End Object
    Mesh = Mesh0;
	Components.Add(Mesh0);
    RotationComponents.Add(Mesh0);
}