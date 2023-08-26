class Archipelago_RandomizedItem_Decoration extends Archipelago_RandomizedItem_Base;

defaultproperties
{
	Begin Object Class=StaticMeshComponent Name=Model2
		StaticMesh = StaticMesh'HatinTime_TreasureChests.models.present_closed';
		LightEnvironment=m_hLightEnvironment;
		Translation=(Z=-22);
		Rotation = (Pitch=-819);
		MaxDrawDistance = 9000;
		Scale=0.9;
		bNoSelfShadow=true;
	End Object
	Mesh=Model2;
	RotationComponents.Add(Model2);
	Components.Add(Model2);
	
	HUDIcon = Texture2D'HatInTime_Hud_ItemIcons.Decorations.decoration_present';
}