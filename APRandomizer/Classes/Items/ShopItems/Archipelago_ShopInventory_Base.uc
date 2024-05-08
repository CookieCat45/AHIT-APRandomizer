class Archipelago_ShopInventory_Base extends Hat_ShopInventory
    abstract;

// Because these two aren't AlwaysLoaded
var bool IsBadgeSeller;
var bool IsMafiaBoss;
var string ShopNPCName; // alternative if different shops use the same NPC class (Metro thugs)