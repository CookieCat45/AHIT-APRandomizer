class Archipelago_RandomizedItem_MetroTicketBlue extends Archipelago_RandomizedItem_Base;

defaultproperties
{
    Begin Object Class=StaticMeshComponent Name=Mesh1
        Materials(0)=MaterialInstanceConstant'hatintime_levels_metro_h.Materials.gate_card_blue'
		StaticMesh=StaticMesh'hatintime_levels_metro_h.models.metro_gate_card'
		bCastDynamicShadow=true
		CollideActors=false
		BlockRigidBody=false
		bAcceptsStaticDecals=false
		bAcceptsDynamicDecals=false
		MaxDrawDistance = 99900;
		LightEnvironment=m_hLightEnvironment
		bUsePrecomputedShadows=false
		LightingChannels=(Static=FALSE,Dynamic=TRUE)
		Rotation=(Roll=-8192)
		Scale=7
	End Object
	Components.Add(Mesh1);
	RotationComponents.Add(Mesh1);
	Mesh=Mesh1
	
	InventoryClass = class'Hat_Collectible_MetroTicket_RouteC';
	HUDIcon = Texture2D'HatInTime_Hud_ItemIcons3.MetroTicket_Blue';
}