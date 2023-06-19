class Archipelago_BadgeSalesmanItem_Base extends Hat_Collectible_Important;
`include(APRandomizer\Classes\Globals.uci);

var int LocationID;
var string DisplayName;

simulated static function string GetLocalizedItemName()
{
	return default.DisplayName;
}

simulated function bool OnCollected(Actor Collector)
{
    if (`AP.IsFullyConnected())
    {
        `AP.SendLocationCheck(default.LocationID);
    }
    
    return Super.OnCollected(Collector);
}

defaultproperties
{
    CollectSound = None;
    DisplayName = "Item";
	HUDIcon = Texture2D'APRandomizer_content.ap_logo';
}