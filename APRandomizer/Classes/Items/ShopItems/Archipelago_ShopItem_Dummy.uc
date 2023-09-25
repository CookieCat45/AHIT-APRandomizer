// Not an actual shop item, just a dummy item to trick shops into thinking they aren't sold out.
class Archipelago_ShopItem_Dummy extends Hat_Collectible_Important;

simulated static function string GetLocalizedItemName()
{
	return "Do Not Delete";
}
