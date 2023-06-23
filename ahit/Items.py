from BaseClasses import Item, ItemClassification
from ..AutoWorld import World
from .Types import HatDLC
import typing


class ItemData(typing.NamedTuple):
    code: typing.Optional[int]
    classification: ItemClassification
    dlc_flags: typing.Optional[HatDLC] = HatDLC.none


class HatInTimeItem(Item):
    game: str = "A Hat in Time"


def item_dlc_enabled(world: World, item: str) -> bool:
    data = ahit_items.get(item) or time_pieces.get(item)

    if data.dlc_flags == HatDLC.none:
        return True
    elif data.dlc_flags == HatDLC.dlc1 and world.multiworld.EnableDLC1[world.player].value is True:
        return True
    elif data.dlc_flags == HatDLC.dlc2 and world.multiworld.EnableDLC2[world.player].value is True:
        return True
    elif data.dlc_flags == HatDLC.death_wish and world.multiworld.EnableDeathWish[world.player].value is True:
        return True

    return False


ahit_items = {
    "Yarn": ItemData(300001, ItemClassification.progression_skip_balancing),

    # Relics
    "Relic (Burger Patty)": ItemData(300006, ItemClassification.progression),
    "Relic (Burger Cushion)": ItemData(300007, ItemClassification.progression),
    "Relic (Mountain Set)": ItemData(300008, ItemClassification.progression),
    "Relic (Train)": ItemData(300009, ItemClassification.progression),
    "Relic (UFO)": ItemData(300010, ItemClassification.progression),
    "Relic (Cow)": ItemData(300011, ItemClassification.progression),
    "Relic (Cool Cow)": ItemData(300012, ItemClassification.progression),
    "Relic (Tin-foil Hat Cow)": ItemData(300013, ItemClassification.progression),
    "Relic (Crayon Box)": ItemData(300014, ItemClassification.progression),
    "Relic (Red Crayon)": ItemData(300015, ItemClassification.progression),
    "Relic (Blue Crayon)": ItemData(300016, ItemClassification.progression),
    "Relic (Green Crayon)": ItemData(300017, ItemClassification.progression),

    # Badges
    "Projectile Badge": ItemData(300024, ItemClassification.useful),
    "Fast Hatter Badge": ItemData(300025, ItemClassification.useful),
    "Hover Badge": ItemData(300026, ItemClassification.useful),
    "Hookshot Badge": ItemData(300027, ItemClassification.progression),
    "Item Magnet Badge": ItemData(300028, ItemClassification.useful),
    "No Bonk Badge": ItemData(300029, ItemClassification.useful),
    "Compass Badge": ItemData(300030, ItemClassification.useful),
    "Scooter Badge": ItemData(300031, ItemClassification.useful),
    "Badge Pin": ItemData(300043, ItemClassification.useful),

    # Other
    "Rift Token": ItemData(300032, ItemClassification.filler),
    "Umbrella": ItemData(300033, ItemClassification.progression),

    # Garbage items
    "25 Pons": ItemData(300034, ItemClassification.filler),
    "50 Pons": ItemData(300035, ItemClassification.filler),
    "100 Pons": ItemData(300036, ItemClassification.filler),
    "Health Pon": ItemData(300037, ItemClassification.filler),

    # Traps
    "Baby Trap": ItemData(300039, ItemClassification.trap),
    "Laser Trap": ItemData(300040, ItemClassification.trap),
    "Parade Trap": ItemData(300041, ItemClassification.trap),

    # DLC1 items
    "Relic (Cake Stand)": ItemData(300018, ItemClassification.progression, HatDLC.dlc1),
    "Relic (Cake)": ItemData(300019, ItemClassification.progression, HatDLC.dlc1),
    "Relic (Cake Slice)": ItemData(300020, ItemClassification.progression, HatDLC.dlc1),
    "Relic (Shortcake)": ItemData(300021, ItemClassification.progression, HatDLC.dlc1),

    # DLC2 items
    "Relic (Necklace Bust)": ItemData(300022, ItemClassification.progression, HatDLC.dlc2),
    "Relic (Necklace)": ItemData(300023, ItemClassification.progression, HatDLC.dlc2),

    # Death Wish items
    "One-Hit Hero Badge": ItemData(300038, ItemClassification.progression, HatDLC.death_wish),
    "Camera Badge": ItemData(300042, ItemClassification.progression, HatDLC.death_wish),
}

time_pieces = {
    "Time Piece (Welcome to Mafia Town)": ItemData(300048, ItemClassification.progression),
    "Time Piece (Barrel Battle)": ItemData(300049, ItemClassification.progression),
    "Time Piece (She Came from Outer Space)": ItemData(300050, ItemClassification.progression),
    "Time Piece (Down with the Mafia!)": ItemData(300051, ItemClassification.progression),
    "Time Piece (Cheating the Race)": ItemData(300052, ItemClassification.progression),
    "Time Piece (Heating Up Mafia Town)": ItemData(300053, ItemClassification.progression),
    "Time Piece (The Golden Vault)": ItemData(300054, ItemClassification.progression),
    "Time Piece (Time Rift - Sewers)": ItemData(300055, ItemClassification.progression),
    "Time Piece (Time Rift - Bazaar)": ItemData(300056, ItemClassification.progression),
    "Time Piece (Time Rift - Mafia of Cooks)": ItemData(300057, ItemClassification.progression),

    "Time Piece (Dead Bird Studio)": ItemData(300058, ItemClassification.progression),
    "Time Piece (Murder on the Owl Express)": ItemData(300059, ItemClassification.progression),
    "Time Piece (Train Rush)": ItemData(300060, ItemClassification.progression),
    "Time Piece (Picture Perfect)": ItemData(300061, ItemClassification.progression),
    "Time Piece (The Big Parade)": ItemData(300062, ItemClassification.progression),
    "Time Piece (Award Ceremony)": ItemData(300063, ItemClassification.progression),
    "Time Piece (Award Ceremony Boss)": ItemData(300064, ItemClassification.progression),
    "Time Piece (Time Rift - The Owl Express)": ItemData(300065, ItemClassification.progression),
    "Time Piece (Time Rift - The Moon)": ItemData(300066, ItemClassification.progression),
    "Time Piece (Time Rift - Dead Bird Studio)": ItemData(300067, ItemClassification.progression),

    "Time Piece (Contractual Obligations)": ItemData(300068, ItemClassification.progression),
    "Time Piece (The Subcon Well)": ItemData(300069, ItemClassification.progression),
    "Time Piece (Toilet of Doom)": ItemData(300070, ItemClassification.progression),
    "Time Piece (Queen Vanessa's Manor)": ItemData(300071, ItemClassification.progression),
    "Time Piece (Mail Delivery Service)": ItemData(300072, ItemClassification.progression),
    "Time Piece (Your Contract Has Expired)": ItemData(300073, ItemClassification.progression),
    "Time Piece (Time Rift - Pipe)": ItemData(300074, ItemClassification.progression),
    "Time Piece (Time Rift - Village)": ItemData(300075, ItemClassification.progression),
    "Time Piece (Time Rift - Sleepy Subcon)": ItemData(300076, ItemClassification.progression),

    "Time Piece (The Birdhouse)": ItemData(300077, ItemClassification.progression),
    "Time Piece (The Lava Cake)": ItemData(300078, ItemClassification.progression),
    "Time Piece (The Twilight Bell)": ItemData(300079, ItemClassification.progression),
    "Time Piece (The Windmill)": ItemData(300080, ItemClassification.progression),
    "Time Piece (The Illness has Spread)": ItemData(300081, ItemClassification.progression),
    "Time Piece (Time Rift - The Twilight Bell)": ItemData(300082, ItemClassification.progression),
    "Time Piece (Time Rift - Curly Tail Trail)": ItemData(300083, ItemClassification.progression),
    "Time Piece (Time Rift - Alpine Skyline)": ItemData(300084, ItemClassification.progression),

    "Time Piece (Time Rift - Gallery)": ItemData(300085, ItemClassification.progression),
    "Time Piece (Time Rift - The Lab)": ItemData(300086, ItemClassification.progression),

    "Time Piece (Time's End - The Finale)": ItemData(300087, ItemClassification.progression),
}

item_frequencies = {
}

junk_weights = {
    "25 Pons": 50,
    "50 Pons": 10,
    "Health Pon": 35,
    "100 Pons": 5,
    "Rift Token": 15,
}

item_table = {
    **ahit_items,
    **time_pieces,
}

lookup_id_to_name: typing.Dict[int, str] = {data.code: item_name for item_name, data in ahit_items.items() if data.code}
