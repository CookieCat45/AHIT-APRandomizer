class Archipelago_GameData extends Object
    deprecated;

var string Game;
var string Checksum;

// IDs from other games have to be strings because UnrealScript only supports 32 bit integers

// Deprecated
struct immutable LocationMap
{
    var string ID;
    var string Location;
};

struct immutable ItemMap
{
    var string ID;
    var string Item;
};

var array<LocationMap> LocationMappings;
var array<ItemMap> ItemMappings;