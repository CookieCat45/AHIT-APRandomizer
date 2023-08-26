class Archipelago_RandomizedItem_BadgeSuckInOrbs extends Archipelago_RandomizedItem_Badge;

defaultproperties
{
	InventoryClass = class'Hat_Badge_SuckInOrbs';
  HUDIcon = Texture2D'HatInTime_Hud_ItemIcons.Badges.badge_itemmagnet';
	
    Begin Object Name=Model2
		Materials(0)=MaterialInstanceConstant'HatInTime_Items.Materials.Badges.badge_itemmagnet'
    End Object
}