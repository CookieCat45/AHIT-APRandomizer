class Archipelago_RandomizedItem_BadgeNoBonk extends Archipelago_RandomizedItem_Badge;

defaultproperties
{
	InventoryClass = class'Hat_Ability_NoBonk';
  HUDIcon = Texture2D'HatInTime_Hud_Loadout.Item_Icons.itemicon_badge_sprint'
	
    Begin Object Name=Model2
		Materials(0)=MaterialInstanceConstant'HatInTime_Items.Materials.Badges.badge_sprint'
    End Object
}