import typing
from Options import Option, Range, Toggle, DeathLink, Choice


# General
class ActRandomizer(Toggle):
    """If enabled, shuffle the game's Acts between each other."""
    display_name = "Shuffle Acts"
    default = 1


class RandomizeHatOrder(Toggle):
    """Randomize the order that hats are stitched in."""
    display_name = "Randomize Hat Order"
    default = 1


class BetterCompassBadge(Toggle):
    """If enabled, start with the Compass Badge. In Archipelago, the Compass Badge will track all items in the world
    (instead of just Relics). Recommended if you're not familiar with where item locations are."""
    display_name = "Start with Compass Badge"
    default = 0


class ShuffleStorybookPages(Toggle):
    """If enabled, each storybook page in the purple Time Rifts is an item check.
    The Compass Badge can track these down for you."""
    display_name = "Shuffle Storybook Pages"
    default = 1


class StartingChapter(Choice):
    """Determines which chapter you will be guaranteed to be able to enter at the beginning of the game."""
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
    """Shuffle content from The Arctic Cruise (Chapter 6) into the game.
    DO NOT ENABLE THIS OPTION IF YOU DO NOT HAVE THE DLC INSTALLED!!!"""
    display_name = "Shuffle Chapter 6"


class EnableDLC2(Toggle):
    """Shuffle content from Nyakuza Metro (Chapter 7) into the game.
    DO NOT ENABLE THIS OPTION IF YOU DO NOT HAVE THE DLC INSTALLED!!!"""
    display_name = "Shuffle Chapter 7"


class LowestChapterCost(Range):
    """Value determining the lowest possible cost for a chapter.
    Chapter costs will, progressively, be calculated based on this value (except for Chapter 5)."""
    display_name = "Lowest Possible Chapter Cost"
    range_start = 0
    range_end = 10
    default = 0


class HighestChapterCost(Range):
    """Value determining the highest possible cost for a chapter.
    Chapter costs will, progressively, be calculated based on this value (except for Chapter 5)."""
    display_name = "Highest Possible Chapter Cost"
    range_start = 0
    range_end = 40
    default = 20


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


# Death Wish
class EnableDeathWish(Toggle):
    """Shuffle Death Wish contracts into the game.
    Each contract by default will have a single check granted upon completion.
    DO NOT ENABLE THIS OPTION IF YOU DO NOT HAVE THE DLC INSTALLED!!!"""
    display_name = "Enable Death Wish"
    default = 0


class DWEnableBonus(Toggle):
    """In Death Wish, allow the full completion of contracts to reward items."""
    display_name = "Shuffle Death Wish Full Completions"
    default = 0


class DWExcludeAnnoyingContracts(Toggle):
    """Exclude Death Wish contracts from the pool that are particularly tedious or take a long time to reach/clear."""
    display_name = "Exclude Annoying Death Wish Contracts"
    default = 1


class DWExcludeAnnoyingBonuses(Toggle):
    """If Death Wish full completions are shuffled in, exclude particularly tedious Death Wish full completions
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
    range_start = 20
    range_end = 85
    default = 60


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
    "RandomizeHatOrder":        RandomizeHatOrder,
    "BetterCompassBadge":       BetterCompassBadge,
    "ShuffleStorybookPages":    ShuffleStorybookPages,
    "StartingChapter":          StartingChapter,
    "SDJLogic":                 SDJLogic,
    "CTRWithSprint":            CTRWithSprint,

    "EnableDLC1":               EnableDLC1,
    "EnableDeathWish":          EnableDeathWish,
    "EnableDLC2":               EnableDLC2,

    "LowestChapterCost":        LowestChapterCost,
    "HighestChapterCost":       HighestChapterCost,

    "Chapter5MinCost":          Chapter5MinCost,
    "Chapter5MaxCost":          Chapter5MaxCost,

    "YarnCostMin":              YarnCostMin,
    "YarnCostMax":              YarnCostMax,
    "YarnAvailable":            YarnAvailable,

    "TrapChance":               TrapChance,
    "BabyTrapWeight":           BabyTrapWeight,
    "LaserTrapWeight":          LaserTrapWeight,
    "ParadeTrapWeight":         ParadeTrapWeight,

    "death_link":               DeathLink,
}
