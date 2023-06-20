class Archipelago_ItemResender extends Object;

`include(APRandomizer\Classes\Globals.uci);

var array<int> LocationsToResend;

function ResendLocations()
{
    if (LocationsToResend.Length == 0 || !`AP.IsFullyConnected())
        return;
    
    `AP.DebugMessage("Resending locations");
    `AP.SendMultipleLocationChecks(LocationsToResend);
    LocationsToResend.Length = 0;
}

function AddLocation(int location)
{
    if (LocationsToResend.Find(location) != -1)
        return;
    
    LocationsToResend.AddItem(location);
}

function AddMultipleLocations(array<int> locationList)
{
    local int i;
    for (i = 0; i < locationList.Length; i++)
    {
        if (LocationsToResend.Find(locationList[i]) != -1)
            continue;

        LocationsToResend.AddItem(locationList[i]);
    }
}