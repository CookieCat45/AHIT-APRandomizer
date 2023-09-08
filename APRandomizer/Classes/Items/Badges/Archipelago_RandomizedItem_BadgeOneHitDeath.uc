class Archipelago_RandomizedItem_BadgeOneHitDeath extends Archipelago_RandomizedItem_Badge;

defaultproperties
{
	InventoryClass = class'Hat_Badge_OneHitDeath';
    HUDIcon = Texture2D'HatInTime_Hud_ItemIcons.Badges.badge_onehithero'
	
    Begin Object Name=Model2
		Materials(0)=MaterialInstanceConstant'HatInTime_Items.Materials.Badges.badge_onehithero'
    End Object
}