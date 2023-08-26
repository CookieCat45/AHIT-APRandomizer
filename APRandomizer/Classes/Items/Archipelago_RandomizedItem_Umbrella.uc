class Archipelago_RandomizedItem_Umbrella extends Archipelago_RandomizedItem_Base;

var Surface HUDIcon2;

defaultproperties
{
	Begin Object Name=Model
		SkeletalMesh = SkeletalMesh'HatInTime_Weapons.models.umbrella_closed';
		//Rotation = (Pitch=-2048);
		Translation = (Z=-30);
	End Object
	
	InventoryClass = class'Archipelago_Weapon_Umbrella';
	HUDIcon = Texture2D'HatInTime_Hud_Loadout.Item_Icons.umbrella_large';
	HUDIcon2 = Texture2D'HatInTime_Hud_ItemIcons3.NyakuzaBat';
}