import typing
from Options import Option, Range, Toggle, DeathLink, Choice


# General
class ActRandomizer(Choice):
    """If enabled, shuffle the game's Acts between each other.
    Separate Rifts will cause Time Rifts to only be shuffled amongst each other,
    and Blue Time Rifts and Purple Time Rifts are shuffled separately."""
    display_name = "Shuffle Acts"
    option_false = 0
    option_light = 1
    option_insanity = 2
    default = 1


class ShuffleAlpineZiplines(Toggle):
    """If enabled, Alpine's zipline paths leading to the peaks will be locked behind items."""
    display_name = "Shuffle Alpine Ziplines"
    default = 0


class VanillaAlpine(Choice):
    """If enabled, force Alpine (and optionally its finale) onto their vanilla locations in act shuffle."""
    display_name = "Vanilla Alpine Skyline"
    option_false = 0
    option_true = 1
    option_finale = 2
    default = 0


class LogicDifficulty(Choice):
    """Choose the difficulty setting for logic. Note that Hard or above will force SDJ logic on."""
    display_name = "Logic Difficulty"
    option_normal = 0
    option_hard = 1
    option_expert = 2
    default = 0


class RandomizeHatOrder(Toggle):
    """Randomize the order that hats are stitched in."""
    display_name = "Randomize Hat Order"
    default = 1


class UmbrellaLogic(Toggle):
    """Makes Hat Kid's default punch attack do absolutely nothing, making the Umbrella much more relevant and useful"""
    display_name = "Umbrella Logic"
    default = 0


class StartWithCompassBadge(Toggle):
    """If enabled, start with the Compass Badge. In Archipelago, the Compass Badge will track all items in the world
    (instead of just Relics). Recommended if you're not familiar with where item locations are."""
    display_name = "Start with Compass Badge"
    default = 1


class CompassBadgeMode(Choice):
    """closest - Compass Badge points to the closest item regardless of classification
    important_only - Compass Badge points to progression/useful items only
    important_first - Compass Badge points to progression/useful items first, then it will point to junk items"""
    display_name = "Compass Badge Mode"
    option_closest = 1
    option_important_only = 2
    option_important_first = 3
    default = 1


class ShuffleStorybookPages(Toggle):
    """If enabled, each storybook page in the purple Time Rifts is an item check.
    The Compass Badge can track these down for you."""
    display_name = "Shuffle Storybook Pages"
    default = 1


class ShuffleActContracts(Toggle):
    """If enabled, shuffle Snatcher's act contracts into the pool as items"""
    display_name = "Shuffle Contracts"
    default = 1


class StartingChapter(Choice):
    """Determines which chapter you will be guaranteed to be able to enter at the beginning of the game.
    Please note that in act randomizer, only 1 and 2 are allowed."""
    display_name = "Starting Chapter"
    option_1 = 1
    option_2 = 2
    option_3 = 3
    option_4 = 4
    default = 1


class SDJLogic(Toggle):
    """Allow the SDJ (Sprint Double Jump) technique to be considered in logic."""
    display_name = "SDJ Logic"
    default = 0


class CTRWithSprint(Toggle):
    """If enabled, clearing Cheating the Race with just Sprint Hat can be in logic."""
    display_name = "Cheating the Race with Sprint Hat"
    default = 0


# DLC
class EnableDLC1(Toggle):
    """Shuffle content from The Arctic Cruise (Chapter 6) into the game. This also includes the Tour time rift.
    DO NOT ENABLE THIS OPTION IF YOU DO NOT HAVE THE DLC INSTALLED!!!"""
    display_name = "Shuffle Chapter 6"


class EnableDLC2(Toggle):
    """NOT IMPLEMENTED Shuffle content from Nyakuza Metro (Chapter 7) into the game.
    DO NOT ENABLE THIS OPTION IF YOU DO NOT HAVE THE DLC INSTALLED!!!"""
    display_name = "Shuffle Chapter 7"


class ChapterCostIncrement(Range):
    """Lower values mean chapter costs increase slower. Higher values make the cost differences more steep."""
    display_name = "Chapter Cost Increment"
    range_start = 1
    range_end = 8
    default = 5


class ChapterCostMinDifference(Range):
    """The minimum difference between chapter costs."""
    display_name = "Minimum Chapter Cost Difference"
    range_start = 1
    range_end = 8
    default = 5


class LowestChapterCost(Range):
    """Value determining the lowest possible cost for a chapter.
    Chapter costs will, progressively, be calculated based on this value (except for Chapter 5)."""
    display_name = "Lowest Possible Chapter Cost"
    range_start = 0
    range_end = 10
    default = 5


class HighestChapterCost(Range):
    """Value determining the highest possible cost for a chapter.
    Chapter costs will, progressively, be calculated based on this value (except for Chapter 5)."""
    display_name = "Highest Possible Chapter Cost"
    range_start = 15
    range_end = 35
    default = 25


class Chapter5MinCost(Range):
    """Minimum Time Pieces required to enter Chapter 5 (Time's End). This is your goal."""
    display_name = "Chapter 5 Minimum Time Piece Cost"
    range_start = 0
    range_end = 40
    default = 25


class Chapter5MaxCost(Range):
    """Maximum Time Pieces required to enter Chapter 5 (Time's End). This is your goal."""
    display_name = "Chapter 5 Maximum Time Piece Cost"
    range_start = 0
    range_end = 40
    default = 35


class MaxExtraTimePieces(Range):
    """Maximum amount of extra Time Pieces that will be factored in chapter costs and the item pool from the DLCs.
    Arctic Cruise will add up to 6. Nyakuza Metro will add up to 10. The absolute maximum is 56."""
    display_name = "Max Extra Time Piece Cost"
    range_start = 0
    range_end = 16
    default = 0


# Death Wish
class EnableDeathWish(Toggle):
    """NOT IMPLEMENTED Shuffle Death Wish contracts into the game.
    Each contract by default will have a single check granted upon completion.
    DO NOT ENABLE THIS OPTION IF YOU DO NOT HAVE THE DLC INSTALLED!!!"""
    display_name = "Enable Death Wish"
    default = 0


class DWEnableBonus(Toggle):
    """NOT IMPLEMENTED In Death Wish, allow the full completion of contracts to reward items."""
    display_name = "Shuffle Death Wish Full Completions"
    default = 0


class DWExcludeAnnoyingContracts(Toggle):
    """NOT IMPLEMENTED Exclude Death Wish contracts from the pool that are particularly tedious or take a long time to reach/clear."""
    display_name = "Exclude Annoying Death Wish Contracts"
    default = 1


class DWExcludeAnnoyingBonuses(Toggle):
    """NOT IMPLEMENTED If Death Wish full completions are shuffled in, exclude particularly tedious Death Wish full completions
    from the pool"""
    display_name = "Exclude Annoying Death Wish Full Completions"
    default = 1


# Yarn
class YarnCostMin(Range):
    """The minimum possible yarn needed to stitch each hat."""
    display_name = "Minimum Yarn Cost"
    range_start = 1
    range_end = 12
    default = 4


class YarnCostMax(Range):
    """The maximum possible yarn needed to stitch each hat."""
    display_name = "Maximum Yarn Cost"
    range_start = 1
    range_end = 12
    default = 8


class YarnAvailable(Range):
    """How much yarn is available to collect in the item pool."""
    display_name = "Yarn Available"
    range_start = 30
    range_end = 75
    default = 45


# Shops
class MinPonCost(Range):
    """The minimum amount of Pons that any shop item can cost."""
    display_name = "Minimum Shop Pon Cost"
    range_start = 10
    range_end = 800
    default = 75


class MaxPonCost(Range):
    """The maximum amount of Pons that any shop item can cost."""
    display_name = "Maximum Shop Pon Cost"
    range_start = 10
    range_end = 800
    default = 400


# Traps
class TrapChance(Range):
    """The chance for any junk item in the pool to be replaced by a trap."""
    display_name = "Trap Chance"
    range_start = 0
    range_end = 100
    default = 0


class BabyTrapWeight(Range):
    """The weight of Baby Traps in the trap pool.
    Baby Traps place a multitude of the Conductor's grandkids into Hat Kid's hands, causing her to lose her balance."""
    display_name = "Baby Trap Weight"
    range_start = 0
    range_end = 100
    default = 40


class LaserTrapWeight(Range):
    """The weight of Laser Traps in the trap pool.
    Laser Traps will spawn multiple giant lasers (from Snatcher's boss fight) at Hat Kid's location."""
    display_name = "Laser Trap Weight"
    range_start = 0
    range_end = 100
    default = 40


class ParadeTrapWeight(Range):
    """The weight of Parade Traps in the trap pool.
    Parade Traps will summon multiple Express Band owls with knives that chase Hat Kid by mimicking her movement."""
    display_name = "Parade Trap Weight"
    range_start = 0
    range_end = 100
    default = 20


ahit_options: typing.Dict[str, type(Option)] = {

    "ActRandomizer":            ActRandomizer,
    "ShuffleAlpineZiplines":    ShuffleAlpineZiplines,
    "VanillaAlpine":            VanillaAlpine,
    "LogicDifficulty":          LogicDifficulty,
    "RandomizeHatOrder":        RandomizeHatOrder,
    "UmbrellaLogic":            UmbrellaLogic,
    "StartWithCompassBadge":    StartWithCompassBadge,
    "CompassBadgeMode":         CompassBadgeMode,
    "ShuffleStorybookPages":    ShuffleStorybookPages,
    "ShuffleActContracts":      ShuffleActContracts,
    "StartingChapter":          StartingChapter,
    "SDJLogic":                 SDJLogic,
    "CTRWithSprint":            CTRWithSprint,

    "EnableDLC1":               EnableDLC1,
    "EnableDeathWish":          EnableDeathWish,
    "EnableDLC2":               EnableDLC2,

    "LowestChapterCost":        LowestChapterCost,
    "HighestChapterCost":       HighestChapterCost,
    "ChapterCostIncrement":     ChapterCostIncrement,
    "ChapterCostMinDifference": ChapterCostMinDifference,
    "MaxExtraTimePieces":       MaxExtraTimePieces,

    "Chapter5MinCost":          Chapter5MinCost,
    "Chapter5MaxCost":          Chapter5MaxCost,

    "YarnCostMin":              YarnCostMin,
    "YarnCostMax":              YarnCostMax,
    "YarnAvailable":            YarnAvailable,

    "MinPonCost":               MinPonCost,
    "MaxPonCost":               MaxPonCost,

    "TrapChance":               TrapChance,
    "BabyTrapWeight":           BabyTrapWeight,
    "LaserTrapWeight":          LaserTrapWeight,
    "ParadeTrapWeight":         ParadeTrapWeight,

    "death_link":               DeathLink,
}

slot_data_options: typing.Dict[str, type(Option)] = {

    "ActRandomizer": ActRandomizer,
    "ShuffleAlpineZiplines": ShuffleAlpineZiplines,
    # "VanillaAlpine": VanillaAlpine,
    "LogicDifficulty": LogicDifficulty,
    "RandomizeHatOrder": RandomizeHatOrder,
    "UmbrellaLogic": UmbrellaLogic,
    # "StartWithCompassBadge": StartWithCompassBadge,
    "CompassBadgeMode": CompassBadgeMode,
    "ShuffleStorybookPages": ShuffleStorybookPages,
    "ShuffleActContracts": ShuffleActContracts,
    # "StartingChapter": StartingChapter,
    "SDJLogic": SDJLogic,
    # "CTRWithSprint": CTRWithSprint,

    "EnableDLC1": EnableDLC1,
    "EnableDeathWish": EnableDeathWish,
    "EnableDLC2": EnableDLC2,

    # "LowestChapterCost": LowestChapterCost,
    # "HighestChapterCost": HighestChapterCost,
    # "ChapterCostIncrement": ChapterCostIncrement,
    # "ChapterCostMinDifference": ChapterCostMinDifference,
    # "MaxExtraTimePieces": MaxExtraTimePieces,

    # "Chapter5MinCost": Chapter5MinCost,
    # "Chapter5MaxCost": Chapter5MaxCost,

    # "YarnCostMin": YarnCostMin,
    # "YarnCostMax": YarnCostMax,
    # "YarnAvailable": YarnAvailable,

    "MinPonCost": MinPonCost,
    "MaxPonCost": MaxPonCost,

    # "TrapChance": TrapChance,
    # "BabyTrapWeight": BabyTrapWeight,
    # "LaserTrapWeight": LaserTrapWeight,
    # "ParadeTrapWeight": ParadeTrapWeight,

    "death_link": DeathLink,
}
