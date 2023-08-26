class Archipelago_RandomizedItem_MetroTicketYellow extends Archipelago_RandomizedItem_Base;

defaultproperties
{
    Begin Object Class=StaticMeshComponent Name=Mesh1
        Materials(0)=Material'hatintime_levels_metro_h.Materials.gate_card'
		StaticMesh=StaticMesh'hatintime_levels_metro_h.models.metro_gate_card'
		bCastDynamicShadow=true
		CollideActors=false
		BlockRigidBody=false
		bAcceptsStaticDecals=false
		bAcceptsDynamicDecals=false
		MaxDrawDistance=6000
		LightEnvironment=m_hLightEnvironment
		bUsePrecomputedShadows=false
		LightingChannels=(Static=FALSE,Dynamic=TRUE)
		Rotation=(Roll=-8192)
		Scale=6
	End Object
	Mesh=Mesh1
	Components.Add(Mesh1);
	RotationComponents.Add(Mesh1);
	
	InventoryClass = class'Hat_Collectible_MetroTicket_RouteA';
	HUDIcon = Texture2D'HatInTime_Hud_ItemIcons3.MetroTicket_Yellow';
}