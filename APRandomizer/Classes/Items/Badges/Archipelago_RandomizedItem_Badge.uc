class Archipelago_RandomizedItem_Badge extends Archipelago_RandomizedItem_Base;

defaultproperties
{
	Begin Object Class=StaticMeshComponent Name=Model2
		StaticMesh = StaticMesh'HatInTime_Items.models.badge_standard';
		LightEnvironment=m_hLightEnvironment;
		Translation=(Z=10);
		Rotation = (Pitch=-8192);
		MaxDrawDistance = 99900;
		Scale=5.7;
		bAcceptsStaticDecals = false;
		bAcceptsDynamicDecals = false;
	End Object
	Mesh=Model2;
	Components.Add(Model2);
	RotationComponents.Add(Model2);
	
	ScaleOnCollect = 1.0;
}