class Archipelago_ShopItem_Base extends Hat_Collectible_Important
    abstract;

`include(APRandomizer\Classes\Globals.uci);

var const editconst bool NeedsDLC2;
var const editconst int LocationID;
var string DisplayName;
var string ItemNumberName;

simulated static function string GetLocalizedItemName()
{
	return default.DisplayName;
}

static function SetDisplayName(string newName)
{
    `GameManager.ConsoleCommand("set "$string(default.class) $" DisplayName "$newName);
}

static function SetHUDIcon(Surface Icon)
{
    `GameManager.ConsoleCommand("set "$string(default.class) $" HUDIcon "$Icon);
}

simulated function bool OnCollected(Actor Collector)
{
    `AP.SendLocationCheck(LocationID);
    return Super.OnCollected(Collector);
}

defaultproperties
{
    CollectSound = None;
    DisplayName = "Unknown Item";
    ItemNumberName = "";
    SaveGameOnCollect = true;
    IsBackpackItem = false;
    ShouldShowInBackpack = false;
	HUDIcon = Texture2D'APRandomizer_content.ap_logo';
}