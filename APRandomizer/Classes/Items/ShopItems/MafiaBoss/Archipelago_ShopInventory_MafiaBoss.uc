class Archipelago_ShopInventory_MafiaBoss extends Archipelago_ShopInventory_Base;

defaultproperties
{
	IsMafiaBoss = true;
	ItemsForSale[0] = (CollectibleClass=class'Archipelago_ShopItem_MafiaBoss', ItemCost=25, PreventRePurchase=true);
}