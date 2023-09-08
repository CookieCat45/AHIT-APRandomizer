class Archipelago_RandomizedItem_BaseballBat extends Archipelago_RandomizedItem_Base;

defaultproperties
{
	Begin Object Name=Model
		SkeletalMesh = SkeletalMesh'HatInTime_Costumes3.SkeletalMesh.nyakuza_baseballbat'
		PhysicsAsset = PhysicsAsset'HatInTime_Costumes3.Physics.nyakuza_baseballbat_Physics'
		Materials(0) = None;
		Translation = (Z=-30);
		MaxDrawDistance = 99900;
	End Object
	
	InventoryClass = class'Archipelago_Weapon_BaseballBat';
	HUDIcon = Texture2D'HatInTime_Hud_ItemIcons3.NyakuzaBat';
}