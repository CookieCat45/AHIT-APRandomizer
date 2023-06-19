from BaseClasses import Location
from ..AutoWorld import World
from .Types import HatDLC
import typing


class LocData(typing.NamedTuple):
    id: typing.Optional[int]
    region: typing.Optional[str]
    dlc_flags: typing.Optional[HatDLC] = HatDLC.none


class HatInTimeLocation(Location):
    game: str = "A Hat in Time"


def get_total_locations(world: World) -> int:
    total: int = 0

    for (name) in location_table.keys():
        if not location_dlc_enabled(world, name):
            continue

        if name in storybook_pages.keys() \
        and world.multiworld.ShuffleStorybookPages[world.player].value is False:
            continue

        total += 1

    return total


def location_dlc_enabled(world: World, location: str) -> bool:
    data = location_table.get(location)

    if data.dlc_flags == HatDLC.none:
        return True
    elif data.dlc_flags == HatDLC.dlc1 and world.multiworld.EnableDLC1[world.player].value is True:
        return True
    elif data.dlc_flags == HatDLC.dlc2 and world.multiworld.EnableDLC2[world.player].value is True:
        return True
    elif data.dlc_flags == HatDLC.death_wish and world.multiworld.EnableDeathWish[world.player].value is True:
        return True

    return False


ahit_locations = {
    "Spaceship - Mustache Girl": LocData(301000, "Spaceship"),
    "Spaceship - Cooking Cat": LocData(301001, "Spaceship"),
    "Mafia Town - Umbrella": LocData(301002, "Welcome to Mafia Town"),

    # 300000 range - Mafia Town/Batle of the Birds
    "Mafia Town - Red Vault": LocData(302848, "Mafia Town"),
    "Mafia Town - Dweller Boxes": LocData(304462, "Mafia Town"),
    "Mafia Town - Old Man (Steel Beams)": LocData(303832, "Mafia Town"),
    "Mafia Town - Ledge Chest": LocData(303530, "Mafia Town"),
    "Mafia Town - Yellow Sphere Building Chest": LocData(303535, "Mafia Town"),
    "Mafia Town - Beneath Scaffolding": LocData(304456, "Mafia Town"),
    "Mafia Town - On Scaffolding": LocData(304457, "Mafia Town"),
    "Mafia Town - Plaza Under Boxes": LocData(304458, "Mafia Town"),
    "Mafia Town - Blue Vault Brewing Crate": LocData(305572, "Mafia Town"),
    "Mafia Town - Small Boat": LocData(304460, "Mafia Town"),
    "Mafia Town - Cargo Ship": LocData(304459, "Mafia Town"),
    "Mafia Town - Beach Alcove": LocData(304463, "Mafia Town"),
    "Mafia Town - Wood Cage": LocData(304606, "Mafia Town"),
    "Mafia Town - Staircase Pon Cluster": LocData(304611, "Mafia Town"),
    "Mafia Town - Blue Vault": LocData(302850, "Mafia Town"),
    "Mafia Town - Old Man (Seaside Spaghetti)": LocData(303833, "Mafia Town"),
    "Mafia Town - Palm Tree": LocData(304609, "Mafia Town"),
    "Mafia Town - Beach Patio": LocData(304610, "Mafia Town"),
    "Mafia Town - Steel Beam Nest": LocData(304608, "Mafia Town"),
    "Mafia Town - Top of Ruined Tower": LocData(304607, "Mafia Town"),
    "Mafia Town - Ice Hat Cage": LocData(304831, "Mafia Town"),
    "Mafia Town - Hot Air Balloon": LocData(304829, "Mafia Town"),
    "Mafia Town - Camera Badge": LocData(310024, "Mafia Town"),
    "Mafia Town - Chest Beneath Aqueduct": LocData(303489, "Mafia Town"),
    "Mafia Town - Secret Cave": LocData(305220, "Mafia Town"),
    "Mafia Town - Crow Chest": LocData(303532, "Mafia Town"),
    "Mafia Town - Port": LocData(305219, "Mafia Town"),
    "Mafia Town - Docks Chest": LocData(303534, "Mafia Town"),
    "Mafia Town - Above Boats": LocData(305218, "Mafia Town"),
    "Mafia Town - Slip Slide Chest": LocData(303529, "Mafia Town"),
    "Mafia Town - Green Vault": LocData(302851, "Mafia Town"),
    "Mafia Town - Behind Faucet": LocData(304214, "Mafia Town"),
    "Mafia Town - Hidden Buttons Chest": LocData(303483, "Mafia Town"),
    "Mafia Town - Clock Tower Chest": LocData(303481, "Mafia Town"),
    "Mafia Town - Top of Lighthouse": LocData(304213, "Mafia Town"),
    "Mafia Town - Mafia Geek Platform": LocData(304212, "Mafia Town"),
    "Mafia Town - Behind HQ Chest": LocData(303486, "Mafia Town"),

    "Mafia HQ - Hallway Brewing Crate": LocData(305387, "Down with the Mafia!"),
    "Mafia HQ - Freezer Chest": LocData(303241, "Down with the Mafia!"),
    "Mafia HQ - Secret Room": LocData(304979, "Down with the Mafia!"),
    "Mafia HQ - Bathroom Stall Chest": LocData(303243, "Down with the Mafia!"),

    "Dead Bird Studio - Up the Ladder": LocData(304874, "Dead Bird Studio"),
    "Dead Bird Studio - DJ Grooves Sign Chest": LocData(303901, "Dead Bird Studio"),
    "Dead Bird Studio - Red Building Top": LocData(305024, "Dead Bird Studio"),
    "Dead Bird Studio - Behind Water Tower": LocData(305248, "Dead Bird Studio"),
    "Dead Bird Studio - Side of House": LocData(305247, "Dead Bird Studio"),
    "Dead Bird Studio - Tightrope Chest": LocData(303898, "Dead Bird Studio"),
    "Dead Bird Studio - Tepee Chest": LocData(303899, "Dead Bird Studio"),
    "Dead Bird Studio - Conductor Chest": LocData(303900, "Dead Bird Studio"),

    "Murder on the Owl Express - Cafeteria": LocData(305313, "Murder on the Owl Express"),
    "Murder on the Owl Express - Luggage Room Top": LocData(305090, "Murder on the Owl Express"),
    "Murder on the Owl Express - Luggage Room Bottom": LocData(305091, "Murder on the Owl Express"),
    "Murder on the Owl Express - Raven Suite Room": LocData(305701, "Murder on the Owl Express"),
    "Murder on the Owl Express - Raven Suite Top": LocData(305312, "Murder on the Owl Express"),

    "Picture Perfect - Behind Badge Seller": LocData(304307, "Picture Perfect"),
    "Picture Perfect - Hats Buy Building": LocData(304530, "Picture Perfect"),

    "Dead Bird Studio Basement - Window Platform": LocData(305432, "Dead Bird Studio Basement"),
    "Dead Bird Studio Basement - Cardboard Conductor": LocData(305059, "Dead Bird Studio Basement"),
    "Dead Bird Studio Basement - Above Conductor Sign": LocData(305057, "Dead Bird Studio Basement"),
    "Dead Bird Studio Basement - Logo Wall": LocData(305207, "Dead Bird Studio Basement"),
    "Dead Bird Studio Basement - Disco Room": LocData(305061, "Dead Bird Studio Basement"),
    "Dead Bird Studio Basement - Small Room": LocData(304813, "Dead Bird Studio Basement"),
    "Dead Bird Studio Basement - Vent Pipe": LocData(305430, "Dead Bird Studio Basement"),
    "Dead Bird Studio Basement - Tightrope": LocData(305058, "Dead Bird Studio Basement"),
    "Dead Bird Studio Basement - Cameras": LocData(305431, "Dead Bird Studio Basement"),
    "Dead Bird Studio Basement - Locked Room": LocData(305819, "Dead Bird Studio Basement"),

    # 320000 range - Subcon Forest
    "Subcon Forest - Cherry Bomb Bone Cage": LocData(324761, "Subcon Forest"),
    "Subcon Forest - Village Tree Top Ice Cube": LocData(325078, "Subcon Forest"),
    "Subcon Forest - Village Graveyard Ice Cube": LocData(325077, "Subcon Forest"),
    "Subcon Forest - Village House Top": LocData(325471, "Subcon Forest"),
    "Subcon Forest - Village Ice Cube House": LocData(325469, "Subcon Forest"),
    "Subcon Forest - Village Snatcher Statue Chest": LocData(323730, "Subcon Forest"),
    "Subcon Forest - Village Stump Platform Chest": LocData(323729, "Subcon Forest"),
    "Subcon Forest - Giant Mushroom Climb": LocData(325470, "Subcon Forest"),
    "Subcon Forest - Swamp Near Well": LocData(324762, "Subcon Forest"),
    "Subcon Forest - Swamp Tree A": LocData(324763, "Subcon Forest"),
    "Subcon Forest - Swamp Tree B": LocData(324764, "Subcon Forest"),
    "Subcon Forest - Swamp Ice Wall": LocData(324706, "Subcon Forest"),
    "Subcon Forest - Swamp Treehouse": LocData(325468, "Subcon Forest"),
    "Subcon Forest - Swamp Tree Chest": LocData(323728, "Subcon Forest"),
    "Subcon Forest - Dweller Stump": LocData(324767, "Subcon Forest"),
    "Subcon Forest - Dweller Floating Rocks": LocData(324464, "Subcon Forest"),
    "Subcon Forest - Dweller Platforming Tree A": LocData(324709, "Subcon Forest"),
    "Subcon Forest - Dweller Platforming Tree B": LocData(324855, "Subcon Forest"),
    "Subcon Forest - Giant Time Piece": LocData(325473, "Subcon Forest"),
    "Subcon Forest - Gallows": LocData(325472, "Subcon Forest"),
    "Subcon Forest - Green and Purple Dweller Rocks": LocData(325082, "Subcon Forest"),
    "Subcon Forest - Dweller Shack": LocData(324463, "Subcon Forest"),
    "Subcon Forest - Tall Tree Hookshot Swing": LocData(324766, "Subcon Forest"),
    "Subcon Forest - Burning House": LocData(324710, "Subcon Forest"),
    "Subcon Forest - Burning Tree Climb": LocData(325079, "Subcon Forest"),
    "Subcon Forest - Burning Stump Chest": LocData(323731, "Subcon Forest"),
    "Subcon Forest - Burning Forest Treehouse": LocData(325467, "Subcon Forest"),
    "Subcon Forest - Spider Bone Cage A": LocData(324462, "Subcon Forest"),
    "Subcon Forest - Spider Bone Cage B": LocData(325080, "Subcon Forest"),
    "Subcon Forest - Triple Spider Bounce": LocData(324765, "Subcon Forest"),
    "Subcon Forest - Noose Treehouse": LocData(324856, "Subcon Forest"),
    "Subcon Forest - Ice Cube Shack": LocData(324465, "Subcon Forest"),
    "Subcon Forest - Long Tree Climb Chest": LocData(323734, "Subcon Forest"),
    "Subcon Forest - Boss Arena Chest": LocData(323735, "Subcon Forest"),
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
    "Alpine Skyline - Goat Village: Below Hookpoint": LocData(334856, "Alpine Free Roam"),
    "Alpine Skyline - Goat Village: Hidden Branch": LocData(334855, "Alpine Free Roam"),
    "Alpine Skyline - Goat Refinery": LocData(333635, "Alpine Free Roam"),
    "Alpine Skyline - Bird Pass Fork": LocData(335911, "Alpine Free Roam"),
    "Alpine Skyline - Yellow Band Hills": LocData(335756, "Alpine Free Roam"),
    "Alpine Skyline - The Purrloined Village: Horned Stone": LocData(335561, "Alpine Free Roam"),
    "Alpine Skyline - The Purrloined Village: Chest Reward": LocData(334831, "Alpine Free Roam"),
    "Alpine Skyline - The Birdhouse: Triple Crow Chest": LocData(334758, "The Birdhouse"),
    "Alpine Skyline - The Birdhouse: Dweller Platforms Relic": LocData(336497, "The Birdhouse"),
    "Alpine Skyline - The Birdhouse: Brewing Crate House": LocData(336496, "The Birdhouse"),
    "Alpine Skyline - The Birdhouse: Hay Bale": LocData(335885, "The Birdhouse"),
    "Alpine Skyline - The Birdhouse: Alpine Crow Mini-Gauntlet": LocData(335886, "The Birdhouse"),
    "Alpine Skyline - The Birdhouse: Outer Edge": LocData(335492, "The Birdhouse"),

    "Alpine Skyline - Mystifying Time Mesa: Zipline": LocData(337058, "Alpine Free Roam"),  # Possibly requires Sprint?
    "Alpine Skyline - Mystifying Time Mesa: Gate Puzzle": LocData(336052, "Alpine Free Roam"),
    "Alpine Skyline - Ember Summit": LocData(336311, "Alpine Free Roam"),
    "Alpine Skyline - The Lava Cake: Center Fence Cage": LocData(335448, "The Lava Cake"),
    "Alpine Skyline - The Lava Cake: Outer Island Chest": LocData(334291, "The Lava Cake"),
    "Alpine Skyline - The Lava Cake: Dweller Pillars": LocData(335417, "The Lava Cake"),
    "Alpine Skyline - The Lava Cake: Top Cake": LocData(335418, "The Lava Cake"),
    "Alpine Skyline - The Twilight Path": LocData(334434, "Alpine Free Roam"),
    "Alpine Skyline - The Twilight Bell: Wide Purple Platform": LocData(336478, "The Twilight Bell"),
    "Alpine Skyline - The Twilight Bell: Ice Platform": LocData(335826, "The Twilight Bell"),
    "Alpine Skyline - Goat Outpost Horn": LocData(334760, "Alpine Free Roam"),
    "Alpine Skyline - Windy Passage": LocData(334776, "Alpine Free Roam"),
    "Alpine Skyline - The Windmill: Bird Nest": LocData(336395, "The Windmill"),
    "Alpine Skyline - The Windmill: Entrance": LocData(335783, "The Windmill"),
    "Alpine Skyline - The Windmill: Dropdown": LocData(335815, "The Windmill"),
    "Alpine Skyline - The Windmill: House Window": LocData(335389, "The Windmill"),
}

act_completions = {
    # 310000 range - Act Completions
    "Act Completion (Time Rift - Gallery)": LocData(312758, "Time Rift - Gallery"),
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
    "Act Completion (Train Rush)": LocData(312481, "Train Rush"),
    "Act Completion (The Big Parade)": LocData(311157, "The Big Parade"),
    "Act Completion (Award Ceremony)": LocData(311488, "Award Ceremony"),
    "Act Completion (Award Ceremony Boss)": LocData(312253, "Dead Bird Studio Basement"),
    "Act Completion (Time Rift - The Owl Express)": LocData(312807, "Time Rift - The Owl Express"),
    "Act Completion (Time Rift - The Moon)": LocData(312785, "Time Rift - The Moon"),
    "Act Completion (Time Rift - Dead Bird Studio)": LocData(312577, "Time Rift - Dead Bird Studio"),

    "Act Completion (Contractual Obligations)": LocData(312317, "Contractual Obligations"),
    "Act Completion (The Subcon Well)": LocData(311160, "The Subcon Well"),
    "Act Completion (Toilet of Doom)": LocData(311984, "Toilet of Doom"),
    "Act Completion (Queen Vanessa's Manor)": LocData(312017, "Queen Vanessa's Manor"),
    "Act Completion (Mail Delivery Service)": LocData(312032, "Mail Delivery Service"),
    "Act Completion (Your Contract has Expired)": LocData(311390, "Your Contract has Expired"),
    "Act Completion (Time Rift - Pipe)": LocData(313069, "Time Rift - Pipe"),
    "Act Completion (Time Rift - Village)": LocData(313056, "Time Rift - Village"),
    "Act Completion (Time Rift - Sleepy Subcon)": LocData(312086, "Time Rift - Sleepy Subcon"),

    "Act Completion (The Birdhouse)": LocData(311428, "The Birdhouse"),
    "Act Completion (The Lava Cake)": LocData(312509, "The Lava Cake"),
    "Act Completion (The Twilight Bell)": LocData(311540, "The Twilight Bell"),
    "Act Completion (The Windmill)": LocData(312263, "The Windmill"),
    "Act Completion (The Illness has Spread)": LocData(312022, "The Illness has Spread"),
    "Act Completion (Time Rift - The Twilight Bell)": LocData(312399, "Time Rift - The Twilight Bell"),
    "Act Completion (Time Rift - Curly Tail Trail)": LocData(313335, "Time Rift - Curly Tail Trail"),
    "Act Completion (Time Rift - Alpine Skyline)": LocData(311777, "Time Rift - Alpine Skyline"),

    "Act Completion (Time's End - The Finale)": LocData(311778, "Time's End"),
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

    "Sleepy Subcon - Page: Behind Entrance Area": LocData(365373, "Time Rift - Dead Bird Studio"),
    "Sleepy Subcon - Page: Near Wrecking Ball": LocData(365327, "Time Rift - Dead Bird Studio"),
    "Sleepy Subcon - Page: Behind Crane": LocData(365371, "Time Rift - Dead Bird Studio"),
    "Sleepy Subcon - Page: Wrecked Treehouse": LocData(365326, "Time Rift - Dead Bird Studio"),
    "Sleepy Subcon - Page: Behind 2nd Rift Gate": LocData(365372, "Time Rift - Dead Bird Studio"),
    "Sleepy Subcon - Page: Rotating Platform": LocData(365328, "Time Rift - Dead Bird Studio"),
    "Sleepy Subcon - Page: Behind 3rd Rift Gate": LocData(365329, "Time Rift - Dead Bird Studio"),
    "Sleepy Subcon - Page: Frozen Tree": LocData(365330, "Time Rift - Dead Bird Studio"),
    "Sleepy Subcon - Page: Secret Library": LocData(365370, "Time Rift - Dead Bird Studio"),

    "Alpine Skyline (Rift) - Page: Entrance Area Hidden Ledge": LocData(375016, "Time Rift - Alpine Skyline"),
    "Alpine Skyline (Rift) - Page: Windmill Island Ledge": LocData(375012, "Time Rift - Alpine Skyline"),
    "Alpine Skyline (Rift) - Page: Waterfall Wooden Pillar": LocData(375015, "Time Rift - Alpine Skyline"),
    "Alpine Skyline (Rift) - Page: Lonely Birdhouse Top": LocData(375014, "Time Rift - Alpine Skyline"),
    "Alpine Skyline (Rift) - Page: Below Aqueduct": LocData(375013, "Time Rift - Alpine Skyline"),
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
}

location_table = {
    **ahit_locations,
    **act_completions,
    **storybook_pages,
    **shop_locations,
}

lookup_id_to_name: typing.Dict[int, str] = {data.id: name for name, data in location_table.items() if data.id}
