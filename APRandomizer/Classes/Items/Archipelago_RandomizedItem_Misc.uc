// Item unknown or from a different AP game.
class Archipelago_RandomizedItem_Misc extends Archipelago_RandomizedItem_Base;

defaultproperties
{
	Begin Object Class=StaticMeshComponent Name=Model2
		StaticMesh = StaticMesh'HatInTime_Items.models.badge_standard';
		LightEnvironment=m_hLightEnvironment;
		Translation=(Z=10);
		Rotation = (Pitch=-8192);
		MaxDrawDistance = 6000;
		Scale=5.7;
		bAcceptsStaticDecals = false;
		bAcceptsDynamicDecals = false;
	End Object
	Mesh=Model2;
	Components.Add(Model2);
	RotationComponents.Add(Model2);
	
	HUDIcon = Texture2D'APRandomizer_content.ap_logo';
}