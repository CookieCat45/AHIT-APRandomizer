class Archipelago_RandomizedItem_Umbrella extends Archipelago_RandomizedItem_Base;

defaultproperties
{
	Begin Object Name=Model
		SkeletalMesh = SkeletalMesh'HatInTime_Weapons.models.umbrella_closed';
		//Rotation = (Pitch=-2048);
		Translation = (Z=-30);
	End Object
	
	InventoryClass = class'Archipelago_Weapon_Umbrella';
}