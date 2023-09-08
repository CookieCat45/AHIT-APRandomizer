/**
 * This class stores information about items as they pertain to the game's Archipelago world.
 * Use the functions below to retreive item data such as name, actor class in game, inventory class given by the item, etc.
 */
class Archipelago_ItemInfo extends Info
	abstract;
	
`include(APRandomizer\Classes\Globals.uci);

// Unrealscript... let me use = in an enum. Come on.
enum EItemFlags
{
	ItemFlag_Garbage, // 0
	ItemFlag_Important, // 1
	ItemFlag_Useful, // 2
	aaaaa,
	ItemFlag_Trap, // 4
	bbbbb,
	ccccc,
	ddddd,
	eeeee,
	ItemFlag_ImportantSkipBalancing // 9
};

// Used with slot data
enum EHatType
{
	HatType_Sprint,
	HatType_Brewing,
	HatType_Ice,
	HatType_Dweller,
	HatType_TimeStop,
};

enum ESpecialItemType
{
	SpecialType_None,
	SpecialType_25Pons,
	SpecialType_50Pons,
	SpecialType_100Pons,
	SpecialType_HealthPon,
	SpecialType_Cosmetic,
};

enum ETrapType
{
	TrapType_None,
	TrapType_Baby,
	TrapType_Laser,
	TrapType_Parade,
};

enum EZiplineType
{
	Zipline_Birdhouse,
	Zipline_LavaCake,
	Zipline_Windmill,
	Zipline_Bell,
};

const YarnItem = 300001;
const TimePieceItem = 300002;

const Pons25Item = 300034;
const Pons50Item = 300035;
const Pons100Item = 300036;
const HealthPonItem = 300037;

const BabyTrapItem = 300039;
const LaserTrapItem = 300040;
const ParadeTrapItem = 300041;
const RandomCosmeticItem = 300044;

static function int GetYarnItemID()
{
	return YarnItem;
}

static function int GetTimePieceItemID()
{
	return TimePieceItem;
}

static function ETrapType GetItemTrapType(int itemId)
{
	switch (itemId)
	{
		case BabyTrapItem:
			return TrapType_Baby;
			
		case LaserTrapItem:
			return TrapType_Laser;
			
		case ParadeTrapItem:
			return TrapType_Parade;
			
		default:
			return TrapType_None;
	}
}

static function ESpecialItemType GetItemSpecialType(int itemId)
{
	switch (itemId)
	{
		case Pons25Item:
			return SpecialType_25Pons;
			
		case Pons50Item:
			return SpecialType_50Pons;
			
		case Pons100Item:
			return SpecialType_100Pons;
			
		case HealthPonItem:
			return SpecialType_HealthPon;
		
		case RandomCosmeticItem:
			return SpecialType_Cosmetic;
			
		default:
			return SpecialType_None;
	}
}

/**
 * Returns true if the item ID belongs to A Hat in Time.
 * Returns the rest of the data pertaining to said ID (name, associated class, etc.) in the "out" arguments.
 */
static function bool GetNativeItemData(int itemId, // Archipelago item ID
optional out string itemName, // Display name
optional out class<Actor> worldClass, // Item in the world
optional out class<Actor> inventoryOverride) // Item inventory class override. Mainly for relics.
{
	switch (itemId)
	{
		case YarnItem:
			itemName = "Yarn";
			worldClass = class'Archipelago_RandomizedItem_Yarn';
			return true;
		
		case TimePieceItem:
			itemName = "Time Piece";
			worldClass = class'Archipelago_RandomizedItem_TimeObject';
			return true;
		
		
		// --------- RELICS -------------------------------------------------------------------------------------------- \\
		
		case 300006:
			itemName = "Relic (Burger Patty)";
			worldClass = class'Archipelago_RandomizedItem_Decoration';
			inventoryOverride = class'Hat_Collectible_Decoration_BurgerBottom';
			return true;
		
		case 300007:
			itemName = "Relic (Burger Cushion)";
			worldClass = class'Archipelago_RandomizedItem_Decoration';
			inventoryOverride = class'Hat_Collectible_Decoration_BurgerTop';
			return true;
			
		case 300008:
			itemName = "Relic (Mountain Set)";
			worldClass = class'Archipelago_RandomizedItem_Decoration';
			inventoryOverride = class'Hat_Collectible_Decoration_TrainTracks';
			return true;
			
		case 300009:
			itemName = "Relic (Train)";
			worldClass = class'Archipelago_RandomizedItem_Decoration';
			inventoryOverride = class'Hat_Collectible_Decoration_Train';
			return true;
			
		case 300010:
			itemName = "Relic (UFO)";
			worldClass = class'Archipelago_RandomizedItem_Decoration';
			inventoryOverride = class'Hat_Collectible_Decoration_UFO';
			return true;
			
		case 300011:
			itemName = "Relic (Cow)";
			worldClass = class'Archipelago_RandomizedItem_Decoration';
			inventoryOverride = class'Hat_Collectible_Decoration_ToyCowA';
			return true;
			
		case 300012:
			itemName = "Relic (Cool Cow)";
			worldClass = class'Archipelago_RandomizedItem_Decoration';
			inventoryOverride = class'Hat_Collectible_Decoration_ToyCowB';
			return true;
		
		case 300013:
			itemName = "Relic (Tin-foil Hat Cow)";
			worldClass = class'Archipelago_RandomizedItem_Decoration';
			inventoryOverride = class'Hat_Collectible_Decoration_ToyCowC';
			return true;
			
		case 300014:
			itemName = "Relic (Crayon Box)";
			worldClass = class'Archipelago_RandomizedItem_Decoration';
			inventoryOverride = class'Hat_Collectible_Decoration_CrayonBox';
			return true;
			
		case 300015:
			itemName = "Relic (Red Crayon)";
			worldClass = class'Archipelago_RandomizedItem_Decoration';
			inventoryOverride = class'Hat_Collectible_Decoration_CrayonRed';
			return true;
			
		case 300016:
			itemName = "Relic (Blue Crayon)";
			worldClass = class'Archipelago_RandomizedItem_Decoration';
			inventoryOverride = class'Hat_Collectible_Decoration_CrayonBlue';
			return true;
			
		case 300017:
			itemName = "Relic (Green Crayon)";
			worldClass = class'Archipelago_RandomizedItem_Decoration';
			inventoryOverride = class'Hat_Collectible_Decoration_CrayonGreen';
			return true;
		
		case 300018:
			itemName = "Relic (Cake Stand)";
			worldClass = class'Archipelago_RandomizedItem_Decoration';
			inventoryOverride = class'Hat_Collectible_Decoration_CakeTower';
			return true;

		case 300019:
			itemName = "Relic (Cake)";
			worldClass = class'Archipelago_RandomizedItem_Decoration';
			inventoryOverride = class'Hat_Collectible_Decoration_CakeA';
			return true;
		
		case 300020:
			itemName = "Relic (Cake Slice)";
			worldClass = class'Archipelago_RandomizedItem_Decoration';
			inventoryOverride = class'Hat_Collectible_Decoration_CakeB';
			return true;
		
		case 300021:
			itemName = "Relic (Shortcake)";
			worldClass = class'Archipelago_RandomizedItem_Decoration';
			inventoryOverride = class'Hat_Collectible_Decoration_CakeC';
			return true;

		case 300022:
			itemName = "Relic (Necklace Bust)";
			worldClass = class'Archipelago_RandomizedItem_Decoration';
			inventoryOverride = class'Hat_Collectible_Decoration_JewelryDisplay';
			return true;
		
		case 300023:
			itemName = "Relic (Necklace)";
			worldClass = class'Archipelago_RandomizedItem_Decoration';
			inventoryOverride = class'Hat_Collectible_Decoration_GoldNecklace';
			return true;
			
			
		// -------- BADGES ----------------------------------------------------------------------------------------------- \\	
		
		case 300024:
			itemName = "Projectile Badge";
			worldClass = class'Archipelago_RandomizedItem_BadgeProjectile';
			return true;
			
		case 300025:
			itemName = "Fast Hatter Badge";
			worldClass = class'Archipelago_RandomizedItem_BadgeHatCooldownBonus';
			return true;
			
		case 300026:
			itemName = "Hover Badge";
			worldClass = class'Archipelago_RandomizedItem_BadgeNoFallDamage';
			return true;
			
		case 300027:
			itemName = "Hookshot Badge";
			worldClass = class'Archipelago_RandomizedItem_BadgeHookshot';
			return true;
			
		case 300028:
			itemName = "Item Magnet Badge";
			worldClass = class'Archipelago_RandomizedItem_BadgeSuckInOrbs';
			return true;
			
		case 300029:
			itemName = "No Bonk Badge";
			worldClass = class'Archipelago_RandomizedItem_BadgeNoBonk';
			return true;
			
		case 300030:
			itemName = "Compass Badge";
			worldClass = class'Archipelago_RandomizedItem_BadgeRelicFinder';
			return true;
			
		case 300031:
			itemName = "Scooter Badge";
			worldClass = class'Archipelago_RandomizedItem_BadgeScooter';
			return true;
		
		case 300038:
			itemName = "One-Hit Hero Badge";
			worldClass = class'Archipelago_RandomizedItem_BadgeOneHitDeath';
			return true;
		
		case 300042:
			itemName = "Camera Badge";
			worldClass = class'Archipelago_RandomizedItem_BadgeCamera';
			return true;
		
		
		// --------- SPECIAL/TRAPS --------------------------------------------------------------------------------------- \\
		
		case Pons25Item:
			itemName = "25 Pons";
			worldClass = class'Archipelago_RandomizedItem_Pons';
			return true;
			
		case Pons50Item:
			itemName = "50 Pons";
			worldClass = class'Archipelago_RandomizedItem_Pons';
			return true;
			
		case Pons100Item:
			itemName = "100 Pons";
			worldClass = class'Archipelago_RandomizedItem_Pons';
			return true;
			
		case HealthPonItem:
			itemName = "Health Pon";
			worldClass = class'Archipelago_RandomizedItem_HealthPon';
			return true;
			
		case BabyTrapItem:
			itemName = "Baby Trap";
			worldClass = class'Archipelago_RandomizedItem_Misc';
			return true;
			
		case LaserTrapItem:
			itemName = "Laser Trap";
			worldClass = class'Archipelago_RandomizedItem_Misc';
			return true;
			
		case ParadeTrapItem:
			itemName = "Parade Trap";
			worldClass = class'Archipelago_RandomizedItem_Misc';
			return true;
		
		case RandomCosmeticItem:
			itemName = "Random Cosmetic";
			worldClass = class'Archipelago_RandomizedItem_Misc';
			return true;
			
		// --------- MISC ---------------------------------------------------------------------------------------------- \\
			
		case 300032:
			itemName = "Rift Token";
			worldClass = class'Archipelago_RandomizedItem_RouletteToken';
			return true;
			
		case 300033:
			if (`AP.SlotData.BaseballBat && `AP.IsDLC2Installed())
			{
				itemName = "Baseball Bat";
				worldClass = class'Archipelago_RandomizedItem_BaseballBat';
			}
			else
			{
				itemName = "Umbrella";
				worldClass = class'Archipelago_RandomizedItem_Umbrella';
			}
			
			return true;
		
		case 300043:
			itemName = "Badge Pin";
			worldClass = class'Archipelago_RandomizedItem_BadgePin';
			return true;
		
		case 300200:
			itemName = "Snatcher's Contract (The Subcon Well)";
			worldClass = class'Archipelago_RandomizedItem_Contract';
			return true;
		
		case 300201:
			itemName = "Snatcher's Contract (Toilet of Doom)";
			worldClass = class'Archipelago_RandomizedItem_Contract';
			return true;
		
		case 300202:
			itemName = "Snatcher's Contract (Queen Vanessa's Manor)";
			worldClass = class'Archipelago_RandomizedItem_Contract';
			return true;

		case 300203:
			itemName = "Snatcher's Contract (Mail Delivery Service)";
			worldClass = class'Archipelago_RandomizedItem_Contract';
			return true;
		
		case 300204:
			itemName = "Zipline Unlock (The Birdhouse Path)";
			worldClass = class'Archipelago_RandomizedItem_Misc';
			return true;
		
		case 300205:
			itemName = "Zipline Unlock (The Lava Cake Path)";
			worldClass = class'Archipelago_RandomizedItem_Misc';
			return true;
		
		case 300206:
			itemName = "Zipline Unlock (The Windmill Path)";
			worldClass = class'Archipelago_RandomizedItem_Misc';
			return true;
		
		case 300207:
			itemName = "Zipline Unlock (The Twilight Bell Path)";
			worldClass = class'Archipelago_RandomizedItem_Misc';
			return true;
		
		case 300003:
			itemName = "Progressive Painting Unlock";
			worldClass = class'Archipelago_RandomizedItem_Misc';
			return true;
		
		case 300045:
			itemName = "Metro Ticket - Yellow";
			worldClass = class'Archipelago_RandomizedItem_MetroTicketYellow';
			return true;
		
		case 300046:
			itemName = "Metro Ticket - Green";
			worldClass = class'Archipelago_RandomizedItem_MetroTicketGreen';
			return true;
		
		case 300047:
			itemName = "Metro Ticket - Blue";
			worldClass = class'Archipelago_RandomizedItem_MetroTicketBlue';
			return true;
		
		case 300048:
			itemName = "Metro Ticket - Pink";
			worldClass = class'Archipelago_RandomizedItem_MetroTicketPink';
			return true;
		
		default:
			worldClass = class'Archipelago_RandomizedItem_Misc';
			return false;
	}
}

// Contract location IDs and item IDs are the same for each
static function int GetContractID(class<Hat_SnatcherContract_Act> contract)
{
	switch (contract)
	{
		case class'Hat_SnatcherContract_IceWall':
			return 300200;
		
		case class'Hat_SnatcherContract_Toilet':
			return 300201;
		
		case class'Hat_SnatcherContract_Vanessa':
			return 300202;
		
		case class'Hat_SnatcherContract_MailDelivery':
			return 300203;

		default:
			return 0;
	}
}

static function class<Hat_SnatcherContract_Act> GetContractFromID(int id)
{
	switch (id)
	{
		case 300200:
			return class'Hat_SnatcherContract_IceWall';
		
		case 300201:
			return class'Hat_SnatcherContract_Toilet';
		
		case 300202:
			return class'Hat_SnatcherContract_Vanessa';
		
		case 300203:
			return class'Hat_SnatcherContract_MailDelivery';

		default:
			return None;
	}
}

// full clear location IDs are +1
static function int GetDeathWishLocationID(class<Hat_SnatcherContract_DeathWish> contract)
{
	switch (contract)
	{
		case class'Hat_SnatcherContract_DeathWish_HeatingUpHarder':
			return 350000;
		
		case class'Hat_SnatcherContract_DeathWish_KillEverybody':
			return 350002;
		
		case class'Hat_SnatcherContract_DeathWish_BackFromSpace':
			return 350004;
		
		case class'Hat_SnatcherContract_DeathWish_PonFrenzy':
			return 350006;
		
		case class'Hat_SnatcherContract_DeathWish_RiftCollapse_MafiaTown':
			return 350008;
		
		case class'Hat_SnatcherContract_DeathWish_Speedrun_MafiaAlien':
			return 350010;
		
		case class'Hat_SnatcherContract_DeathWish_NoAPresses_MafiaAlien':
			return 350012;

		case class'Hat_SnatcherContract_DeathWish_MovingVault':
			return 350014;

		case class'Hat_SnatcherContract_DeathWish_MafiaBossEX':
			return 350016;
		
		case class'Hat_SnatcherContract_DeathWish_Tokens_MafiaTown':
			return 350018;
	
		case class'Hat_SnatcherContract_DeathWish_DeadBirdStudioMoreGuards':
			return 350020;

		case class'Hat_SnatcherContract_DeathWish_DifficultParade':
			return 350022;

		case class'Hat_SnatcherContract_DeathWish_RiftCollapse_Birds':
			return 350024;
		
		case class'Hat_SnatcherContract_DeathWish_TrainRushShortTime':
			return 350026;
		
		case class'Hat_SnatcherContract_DeathWish_BirdBossEX':
			return 350028;

		case class'Hat_SnatcherContract_DeathWish_Tokens_Birds':
			return 350030;
		
		case class'Hat_SnatcherContract_DeathWish_NoAPresses':
			return 350032;
	
		case class'Hat_SnatcherContract_DeathWish_Speedrun_SubWell':
			return 350034;

		case class'Hat_SnatcherContract_DeathWish_RiftCollapse_Subcon':
			return 350036;
	
		case class'Hat_SnatcherContract_DeathWish_BossRush':
			return 350038;

		case class'Hat_SnatcherContract_DeathWish_SurvivalOfTheFittest':
			return 350040;
		
		case class'Hat_SnatcherContract_DeathWish_SnatcherEX':
			return 350042;

		case class'Hat_SnatcherContract_DeathWish_Tokens_Subcon':
			return 350044;

		case class'Hat_SnatcherContract_DeathWish_NiceBirdhouse':
			return 350046;

		case class'Hat_SnatcherContract_DeathWish_RiftCollapse_Alps':
			return 350048;

		case class'Hat_SnatcherContract_DeathWish_FastWindmill':
			return 350050;

		case class'Hat_SnatcherContract_DeathWish_Speedrun_Illness':
			return 350052;

		case class'Hat_SnatcherContract_DeathWish_Tokens_Alps':
			return 350054;
		
		case class'Hat_SnatcherContract_DeathWish_CameraTourist_1':
			return 350056;

		case class'Hat_SnatcherContract_DeathWish_HardCastle':
			return 350058;

		case class'Hat_SnatcherContract_DeathWish_MuGirlEX':
			return 350060;

		case class'Hat_SnatcherContract_DeathWish_BossRushEX':
			return 350062;

		case class'Hat_SnatcherContract_DeathWish_RiftCollapse_Cruise':
			return 350064;

		case class'Hat_SnatcherContract_DeathWish_EndlessTasks':
			return 350066;

		case class'Hat_SnatcherContract_DeathWish_CommunityRift_RhythmJump':
			return 350068;

		case class'Hat_SnatcherContract_DeathWish_CommunityRift_TwilightTravels':
			return 350070;
		
		case class'Hat_SnatcherContract_DeathWish_CommunityRift_MountainRift':
			return 350072;
		
		case class'Hat_SnatcherContract_DeathWish_Tokens_Metro':
			return 350074;
	}

	return -1;
}