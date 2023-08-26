class Archipelago_ShopInventory_MafiaBoss extends Archipelago_ShopInventory_Base;

defaultproperties
{
	ShopNPC = class'Hat_NPC_MafiaBossJar';
	ItemsForSale[0] = (CollectibleClass=class'Archipelago_ShopItem_MafiaBoss', ItemCost=25, PreventRePurchase=true);
}