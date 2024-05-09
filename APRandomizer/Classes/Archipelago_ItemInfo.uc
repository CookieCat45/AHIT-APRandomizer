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

const YarnItem = 2000300001;
const TimePieceItem = 2000300002;

const Pons25Item = 2000300034;
const Pons50Item = 2000300035;
const Pons100Item = 2000300036;
const HealthPonItem = 2000300037;

const BabyTrapItem = 2000300039;
const LaserTrapItem = 2000300040;
const ParadeTrapItem = 2000300041;
const RandomCosmeticItem = 2000300044;

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
static function bool GetNativeItemData(string itemId, // Archipelago item ID
optional out class<Actor> worldClass, // Item in the world
optional out class<Actor> inventoryOverride) // Item inventory class override. Mainly for relics.
{
	switch (int(itemId))
	{
		case YarnItem:
			worldClass = class'Archipelago_RandomizedItem_Yarn';
			return true;
		
		case TimePieceItem:
			worldClass = class'Archipelago_RandomizedItem_TimeObject';
			return true;
		
		// Hats for HatItems setting
		case 2000300049:
			worldClass = class'Archipelago_RandomizedItem_Sprint';
			return true;
		
		case 2000300050:
			worldClass = class'Archipelago_RandomizedItem_Chemical';
			return true;

		case 2000300051:
			worldClass = class'Archipelago_RandomizedItem_Ice';
			return true;
		
		case 2000300052:
			worldClass = class'Archipelago_RandomizedItem_Dweller';
			return true;
		
		case 2000300053:
			worldClass = class'Archipelago_RandomizedItem_TimeStop';
			return true;
		
		
		// --------- RELICS -------------------------------------------------------------------------------------------- \\
		
		case 2000300006:
			worldClass = class'Archipelago_RandomizedItem_Decoration';
			inventoryOverride = class'Hat_Collectible_Decoration_BurgerBottom';
			return true;
		
		case 2000300007:
			worldClass = class'Archipelago_RandomizedItem_Decoration';
			inventoryOverride = class'Hat_Collectible_Decoration_BurgerTop';
			return true;
			
		case 2000300008:
			worldClass = class'Archipelago_RandomizedItem_Decoration';
			inventoryOverride = class'Hat_Collectible_Decoration_TrainTracks';
			return true;
			
		case 2000300009:
			worldClass = class'Archipelago_RandomizedItem_Decoration';
			inventoryOverride = class'Hat_Collectible_Decoration_Train';
			return true;
			
		case 2000300010:
			worldClass = class'Archipelago_RandomizedItem_Decoration';
			inventoryOverride = class'Hat_Collectible_Decoration_UFO';
			return true;
			
		case 2000300011:
			worldClass = class'Archipelago_RandomizedItem_Decoration';
			inventoryOverride = class'Hat_Collectible_Decoration_ToyCowA';
			return true;
			
		case 2000300012:
			worldClass = class'Archipelago_RandomizedItem_Decoration';
			inventoryOverride = class'Hat_Collectible_Decoration_ToyCowB';
			return true;
		
		case 2000300013:
			worldClass = class'Archipelago_RandomizedItem_Decoration';
			inventoryOverride = class'Hat_Collectible_Decoration_ToyCowC';
			return true;
			
		case 2000300014:
			worldClass = class'Archipelago_RandomizedItem_Decoration';
			inventoryOverride = class'Hat_Collectible_Decoration_CrayonBox';
			return true;
			
		case 2000300015:
			worldClass = class'Archipelago_RandomizedItem_Decoration';
			inventoryOverride = class'Hat_Collectible_Decoration_CrayonRed';
			return true;
			
		case 2000300016:
			worldClass = class'Archipelago_RandomizedItem_Decoration';
			inventoryOverride = class'Hat_Collectible_Decoration_CrayonBlue';
			return true;
			
		case 2000300017:
			worldClass = class'Archipelago_RandomizedItem_Decoration';
			inventoryOverride = class'Hat_Collectible_Decoration_CrayonGreen';
			return true;
		
		case 2000300018:
			worldClass = class'Archipelago_RandomizedItem_Decoration';
			inventoryOverride = class'Hat_Collectible_Decoration_CakeTower';
			return true;

		case 2000300019:
			worldClass = class'Archipelago_RandomizedItem_Decoration';
			inventoryOverride = class'Hat_Collectible_Decoration_CakeA';
			return true;
		
		case 2000300020:
			worldClass = class'Archipelago_RandomizedItem_Decoration';
			inventoryOverride = class'Hat_Collectible_Decoration_CakeB';
			return true;
		
		case 2000300021:
			worldClass = class'Archipelago_RandomizedItem_Decoration';
			inventoryOverride = class'Hat_Collectible_Decoration_CakeC';
			return true;

		case 2000300022:
			worldClass = class'Archipelago_RandomizedItem_Decoration';
			inventoryOverride = class'Hat_Collectible_Decoration_JewelryDisplay';
			return true;
		
		case 2000300023:
			worldClass = class'Archipelago_RandomizedItem_Decoration';
			inventoryOverride = class'Hat_Collectible_Decoration_GoldNecklace';
			return true;
			
			
		// -------- BADGES ----------------------------------------------------------------------------------------------- \\	
		
		case 2000300024:
			worldClass = class'Archipelago_RandomizedItem_BadgeProjectile';
			return true;
			
		case 2000300025:
			worldClass = class'Archipelago_RandomizedItem_BadgeHatCooldownBonus';
			return true;
			
		case 2000300026:
			worldClass = class'Archipelago_RandomizedItem_BadgeNoFallDamage';
			return true;
			
		case 2000300027:
			worldClass = class'Archipelago_RandomizedItem_BadgeHookshot';
			return true;
			
		case 2000300028:
			worldClass = class'Archipelago_RandomizedItem_BadgeSuckInOrbs';
			return true;
			
		case 2000300029:
			worldClass = class'Archipelago_RandomizedItem_BadgeNoBonk';
			return true;
			
		case 2000300030:
			worldClass = class'Archipelago_RandomizedItem_BadgeRelicFinder';
			return true;
			
		case 2000300031:
			worldClass = class'Archipelago_RandomizedItem_BadgeScooter';
			return true;
		
		case 2000300038:
			worldClass = class'Archipelago_RandomizedItem_BadgeOneHitDeath';
			return true;
		
		case 2000300042:
			worldClass = class'Archipelago_RandomizedItem_BadgeCamera';
			return true;
		
		
		// --------- SPECIAL/TRAPS --------------------------------------------------------------------------------------- \\
		
		case Pons25Item:
			worldClass = class'Archipelago_RandomizedItem_Pons';
			return true;
			
		case Pons50Item:
			worldClass = class'Archipelago_RandomizedItem_Pons';
			return true;
			
		case Pons100Item:
			worldClass = class'Archipelago_RandomizedItem_Pons';
			return true;
			
		case HealthPonItem:
			worldClass = class'Archipelago_RandomizedItem_HealthPon';
			return true;
			
		case BabyTrapItem:
			worldClass = class'Archipelago_RandomizedItem_TimeObject';
			return true;
			
		case LaserTrapItem:
			worldClass = class'Archipelago_RandomizedItem_TimeObject';
			return true;
			
		case ParadeTrapItem:
			worldClass = class'Archipelago_RandomizedItem_TimeObject';
			return true;
		
		case RandomCosmeticItem:
			worldClass = class'Archipelago_RandomizedItem_RouletteToken';
			return true;
			
		// --------- MISC ---------------------------------------------------------------------------------------------- \\
			
		case 2000300032:
			worldClass = class'Archipelago_RandomizedItem_RouletteToken';
			return true;
			
		case 2000300033:
			if (`AP.SlotData.BaseballBat && `AP.IsDLC2Installed())
			{
				worldClass = class'Archipelago_RandomizedItem_BaseballBat';
			}
			else
			{
				worldClass = class'Archipelago_RandomizedItem_Umbrella';
			}
			
			return true;
		
		case 2000300043:
			worldClass = class'Archipelago_RandomizedItem_BadgePin';
			return true;
		
		case 2000300200: // Subcon Well
			worldClass = class'Archipelago_RandomizedItem_Contract';
			return true;
		
		case 2000300201: // Toilet of Doom
			worldClass = class'Archipelago_RandomizedItem_Contract';
			return true;
		
		case 2000300202: // Queen Vanessa
			worldClass = class'Archipelago_RandomizedItem_Contract';
			return true;
		
		case 2000300203: // Mail Delivery
			worldClass = class'Archipelago_RandomizedItem_Contract';
			return true;
		
		case 2000300204: // Birdhouse Path
			worldClass = class'Archipelago_RandomizedItem_ZiplineUnlock';
			return true;
		
		case 2000300205: // Lava Cake Path
			worldClass = class'Archipelago_RandomizedItem_ZiplineUnlock';
			return true;
		
		case 2000300206: // Windmill Path
			worldClass = class'Archipelago_RandomizedItem_ZiplineUnlock';
			return true;
		
		case 2000300207: // Twilight Bell Path
			worldClass = class'Archipelago_RandomizedItem_ZiplineUnlock';
			return true;
		
		case 2000300003:
			worldClass = class'Archipelago_RandomizedItem_Painting';
			return true;
		
		case 2000300045:
			worldClass = class'Archipelago_RandomizedItem_MetroTicketYellow';
			return true;
		
		case 2000300046:
			worldClass = class'Archipelago_RandomizedItem_MetroTicketGreen';
			return true;
		
		case 2000300047:
			worldClass = class'Archipelago_RandomizedItem_MetroTicketBlue';
			return true;
		
		case 2000300048:
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
			return 2000300200;
		
		case class'Hat_SnatcherContract_Toilet':
			return 2000300201;
		
		case class'Hat_SnatcherContract_Vanessa':
			return 2000300202;
		
		case class'Hat_SnatcherContract_MailDelivery':
			return 2000300203;

		default:
			return 0;
	}
}

static function class<Hat_SnatcherContract_Act> GetContractFromID(int id)
{
	switch (id)
	{
		case 2000300200:
			return class'Hat_SnatcherContract_IceWall';
		
		case 2000300201:
			return class'Hat_SnatcherContract_Toilet';
		
		case 2000300202:
			return class'Hat_SnatcherContract_Vanessa';
		
		case 2000300203:
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
			return 2000350000;
		
		case class'Hat_SnatcherContract_DeathWish_KillEverybody':
			return 2000350002;
		
		case class'Hat_SnatcherContract_DeathWish_BackFromSpace':
			return 2000350004;
		
		case class'Hat_SnatcherContract_DeathWish_PonFrenzy':
			return 2000350006;
		
		case class'Hat_SnatcherContract_DeathWish_RiftCollapse_MafiaTown':
			return 2000350008;
		
		case class'Hat_SnatcherContract_DeathWish_Speedrun_MafiaAlien':
			return 2000350010;
		
		case class'Hat_SnatcherContract_DeathWish_NoAPresses_MafiaAlien':
			return 2000350012;

		case class'Hat_SnatcherContract_DeathWish_MovingVault':
			return 2000350014;

		case class'Hat_SnatcherContract_DeathWish_MafiaBossEX':
			return 2000350016;
		
		case class'Hat_SnatcherContract_DeathWish_Tokens_MafiaTown':
			return 2000350018;
	
		case class'Hat_SnatcherContract_DeathWish_DeadBirdStudioMoreGuards':
			return 2000350020;

		case class'Hat_SnatcherContract_DeathWish_DifficultParade':
			return 2000350022;

		case class'Hat_SnatcherContract_DeathWish_RiftCollapse_Birds':
			return 2000350024;
		
		case class'Hat_SnatcherContract_DeathWish_TrainRushShortTime':
			return 2000350026;
		
		case class'Hat_SnatcherContract_DeathWish_BirdBossEX':
			return 2000350028;

		case class'Hat_SnatcherContract_DeathWish_Tokens_Birds':
			return 2000350030;
		
		case class'Hat_SnatcherContract_DeathWish_NoAPresses':
			return 2000350032;
	
		case class'Hat_SnatcherContract_DeathWish_Speedrun_SubWell':
			return 2000350034;

		case class'Hat_SnatcherContract_DeathWish_RiftCollapse_Subcon':
			return 2000350036;
	
		case class'Hat_SnatcherContract_DeathWish_BossRush':
			return 2000350038;

		case class'Hat_SnatcherContract_DeathWish_SurvivalOfTheFittest':
			return 2000350040;
		
		case class'Hat_SnatcherContract_DeathWish_SnatcherEX':
			return 2000350042;

		case class'Hat_SnatcherContract_DeathWish_Tokens_Subcon':
			return 2000350044;

		case class'Hat_SnatcherContract_DeathWish_NiceBirdhouse':
			return 2000350046;

		case class'Hat_SnatcherContract_DeathWish_RiftCollapse_Alps':
			return 2000350048;

		case class'Hat_SnatcherContract_DeathWish_FastWindmill':
			return 2000350050;

		case class'Hat_SnatcherContract_DeathWish_Speedrun_Illness':
			return 2000350052;

		case class'Hat_SnatcherContract_DeathWish_Tokens_Alps':
			return 2000350054;
		
		case class'Hat_SnatcherContract_DeathWish_CameraTourist_1':
			return 2000350056;

		case class'Hat_SnatcherContract_DeathWish_HardCastle':
			return 2000350058;

		case class'Hat_SnatcherContract_DeathWish_MuGirlEX':
			return 2000350060;

		case class'Hat_SnatcherContract_DeathWish_BossRushEX':
			return 2000350062;
		
		case class'Hat_SnatcherContract_DeathWish_RiftCollapse_Cruise':
			return 2000350064;
		
		case class'Hat_SnatcherContract_DeathWish_EndlessTasks':
			return 2000350066;

		case class'Hat_SnatcherContract_DeathWish_CommunityRift_RhythmJump':
			return 2000350068;

		case class'Hat_SnatcherContract_DeathWish_CommunityRift_TwilightTravels':
			return 2000350070;
		
		case class'Hat_SnatcherContract_DeathWish_CommunityRift_MountainRift':
			return 2000350072;
		
		case class'Hat_SnatcherContract_DeathWish_Tokens_Metro':
			return 2000350074;
	}

	return -1;
}