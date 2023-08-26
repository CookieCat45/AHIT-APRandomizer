class Archipelago_RandomizedItem_BadgeHatCooldownBonus extends Archipelago_RandomizedItem_Badge;

defaultproperties
{
	InventoryClass = class'Hat_Ability_HatCooldownBonus';
  HUDIcon = Texture2D'HatInTime_Hud_Loadout.Item_Icons.itemicon_badge_teenangst'
	
    Begin Object Name=Model2
		Materials(0)=MaterialInstanceConstant'HatInTime_Items.Materials.Badges.badge_teenangst'
    End Object
}