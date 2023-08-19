class Archipelago_SlotData extends Object
    dependson(Archipelago_ItemInfo);

var transient bool Initialized;
var array<ShuffledAct> ShuffledActList;
var array<LocationInfo> LocationInfoArray;
var array<ShopItemInfo> ShopItemList;
var array<string> PlayerNames;

var bool ConnectedOnce;

var int PlayerSlot;
var string SlotName;
var string Password;
var string Host;
var int Port;
var int Seed;
var int ShopItemRandStep;
var array<int> PageLocationIDs;
var bool TimePiecesCached;

var bool ActRando;
var bool ShuffleStorybookPages;
var bool ShuffleActContracts;
var bool ShuffleZiplines;
var bool ShuffleSubconPaintings;
var bool SDJLogic;
var bool UmbrellaLogic;
var bool DeathLink;

var bool DLC1;
var bool Tasksanity;
var int TasksanityTaskStep;
var int TasksanityCheckCount;
var int TaskStep;
var int CompletedTasks;

var bool DLC2;

var int CompassBadgeMode;

var int Chapter1Cost;
var int Chapter2Cost;
var int Chapter3Cost;
var int Chapter4Cost;
var int Chapter5Cost;
var int Chapter6Cost;

var int SprintYarnCost;
var int BrewingYarnCost;
var int IceYarnCost;
var int DwellerYarnCost;
var int TimeStopYarnCost;

var int MinPonCost;
var int MaxPonCost;

var array<Hat_ChapterActInfo> LockedBlueRifts;
var array< class<Hat_SnatcherContract_Act> > ObtainedContracts;
var array< class<Hat_SnatcherContract_Act> > TakenContracts;
var array< class<Hat_SnatcherContract_Act> > CheckedContracts;

var array<Name> UnlockedPaintings;

// hat stitch order
var EHatType Hat1;
var EHatType Hat2;
var EHatType Hat3;
var EHatType Hat4;
var EHatType Hat5;

defaultproperties
{
    Host="archipelago.gg";
    Port=56510;
}