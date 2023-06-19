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

enum ESpecialItemType
{
	SpecialType_None,
	SpecialType_25Pons,
	SpecialType_50Pons,
	SpecialType_100Pons,
	SpecialType_HealthPon,
};

enum ETrapType
{
	TrapType_None,
	TrapType_Baby,
	TrapType_Laser,
	TrapType_Parade,
};

const YarnItem = 300001;

const Pons25Item = 300034;
const Pons50Item = 300035;
const Pons100Item = 300036;
const HealthPonItem = 300037;

const BabyTrapItem = 300039;
const LaserTrapItem = 300040;
const ParadeTrapItem = 300041;

static function int GetYarnItemID()
{
	return YarnItem;
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
optional out class worldClass, // Item in the world
optional out class inventoryOverride) // Item inventory class override. Mainly for relics.
{
	switch (itemId)
	{
		case YarnItem:
			itemName = "Yarn";
			worldClass = class'Archipelago_RandomizedItem_Yarn';
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
			
			
		// --------- MISC ---------------------------------------------------------------------------------------------- \\
			
		case 300032:
			itemName = "Rift Token";
			worldClass = class'Archipelago_RandomizedItem_RouletteToken';
			return true;
			
		case 300033:
			itemName = "Umbrella";
			worldClass = class'Archipelago_RandomizedItem_Umbrella';
			return true;
		
		default:
			return false;
	}
}

static function string GetTimePieceFromItemID(int id, optional out int IsAct, optional out string displayName)
{
	IsAct = 1;

	switch (id)
	{
		// -------------------------------------------------- MAFIA TOWN ------------------------------------------------------------- \\
	
		case 300048:
			displayName = "Welcome to Mafia Town";
			return "chapter1_tutorial";
			
		case 300049:
			displayName = "Barrel Battle";
			return "chapter1_barrelboss";
			
		case 300050:
			displayName = "She Came from Outer Space";
			return "chapter1_cannon_repair";
			
		case 300051:
			displayName = "Down with the Mafia!";
			return "chapter1_boss";
			
		case 300052:
			displayName = "Cheating the Race";
			return "harbor_impossible_race";
			
		case 300053:
			displayName = "Heating Up Mafia Town";
			return "mafiatown_lava";
			
		case 300054:
			displayName = "The Golden Vault";
			return "mafiatown_goldenvault";
			
		case 300055:
			displayName = "Time Rift - Sewers";
			IsAct = 0;
			return "TimeRift_Water_Mafia_Easy";
			
		case 300056:
			displayName = "Time Rift - Bazaar";
			IsAct = 0;
			return "TimeRift_Water_Mafia_Hard";
			
		case 300057:
			displayName = "Time Rift - Mafia of Cooks";
			IsAct = 0;
			return "TimeRift_Cave_Mafia";
			
		// -------------------------------------------------- BATTLE OF THE BIRDS ----------------------------------------------------- \\
			
		case 300058:
			displayName = "Dead Bird Studio";
			return "DeadBirdStudio";
			
		case 300059:
			displayName = "Murder on the Owl Express";
			return "chapter3_murder";
			
		case 300060:
			displayName = "Train Rush";
			return "trainwreck_selfdestruct";
			
		case 300061:
			displayName = "Picture Perfect";
			return "moon_camerasnap";
			
		case 300062:
			displayName = "The Big Parade";
			return "moon_parade";
			
		case 300063:
			displayName = "Award Ceremony";
			return "award_ceremony";
			
		case 300064:
			displayName = "Award Ceremony - Boss";
			return "chapter3_secret_finale";
			
		case 300065:
			displayName = "Time Rift - The Owl Express";
			IsAct = 0;
			return "TimeRift_Water_TWreck_Panels";
			
		case 300066:
			displayName = "Time Rift - The Moon";
			IsAct = 0;
			return "TimeRift_Water_TWreck_Parade";
			
		case 300067:
			displayName = "Time Rift - Dead Bird Studio";
			IsAct = 0;
			return "TimeRift_Cave_BirdBasement";
			
		// -------------------------------------------------- SUBCON FOREST ----------------------------------------------------- \\
		case 300068:
			displayName = "Contractual Obligations";
			return "subcon_village_icewall";
			
		case 300069:
			displayName = "The Subcon Well";
			return "subcon_cave";
			
		case 300070:
			displayName = "Toilet of Doom";
			return "chapter2_toiletboss";
			
		case 300071:
			displayName = "Queen Vanessa's Manor";
			return "vanessa_manor_attic";
			
		case 300072:
			displayName = "Mail Delivery Service";
			return "subcon_maildelivery";
			
		case 300073:
			displayName = "Your Contract Has Expired";
			return "snatcher_boss";
			
		case 300074:
			displayName = "Time Rift - Pipe";
			IsAct = 0;
			return "TimeRift_Water_Subcon_Hookshot";
			
		case 300075:
			displayName = "Time Rift - Village";
			IsAct = 0;
			return "TimeRift_Water_Subcon_Dwellers";
			
		case 300076:
			displayName = "Time Rift - Sleepy Subcon";
			IsAct = 0;
			return "TimeRift_Cave_Raccoon";
			
			
		// -------------------------------------------------- ALPINE SKYLINE ----------------------------------------------------- \\
		case 300077:
			displayName = "The Birdhouse";
			return "Alps_Birdhouse";
			
		case 300078:
			displayName = "The Lava Cake";
			return "AlpineSkyline_WeddingCake";
			
		case 300079:
			displayName = "The Twilight Bell";
			return "Alpine_Twilight";
			
		case 300080:
			displayName = "The Windmill";
			return "AlpineSkyline_Windmill";
			
		case 300081:
			displayName = "The Illness Has Spread";
			return "AlpineSkyline_Finale";
			
		case 300082:
			displayName = "Time Rift - The Twilight Bell";
			return "TimeRift_Water_Alp_Goats";
			
		case 300083:
			displayName = "Time Rift - Curly Tail Trail";
			return "TimeRift_Water_AlpineSkyline_Cats";
			
		case 300084:
			displayName = "Time Rift - Alpine Skyline";
			return "TimeRift_Cave_Alps";
			
		case 300085:
			displayName = "Time Rift - Gallery";
			return "Spaceship_WaterRift_Gallery";
			
		case 300086:
			displayName = "Time Rift - The Lab";
			return "Spaceship_WaterRift_MailRoom";
			
		// Time's End
		case 300087:
		displayName = "The Finale";
		return "";
		
		default:
			return "";
	}
}