class Archipelago_RandomizedItem_BadgeNoFallDamage extends Archipelago_RandomizedItem_Badge;

defaultproperties
{
	InventoryClass = class'Hat_Ability_NoFallDamage';
  HUDIcon = Texture2D'HatInTime_Hud_Loadout.Item_Icons.itemicon_badge_hover'
	
    Begin Object Name=Model2
		Materials(0)=MaterialInstanceConstant'HatInTime_Items.Materials.Badges.badge_hover'
    End Object
}