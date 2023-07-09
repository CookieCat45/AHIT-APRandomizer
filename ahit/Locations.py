from BaseClasses import Location
from worlds.AutoWorld import World
from .Types import HatDLC, HatType
from typing import Optional, NamedTuple, Dict, List


class LocData(NamedTuple):
    id: int
    region: str
    required_hats: Optional[List[HatType]] = [HatType.NONE]
    required_tps: Optional[int] = 0
    hookshot: Optional[bool] = False
    dlc_flags: Optional[HatDLC] = HatDLC.none


class HatInTimeLocation(Location):
    game: str = "A Hat in Time"


def get_total_locations(world: World) -> int:
    total: int = 0

    for (name) in location_table.keys():
        if not location_dlc_enabled(world, name):
            continue

        if name in storybook_pages.keys() \
           and world.multiworld.ShuffleStorybookPages[world.player].value == 0:
            continue

        if name in contract_locations.keys() and world.multiworld.ShuffleActContracts[world.player].value == 0:
            continue

        total += 1

    return total


def location_dlc_enabled(world: World, location: str) -> bool:
    data = location_table.get(location)

    if data.dlc_flags == HatDLC.none:
        return True
    elif data.dlc_flags == HatDLC.dlc1 and world.multiworld.EnableDLC1[world.player].value > 0:
        return True
    elif data.dlc_flags == HatDLC.dlc2 and world.multiworld.EnableDLC2[world.player].value > 0:
        return True
    elif data.dlc_flags == HatDLC.death_wish and world.multiworld.EnableDeathWish[world.player].value > 0:
        return True

    return False


ahit_locations = {
    "Spaceship - Rumbi": LocData(301000, "Spaceship", required_tps=4),
    "Spaceship - Cooking Cat": LocData(301001, "Spaceship", required_tps=5),

    # 300000 range - Mafia Town/Batle of the Birds
    "Mafia Town - Umbrella": LocData(301002, "Welcome to Mafia Town"),
    "Mafia Town - Red Vault": LocData(302848, "Mafia Town Area"),
    "Mafia Town - Dweller Boxes": LocData(304462, "Mafia Town Area"),
    "Mafia Town - Old Man (Steel Beams)": LocData(303832, "Mafia Town Area"),
    "Mafia Town - Ledge Chest": LocData(303530, "Mafia Town Area"),
    "Mafia Town - Yellow Sphere Building Chest": LocData(303535, "Mafia Town Area"),
    "Mafia Town - Beneath Scaffolding": LocData(304456, "Mafia Town Area"),
    "Mafia Town - On Scaffolding": LocData(304457, "Mafia Town Area"),
    "Mafia Town - Plaza Under Boxes": LocData(304458, "Mafia Town Area"),
    "Mafia Town - Blue Vault Brewing Crate": LocData(305572, "Mafia Town Area", required_hats=[HatType.BREWING]),
    "Mafia Town - Small Boat": LocData(304460, "Mafia Town Area"),
    "Mafia Town - Cargo Ship": LocData(304459, "Mafia Town Area"),
    "Mafia Town - Beach Alcove": LocData(304463, "Mafia Town Area"),
    "Mafia Town - Wood Cage": LocData(304606, "Mafia Town Area"),
    "Mafia Town - Staircase Pon Cluster": LocData(304611, "Mafia Town Area"),
    "Mafia Town - Blue Vault": LocData(302850, "Mafia Town Area"),
    "Mafia Town - Old Man (Seaside Spaghetti)": LocData(303833, "Mafia Town Area"),
    "Mafia Town - Palm Tree": LocData(304609, "Mafia Town Area"),
    "Mafia Town - Beach Patio": LocData(304610, "Mafia Town Area"),
    "Mafia Town - Steel Beam Nest": LocData(304608, "Mafia Town Area"),
    "Mafia Town - Top of Ruined Tower": LocData(304607, "Mafia Town Area", required_hats=[HatType.ICE]),
    "Mafia Town - Ice Hat Cage": LocData(304831, "Mafia Town Area", required_hats=[HatType.ICE]),
    "Mafia Town - Hot Air Balloon": LocData(304829, "Mafia Town Area", required_hats=[HatType.ICE]),
    "Mafia Town - Camera Badge 1": LocData(302003, "Mafia Town Area"),
    "Mafia Town - Camera Badge 2": LocData(302004, "Mafia Town Area"),
    "Mafia Town - Chest Beneath Aqueduct": LocData(303489, "Mafia Town Area"),
    "Mafia Town - Secret Cave": LocData(305220, "Mafia Town Area", required_hats=[HatType.BREWING]),
    "Mafia Town - Crow Chest": LocData(303532, "Mafia Town Area"),
    "Mafia Town - Port": LocData(305219, "Mafia Town Area"),
    "Mafia Town - Docks Chest": LocData(303534, "Mafia Town Area"),
    "Mafia Town - Above Boats": LocData(305218, "Mafia Town Area", hookshot=True),
    "Mafia Town - Slip Slide Chest": LocData(303529, "Mafia Town Area"),
    "Mafia Town - Green Vault": LocData(302851, "Mafia Town Area"),
    "Mafia Town - Behind Faucet": LocData(304214, "Mafia Town Area"),
    "Mafia Town - Hidden Buttons Chest": LocData(303483, "Mafia Town Area"),
    "Mafia Town - Clock Tower Chest": LocData(303481, "Mafia Town Area", hookshot=True),
    "Mafia Town - Top of Lighthouse": LocData(304213, "Mafia Town Area", hookshot=True),
    "Mafia Town - Mafia Geek Platform": LocData(304212, "Mafia Town Area"),
    "Mafia Town - Behind HQ Chest": LocData(303486, "Down with the Mafia!"),

    "Mafia HQ - Hallway Brewing Crate": LocData(305387, "Down with the Mafia!", required_hats=[HatType.BREWING]),
    "Mafia HQ - Freezer Chest": LocData(303241, "Down with the Mafia!"),
    "Mafia HQ - Secret Room": LocData(304979, "Down with the Mafia!", required_hats=[HatType.ICE]),
    "Mafia HQ - Bathroom Stall Chest": LocData(303243, "Down with the Mafia!"),

    "Dead Bird Studio - Up the Ladder": LocData(304874, "Dead Bird Studio"),  # Can be reached from basement
    "Dead Bird Studio - Red Building Top": LocData(305024, "Dead Bird Studio"),  # Can be reached from basement
    "Dead Bird Studio - Behind Water Tower": LocData(305248, "Dead Bird Studio"),  # Can be reached from basement
    "Dead Bird Studio - Side of House": LocData(305247, "Dead Bird Studio"),  # Can be reached from basement
    "Dead Bird Studio - DJ Grooves Sign Chest": LocData(303901, "Dead Bird Studio"),
    "Dead Bird Studio - Tightrope Chest": LocData(303898, "Dead Bird Studio"),
    "Dead Bird Studio - Tepee Chest": LocData(303899, "Dead Bird Studio"),
    "Dead Bird Studio - Conductor Chest": LocData(303900, "Dead Bird Studio"),

    "Murder on the Owl Express - Cafeteria": LocData(305313, "Murder on the Owl Express"),
    "Murder on the Owl Express - Luggage Room Top": LocData(305090, "Murder on the Owl Express"),
    "Murder on the Owl Express - Luggage Room Bottom": LocData(305091, "Murder on the Owl Express"),
    "Murder on the Owl Express - Raven Suite Room": LocData(305701, "Murder on the Owl Express",
                                                            required_hats=[HatType.BREWING]),
    "Murder on the Owl Express - Raven Suite Top": LocData(305312, "Murder on the Owl Express"),
    "Murder on the Owl Express - Lounge Chest": LocData(303963, "Murder on the Owl Express"),

    "Picture Perfect - Behind Badge Seller": LocData(304307, "Picture Perfect"),
    "Picture Perfect - Hats Buy Building": LocData(304530, "Picture Perfect"),

    "Dead Bird Studio Basement - Window Platform": LocData(305432, "Dead Bird Studio Basement", hookshot=True),
    "Dead Bird Studio Basement - Cardboard Conductor": LocData(305059, "Dead Bird Studio Basement", hookshot=True),
    "Dead Bird Studio Basement - Above Conductor Sign": LocData(305057, "Dead Bird Studio Basement", hookshot=True),
    "Dead Bird Studio Basement - Logo Wall": LocData(305207, "Dead Bird Studio Basement"),
    "Dead Bird Studio Basement - Disco Room": LocData(305061, "Dead Bird Studio Basement", hookshot=True),
    "Dead Bird Studio Basement - Small Room": LocData(304813, "Dead Bird Studio Basement", hookshot=True),
    "Dead Bird Studio Basement - Vent Pipe": LocData(305430, "Dead Bird Studio Basement"),
    "Dead Bird Studio Basement - Tightrope": LocData(305058, "Dead Bird Studio Basement", hookshot=True),
    "Dead Bird Studio Basement - Cameras": LocData(305431, "Dead Bird Studio Basement", hookshot=True),
    "Dead Bird Studio Basement - Locked Room": LocData(305819, "Dead Bird Studio Basement", hookshot=True),

    # 320000 range - Subcon Forest
    "Subcon Forest - Cherry Bomb Bone Cage": LocData(324761, "Contractual Obligations"),
    "Subcon Village - Tree Top Ice Cube": LocData(325078, "Subcon Forest Area"),
    "Subcon Village - Graveyard Ice Cube": LocData(325077, "Subcon Forest Area"),
    "Subcon Village - House Top": LocData(325471, "Subcon Forest Area"),
    "Subcon Village - Ice Cube House": LocData(325469, "Subcon Forest Area"),
    "Subcon Village - Snatcher Statue Chest": LocData(323730, "Subcon Forest Area"),
    "Subcon Village - Stump Platform Chest": LocData(323729, "Subcon Forest Area"),
    "Subcon Forest - Giant Mushroom Climb": LocData(325470, "Subcon Forest Area"),
    "Subcon Forest - Swamp Gravestone": LocData(326296, "Subcon Forest Area", required_hats=[HatType.BREWING]),
    "Subcon Forest - Swamp Near Well": LocData(324762, "Subcon Forest Area"),
    "Subcon Forest - Swamp Tree A": LocData(324763, "Subcon Forest Area"),
    "Subcon Forest - Swamp Tree B": LocData(324764, "Subcon Forest Area"),
    "Subcon Forest - Swamp Ice Wall": LocData(324706, "Subcon Forest Area"),
    "Subcon Forest - Swamp Treehouse": LocData(325468, "Subcon Forest Area"),
    "Subcon Forest - Swamp Tree Chest": LocData(323728, "Subcon Forest Area"),
    "Subcon Forest - Dweller Stump": LocData(324767, "Subcon Forest Area", required_hats=[HatType.DWELLER]),
    "Subcon Forest - Dweller Floating Rocks": LocData(324464, "Subcon Forest Area", required_hats=[HatType.DWELLER]),
    "Subcon Forest - Dweller Platforming Tree A": LocData(324709, "Subcon Forest Area", required_hats=[HatType.DWELLER]),
    "Subcon Forest - Dweller Platforming Tree B": LocData(324855, "Subcon Forest Area", required_hats=[HatType.DWELLER]),
    "Subcon Forest - Giant Time Piece": LocData(325473, "Subcon Forest Area"),
    "Subcon Forest - Gallows": LocData(325472, "Subcon Forest Area"),
    "Subcon Forest - Green and Purple Dweller Rocks": LocData(325082, "Subcon Forest Area", required_hats=[HatType.DWELLER]),
    "Subcon Forest - Dweller Shack": LocData(324463, "Subcon Forest Area", required_hats=[HatType.DWELLER]),
    "Subcon Forest - Tall Tree Hookshot Swing": LocData(324766, "Subcon Forest Area",
                                                        required_hats=[HatType.DWELLER], hookshot=True),
    "Subcon Forest - Burning House": LocData(324710, "Subcon Forest Area"),
    "Subcon Forest - Burning Tree Climb": LocData(325079, "Subcon Forest Area"),
    "Subcon Forest - Burning Stump Chest": LocData(323731, "Subcon Forest Area"),
    "Subcon Forest - Burning Forest Treehouse": LocData(325467, "Subcon Forest Area"),
    "Subcon Forest - Spider Bone Cage A": LocData(324462, "Subcon Forest Area"),
    "Subcon Forest - Spider Bone Cage B": LocData(325080, "Subcon Forest Area"),
    "Subcon Forest - Triple Spider Bounce": LocData(324765, "Subcon Forest Area"),
    "Subcon Forest - Noose Treehouse": LocData(324856, "Subcon Forest Area", hookshot=True),
    "Subcon Forest - Ice Cube Shack": LocData(324465, "Subcon Forest Area"),
    "Subcon Forest - Long Tree Climb Chest": LocData(323734, "Subcon Forest Area", required_hats=[HatType.DWELLER]),
    "Subcon Forest - Boss Arena Chest": LocData(323735, "Subcon Forest Area"),
    "Subcon Well - Hookshot Badge Chest": LocData(324114, "The Subcon Well"),
    "Subcon Well - Above Chest": LocData(324612, "The Subcon Well"),
    "Subcon Well - On Pipe": LocData(324311, "The Subcon Well"),
    "Subcon Well - Mushroom": LocData(325318, "The Subcon Well"),
    "Queen Vanessa's Manor - Rooftop": LocData(325466, "Queen Vanessa's Manor"),
    "Queen Vanessa's Manor - Cellar": LocData(324841, "Queen Vanessa's Manor"),
    "Queen Vanessa's Manor - Bedroom Chest": LocData(323808, "Queen Vanessa's Manor"),
    "Queen Vanessa's Manor - Hall Chest": LocData(323896, "Queen Vanessa's Manor"),
    "Queen Vanessa's Manor - Chandelier": LocData(325546, "Queen Vanessa's Manor"),

    # 330000 range - Alpine Skyline
    "Alpine Skyline - Goat Village: Below Hookpoint": LocData(334856, "Goat Village"),
    "Alpine Skyline - Goat Village: Hidden Branch": LocData(334855, "Goat Village"),
    "Alpine Skyline - Goat Refinery": LocData(333635, "Alpine Free Roam"),
    "Alpine Skyline - Bird Pass Fork": LocData(335911, "Alpine Free Roam"),
    "Alpine Skyline - Yellow Band Hills": LocData(335756, "Alpine Free Roam"),
    "Alpine Skyline - The Purrloined Village: Horned Stone": LocData(335561, "Alpine Free Roam"),
    "Alpine Skyline - The Purrloined Village: Chest Reward": LocData(334831, "Alpine Free Roam"),
    "Alpine Skyline - The Birdhouse: Triple Crow Chest": LocData(334758, "The Birdhouse"),
    "Alpine Skyline - The Birdhouse: Dweller Platforms Relic": LocData(336497, "The Birdhouse",
                                                                       required_hats=[HatType.DWELLER]),
    "Alpine Skyline - The Birdhouse: Brewing Crate House": LocData(336496, "The Birdhouse"),
    "Alpine Skyline - The Birdhouse: Hay Bale": LocData(335885, "The Birdhouse"),
    "Alpine Skyline - The Birdhouse: Alpine Crow Mini-Gauntlet": LocData(335886, "The Birdhouse"),
    "Alpine Skyline - The Birdhouse: Outer Edge": LocData(335492, "The Birdhouse"),

    "Alpine Skyline - Mystifying Time Mesa: Zipline": LocData(337058, "Alpine Free Roam"),
    "Alpine Skyline - Mystifying Time Mesa: Gate Puzzle": LocData(336052, "Alpine Free Roam"),
    "Alpine Skyline - Ember Summit": LocData(336311, "Alpine Free Roam"),
    "Alpine Skyline - The Lava Cake: Center Fence Cage": LocData(335448, "The Lava Cake"),
    "Alpine Skyline - The Lava Cake: Outer Island Chest": LocData(334291, "The Lava Cake"),
    "Alpine Skyline - The Lava Cake: Dweller Pillars": LocData(335417, "The Lava Cake"),
    "Alpine Skyline - The Lava Cake: Top Cake": LocData(335418, "The Lava Cake"),
    "Alpine Skyline - The Twilight Path": LocData(334434, "Alpine Free Roam"),
    "Alpine Skyline - The Twilight Bell: Wide Purple Platform": LocData(336478, "The Twilight Bell"),
    "Alpine Skyline - The Twilight Bell: Ice Platform": LocData(335826, "The Twilight Bell",
                                                                required_hats=[HatType.ICE]),
    "Alpine Skyline - Goat Outpost Horn": LocData(334760, "Alpine Free Roam"),
    "Alpine Skyline - Windy Passage": LocData(334776, "Alpine Free Roam"),
    # "Alpine Skyline - The Windmill: Time Trial": LocData(336395, "The Windmill", required_hats=[HatType.DWELLER]),
    "Alpine Skyline - The Windmill: Entrance": LocData(335783, "The Windmill"),
    "Alpine Skyline - The Windmill: Dropdown": LocData(335815, "The Windmill"),
    "Alpine Skyline - The Windmill: House Window": LocData(335389, "The Windmill"),

    "Time's End - Frozen Item": LocData(304108, "Time's End"),
}

act_completions = {
    # 310000 range - Act Completions
    "Act Completion (Time Rift - Gallery)": LocData(312758, "Time Rift - Gallery", required_hats=[HatType.BREWING]),
    "Act Completion (Time Rift - The Lab)": LocData(312838, "Time Rift - The Lab"),

    "Act Completion (Welcome to Mafia Town)": LocData(311771, "Welcome to Mafia Town"),
    "Act Completion (Barrel Battle)": LocData(311958, "Barrel Battle"),
    "Act Completion (She Came from Outer Space)": LocData(312262, "She Came from Outer Space"),
    "Act Completion (Down with the Mafia!)": LocData(311326, "Down with the Mafia!"),
    "Act Completion (Cheating the Race)": LocData(312318, "Cheating the Race"),
    "Act Completion (Heating Up Mafia Town)": LocData(311481, "Heating Up Mafia Town"),
    "Act Completion (The Golden Vault)": LocData(312250, "The Golden Vault"),
    "Act Completion (Time Rift - Bazaar)": LocData(312465, "Time Rift - Bazaar"),
    "Act Completion (Time Rift - Sewers)": LocData(312484, "Time Rift - Sewers"),
    "Act Completion (Time Rift - Mafia of Cooks)": LocData(311855, "Time Rift - Mafia of Cooks"),

    "Act Completion (Dead Bird Studio)": LocData(311383, "Dead Bird Studio"),
    "Act Completion (Murder on the Owl Express)": LocData(311544, "Murder on the Owl Express"),
    "Act Completion (Picture Perfect)": LocData(311587, "Picture Perfect"),
    "Act Completion (Train Rush)": LocData(312481, "Train Rush", hookshot=True),
    "Act Completion (The Big Parade)": LocData(311157, "The Big Parade"),
    "Act Completion (Award Ceremony)": LocData(311488, "Award Ceremony"),
    "Act Completion (Dead Bird Studio Basement)": LocData(312253, "Dead Bird Studio Basement", hookshot=True),
    "Act Completion (Time Rift - The Owl Express)": LocData(312807, "Time Rift - The Owl Express"),
    "Act Completion (Time Rift - The Moon)": LocData(312785, "Time Rift - The Moon"),
    "Act Completion (Time Rift - Dead Bird Studio)": LocData(312577, "Time Rift - Dead Bird Studio"),

    "Act Completion (Contractual Obligations)": LocData(312317, "Contractual Obligations"),
    "Act Completion (The Subcon Well)": LocData(311160, "The Subcon Well", hookshot=True),
    "Act Completion (Toilet of Doom)": LocData(311984, "Toilet of Doom", hookshot=True),
    "Act Completion (Queen Vanessa's Manor)": LocData(312017, "Queen Vanessa's Manor"),
    "Act Completion (Mail Delivery Service)": LocData(312032, "Mail Delivery Service", required_hats=[HatType.SPRINT]),
    "Act Completion (Your Contract has Expired)": LocData(311390, "Your Contract has Expired"),
    "Act Completion (Time Rift - Pipe)": LocData(313069, "Time Rift - Pipe", hookshot=True),
    "Act Completion (Time Rift - Village)": LocData(313056, "Time Rift - Village"),
    "Act Completion (Time Rift - Sleepy Subcon)": LocData(312086, "Time Rift - Sleepy Subcon"),

    "Act Completion (The Birdhouse)": LocData(311428, "The Birdhouse"),
    "Act Completion (The Lava Cake)": LocData(312509, "The Lava Cake"),
    "Act Completion (The Twilight Bell)": LocData(311540, "The Twilight Bell"),
    "Act Completion (The Windmill)": LocData(312263, "The Windmill"),
    "Act Completion (The Illness has Spread)": LocData(312022, "The Illness has Spread", hookshot=True),
    "Act Completion (Time Rift - The Twilight Bell)": LocData(312399, "Time Rift - The Twilight Bell",
                                                              required_hats=[HatType.DWELLER]),
    "Act Completion (Time Rift - Curly Tail Trail)": LocData(313335, "Time Rift - Curly Tail Trail",
                                                             required_hats=[HatType.ICE]),
    "Act Completion (Time Rift - Alpine Skyline)": LocData(311777, "Time Rift - Alpine Skyline"),

    "Act Completion (Time's End - The Finale)": LocData(311872, "Time's End"),
}

storybook_pages = {
    "Mafia of Cooks - Page: Fish Pile": LocData(345091, "Time Rift - Mafia of Cooks"),
    "Mafia of Cooks - Page: Trash Mound": LocData(345090, "Time Rift - Mafia of Cooks"),
    "Mafia of Cooks - Page: Beside Red Building": LocData(345092, "Time Rift - Mafia of Cooks"),
    "Mafia of Cooks - Page: Behind Shipping Containers": LocData(345095, "Time Rift - Mafia of Cooks"),
    "Mafia of Cooks - Page: Top of Boat": LocData(345093, "Time Rift - Mafia of Cooks"),
    "Mafia of Cooks - Page: Below Dock": LocData(345094, "Time Rift - Mafia of Cooks"),

    "Dead Bird Studio (Rift) - Page: Behind Cardboard Planet": LocData(345449, "Time Rift - Dead Bird Studio"),
    "Dead Bird Studio (Rift) - Page: Near Time Rift Gate": LocData(345447, "Time Rift - Dead Bird Studio"),
    "Dead Bird Studio (Rift) - Page: Top of Metal Bar": LocData(345448, "Time Rift - Dead Bird Studio"),
    "Dead Bird Studio (Rift) - Page: Lava Lamp": LocData(345450, "Time Rift - Dead Bird Studio"),
    "Dead Bird Studio (Rift) - Page: Above Horse Picture": LocData(345451, "Time Rift - Dead Bird Studio"),
    "Dead Bird Studio (Rift) - Page: Green Screen": LocData(345452, "Time Rift - Dead Bird Studio"),
    "Dead Bird Studio (Rift) - Page: In The Corner": LocData(345453, "Time Rift - Dead Bird Studio"),
    "Dead Bird Studio (Rift) - Page: Above TV Room": LocData(345445, "Time Rift - Dead Bird Studio"),

    "Sleepy Subcon - Page: Behind Entrance Area": LocData(345373, "Time Rift - Dead Bird Studio"),
    "Sleepy Subcon - Page: Near Wrecking Ball": LocData(345327, "Time Rift - Dead Bird Studio"),
    "Sleepy Subcon - Page: Behind Crane": LocData(345371, "Time Rift - Dead Bird Studio"),
    "Sleepy Subcon - Page: Wrecked Treehouse": LocData(345326, "Time Rift - Dead Bird Studio"),
    "Sleepy Subcon - Page: Behind 2nd Rift Gate": LocData(345372, "Time Rift - Dead Bird Studio"),
    "Sleepy Subcon - Page: Rotating Platform": LocData(345328, "Time Rift - Dead Bird Studio"),
    "Sleepy Subcon - Page: Behind 3rd Rift Gate": LocData(345329, "Time Rift - Dead Bird Studio"),
    "Sleepy Subcon - Page: Frozen Tree": LocData(345330, "Time Rift - Dead Bird Studio"),
    "Sleepy Subcon - Page: Secret Library": LocData(345370, "Time Rift - Dead Bird Studio"),

    "Alpine Skyline (Rift) - Page: Entrance Area Hidden Ledge": LocData(345016, "Time Rift - Alpine Skyline"),
    "Alpine Skyline (Rift) - Page: Windmill Island Ledge": LocData(345012, "Time Rift - Alpine Skyline"),
    "Alpine Skyline (Rift) - Page: Waterfall Wooden Pillar": LocData(345015, "Time Rift - Alpine Skyline"),
    "Alpine Skyline (Rift) - Page: Lonely Birdhouse Top": LocData(345014, "Time Rift - Alpine Skyline"),
    "Alpine Skyline (Rift) - Page: Below Aqueduct": LocData(345013, "Time Rift - Alpine Skyline"),
}

contract_locations = {
    "Snatcher's Contract - The Subcon Well": LocData(300200, "Contractual Obligations"),
    "Snatcher's Contract - Toilet of Doom": LocData(300201, "Subcon Forest Area"),
    "Snatcher's Contract - Queen Vanessa's Manor": LocData(300202, "Subcon Forest Area"),
    "Snatcher's Contract - Mail Delivery Service": LocData(300203, "Subcon Forest Area"),
}

shop_locations = {
    "Badge Seller - Item 1": LocData(301003, "Badge Seller"),
    "Badge Seller - Item 2": LocData(301004, "Badge Seller"),
    "Badge Seller - Item 3": LocData(301005, "Badge Seller"),
    "Badge Seller - Item 4": LocData(301006, "Badge Seller"),
    "Badge Seller - Item 5": LocData(301007, "Badge Seller"),
    "Badge Seller - Item 6": LocData(301008, "Badge Seller"),
    "Badge Seller - Item 7": LocData(301009, "Badge Seller"),
    "Badge Seller - Item 8": LocData(301010, "Badge Seller"),
    "Badge Seller - Item 9": LocData(301011, "Badge Seller"),
    "Badge Seller - Item 10": LocData(301012, "Badge Seller"),
    "Mafia Boss Shop Item": LocData(301013, "Spaceship", required_tps=12),
}

# These are the only locations in Heating Up Mafia Town that are available
humt_locations = [
    "Mafia Town - Crow Chest",
    "Mafia Town - Behind Faucet",
    "Mafia Town - Slip Slide Chest",
    "Mafia Town - Beach Patio",
    "Mafia Town - Yellow Sphere Building Chest",
    "Mafia Town - Cargo Ship",
    "Mafia Town - Top of Lighthouse",
    "Mafia Town - Steel Beam Nest",
    "Mafia Town - Dweller Boxes",
    "Mafia Town - Chest Beneath Aqueduct",
    "Mafia Town - Ledge Chest",
    "Mafia Town - Beneath Scaffolding",
    "Mafia Town - On Scaffolding",
    "Mafia Town - Wood Cage",
    "Mafia Town - Clock Tower Chest",
    "Mafia Town - Secret Cave",
    "Mafia Town - Top of Ruined Tower",
    "Mafia Town - Mafia Geek Platform",
    "Mafia Town - Behind HQ Chest",
    "Mafia Town - Camera Badge 1",
    "Mafia Town - Camera Badge 2",
]

# Locations in Alpine that are available in The Illness has Spread
# Goat Village locations don't need to be put here
tihs_locations = [
    "Alpine Skyline - Bird Pass Fork",
    "Alpine Skyline - Yellow Band Hills",
    "Alpine Skyline - Ember Summit",
    "Alpine Skyline - Goat Outpost Horn",
    "Alpine Skyline - Windy Passage",
]

event_locs = {
    "Windmill Cleared": LocData(0, "The Windmill"),
    "Twilight Bell Cleared": LocData(0, "The Twilight Bell"),
}

location_table = {
    **ahit_locations,
    **act_completions,
    **storybook_pages,
    **contract_locations,
    **shop_locations,
}

lookup_id_to_name: Dict[int, str] = {data.id: name for name, data in location_table.items() if data.id}
