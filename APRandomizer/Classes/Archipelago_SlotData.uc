class Archipelago_SlotData extends Object
    dependson(Archipelago_ItemInfo);

var transient bool Initialized;
var array<ShuffledAct> ShuffledActList;

var bool ConnectedOnce;

var int PlayerSlot;
var string SlotName;
var string Password;
var string Host;
var int Port;

var bool ActRando;
var bool ShuffleStorybookPages;
var bool DeathLink;

var int Chapter1Cost;
var int Chapter2Cost;
var int Chapter3Cost;
var int Chapter4Cost;
var int Chapter5Cost;

var int SprintYarnCost;
var int BrewingYarnCost;
var int IceYarnCost;
var int DwellerYarnCost;
var int TimeStopYarnCost;

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