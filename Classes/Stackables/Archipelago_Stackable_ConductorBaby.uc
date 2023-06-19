class Archipelago_Stackable_ConductorBaby extends Archipelago_Stackable_Base;

var int CostumeID;
var StaticMeshComponent Knife;

function OnSpawn()
{
	SetCostume();
}

function OnDespawn()
{
	CostumeID = -1;
}

function OnPickUp(Actor p)
{
	Super.OnPickUp(p);
	PlaySound(SoundCue'HatinTime_SFX_Cruise.SoundCues.Conductor_Baby_Pickup1');
}

function OnCompleteDelivery()
{
	Super.OnCompleteDelivery();
	PlaySound(SoundCue'HatinTime_SFX_Cruise.SoundCues.Conductor_Baby_Pickup1');
}

function SetCostume(optional int id = -1)
{
	local Array<int> available;
	local int i;
	local Actor a;

	// randomize costume (avoid duplicates)
	if (id == -1)
	{
		for (i = 0; i < 5; i++)
			available.AddItem(i);

		foreach DynamicActors(class'Actor', a)
		{
			if (Archipelago_Stackable_ConductorBaby(a) == None) continue;
			if (Archipelago_Stackable_ConductorBaby(a).CostumeID == -1) continue;
			available.RemoveItem(Archipelago_Stackable_ConductorBaby(a).CostumeID);
		}

		id = available.Length > 0 ? available[Rand(available.Length)] : Rand(5);
	}

	CostumeID = id;

	`if(`isdefined(WITH_DLC1))
	Knife.SetHidden(true);
	switch (CostumeID)
	{
		case 1: // Stripe
			Mesh.SetMaterial(0, Material'HatInTime_Characters.Materials.Invisible');
			Mesh.SetMaterial(1, Material'HatInTime_Characters.Materials.Invisible');
			Mesh.SetMaterial(2, Material'HatInTime_Characters.Materials.Invisible');
			Mesh.SetMaterial(3, Material'HatinTime_Characters_Grandkid.Materials.grandkid_stripedeshirt');
			Mesh.SetMaterial(4, Material'HatInTime_Characters.Materials.Invisible');
			break;
		case 2: // Pacifier
			Mesh.SetMaterial(0, Material'HatInTime_Characters.Materials.Invisible');
			Mesh.SetMaterial(1, Material'HatinTime_Characters_Grandkid.Materials.grandkid_pacifier');
			Mesh.SetMaterial(2, Material'HatInTime_Characters.Materials.Invisible');
			Mesh.SetMaterial(3, Material'HatInTime_Characters.Materials.Invisible');
			Mesh.SetMaterial(4, Material'HatInTime_Characters.Materials.Invisible');
			break;
		case 3: // Cute
			Mesh.SetMaterial(0, Material'HatinTime_Characters_Grandkid.Materials.grandkid_strawhat');
			Mesh.SetMaterial(1, Material'HatInTime_Characters.Materials.Invisible');
			Mesh.SetMaterial(2, Material'HatInTime_Characters.Materials.Invisible');
			Mesh.SetMaterial(3, Material'HatinTime_Characters_Grandkid.Materials.grandkid_pinkshirt');
			Mesh.SetMaterial(4, Material'HatInTime_Characters.Materials.Invisible');
			break;
		case 4: // Sailor
			Mesh.SetMaterial(0, Material'HatInTime_Characters.Materials.Invisible');
			Mesh.SetMaterial(1, Material'HatInTime_Characters.Materials.Invisible');
			Mesh.SetMaterial(2, Material'HatinTime_Characters_Grandkid.Materials.grandkid_sailorhat');
			Mesh.SetMaterial(3, Material'HatinTime_Characters_Grandkid.Materials.grandkid_whiteshirt');
			Mesh.SetMaterial(4, Material'HatInTime_Characters.Materials.Invisible');
			break;
		default: // Grandpa's Favorite
			Mesh.SetMaterial(0, Material'HatInTime_Characters.Materials.Invisible');
			Mesh.SetMaterial(1, Material'HatInTime_Characters.Materials.Invisible');
			Mesh.SetMaterial(2, Material'HatInTime_Characters.Materials.Invisible');
			Mesh.SetMaterial(3, Material'HatInTime_Characters.Materials.Invisible');
			Mesh.SetMaterial(4, Material'HatinTime_Characters_Grandkid.Materials.grandkid_condhat');
			Knife.SetHidden(false);// let me see what you have
			SkeletalMeshComponent(Mesh).AttachComponentToSocket(Knife, 'Knife');// NO!!!
			break;
	}
	`endif
}

`if(`isdefined(WITH_DLC1))
defaultproperties
{
	Begin Object Name=SkeletalMeshComponent0
		SkeletalMesh=SkeletalMesh'HatinTime_Characters_Grandkid.SkeletalMeshes.Conductor_Grandkid'
		PhysicsAsset=PhysicsAsset'HatinTime_Characters_Grandkid.Physics.Conductor_Grandkid_Physics'
		AnimSets(0)=AnimSet'HatinTime_Characters_Grandkid.AnimSets.Conductor_Grandkid_Anims'
		AnimTreeTemplate=AnimTree'HatinTime_Characters_Grandkid.AnimTrees.Conductor_GrandKid_AnimTree'
	End Object

	`if(`isdefined(WITH_DLC1))
	Begin Object Class=StaticMeshComponent Name=KnifeMesh0
		StaticMesh=StaticMesh'HatInTime_Levels_Murder_Mecha.models.Objects.knife'
		LightEnvironment=m_hLightEnvironment
		CanBlockCamera=false
		BlockActors=true
		CollideActors=true
		MaxDrawDistance=6000
		BlockZeroExtent=false
		BlockNonZeroExtent=false
		CanBeEdgeGrabbed=false
		HiddenGame=true
		HiddenEditor=true
	End Object
	Components.Add(KnifeMesh0);
	Knife = KnifeMesh0;
	`endif

	StackHeight = 35
	StackOffset = -15
	StackDistance = 5

	CostumeID = -1
}
`endif