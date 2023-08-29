class Archipelago_GameData extends Object;

var string Game;
var string Checksum;

struct immutable LocationMap
{
    var int ID;
    var string Location;
};

struct immutable ItemMap
{
    var int ID;
    var string Item;
};

var array<LocationMap> LocationMappings;
var array<ItemMap> ItemMappings;