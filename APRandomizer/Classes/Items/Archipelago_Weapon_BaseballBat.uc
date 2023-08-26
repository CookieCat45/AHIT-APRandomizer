class Archipelago_Weapon_BaseballBat extends Archipelago_Weapon_Umbrella;

`if(`isdefined(WITH_DLC2))
defaultproperties
{
	Components.Remove(Mesh1)
	Components.Remove(Mesh2)
	
	Begin Object Name=Mesh0
		SkeletalMesh = SkeletalMesh'HatInTime_Costumes3.SkeletalMesh.nyakuza_baseballbat'
		PhysicsAsset = PhysicsAsset'HatInTime_Costumes3.Physics.nyakuza_baseballbat_Physics'
		Materials(0) = None;
	End Object
	OpenMesh = None;
	ShaftMesh = None;
	CoopTexture = None;
	WeaponType = EWeapon_BaseballBat;
	
	HUDIcon = Texture2D'HatInTime_Hud_ItemIcons3.NyakuzaBat'
	WeaponName = "Weapon_Nyakuza_BaseballBat"
	WeaponDescription(0) = "Weapon_Nyakuza_BaseballBat_Shop"
	HitSound = SoundCue'HatinTime_SFX_Metro.SoundCues.Weapon_Baseball_Bat_General_Hit'
	SwingSound = SoundCue'HatinTime_SFX_Metro.SoundCues.Weapon_Baseball_Bat_Swing'
	IsUmbrellaWeapon = false;
	
	DmgTypeOverride = class'Hat_DamageType_BaseballBat'
}

function OnAttackParticle(ParticleSystemComponent PSC)
{
	PSC.SetMaterialParameter('Material', MaterialInstanceConstant'HatInTime_Costumes3.Materials.AttackSwing_BaseballBat');
}
`endif