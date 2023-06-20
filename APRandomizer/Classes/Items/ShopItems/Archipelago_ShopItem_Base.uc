class Archipelago_ShopItem_Base extends Hat_Collectible_Important
    abstract;

`include(APRandomizer\Classes\Globals.uci);

var const editconst int LocationID;
var string DisplayName;

simulated static function string GetLocalizedItemName()
{
	return default.DisplayName;
}

simulated function bool OnCollected(Actor Collector)
{
    `AP.SendLocationCheck(LocationID);
    return Super.OnCollected(Collector);
}

defaultproperties
{
    CollectSound = None;
    DisplayName = "Item";
    SaveGameOnCollect = true;
    IsBackpackItem = false;
    ShouldShowInBackpack = false;
	HUDIcon = Texture2D'APRandomizer_content.ap_logo';
}