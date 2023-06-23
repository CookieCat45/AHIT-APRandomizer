from ..AutoWorld import World, CollectionState
from ..generic.Rules import add_rule
from .Items import time_pieces
from .Locations import ahit_locations
from .Types import HatType, RelicType, ChapterIndex
from BaseClasses import Location, Entrance, LocationProgressType, Region
import typing


def can_use_hat(state: CollectionState, world: World, hat: HatType) -> bool:
    return get_remaining_hat_cost(state, world, hat) <= 0


def get_remaining_hat_cost(state: CollectionState, world: World, hat: HatType) -> int:
    cost: int = 0
    for h in world.hat_craft_order:
        cost += world.hat_yarn_costs.get(h)
        if h == hat:
            break

    return max(cost - state.count("Yarn", world.player), 0)


def can_sdj(state: CollectionState, world: World):
    return world.multiworld.SDJLogic[world.player].value is True and can_use_hat(state, world, HatType.SPRINT)


def can_use_hookshot(state: CollectionState, world: World):
    return state.has("Hookshot Badge", world.player)


def get_timepiece_count(state: CollectionState, world: World) -> int:
    count: int = 0
    for (name) in time_pieces.keys():
        if state.has(name, world.player):
            count += 1

    return count


def has_combo(state: CollectionState, world: World, relic: RelicType) -> bool:
    if relic == RelicType.BURGER:
        return state.has("Relic (Burger Patty)", world.player) and state.has("Relic (Burger Cushion)", world.player)

    if relic == RelicType.TRAIN:
        return state.has("Relic (Mountain Set)", world.player) and state.has("Relic (Train)", world.player)

    if relic == RelicType.UFO:
        return state.has("Relic (UFO)", world.player) and state.has("Relic (Cow)", world.player) and \
               state.has("Relic (Cool Cow)", world.player) and state.has("Relic (Tin-foil Hat Cow)", world.player)

    if relic == RelicType.CRAYON:
        return state.has("Relic (Crayon Box)", world.player) and state.has("Relic (Red Crayon)", world.player) and \
               state.has("Relic (Blue Crayon)", world.player) and state.has("Relic (Green Crayon)", world.player)

    if relic == RelicType.CAKE:
        return state.has("Relic (Cake Stand)", world.player) and state.has("Relic (Cake)", world.player) and \
               state.has("Relic (Cake Slice)", world.player) and state.has("Relic (Shortcake)", world.player)

    if relic == RelicType.NECKLACE:
        return state.has("Relic (Necklace Bust)", world.player) and state.has("Relic (Necklace)", world.player)

    return False


def can_clear_act(state: CollectionState, world: World, act_entrance: str) -> bool:
    for location in world.multiworld.get_entrance(act_entrance, world.player).connected_region.locations:
        if "Act Completion" in location.name:
            return state.can_reach(location, player=world.player)

    return True  # Likely a free roam act


def can_reach_mafia_day(state: CollectionState, world: World) -> bool:
    return state.can_reach("Welcome to Mafia Town", player=world.player) \
        or state.can_reach("Barrel Battle", player=world.player) \
        or state.can_reach("Cheating the Race", player=world.player) \
        or state.can_reach("The Golden Vault", player=world.player)


def can_reach_mafia_night(state: CollectionState, world: World) -> bool:
    return state.can_reach("She Came from Outer Space", player=world.player) \
        or state.can_reach("Down with the Mafia!", player=world.player)


def can_reach_mafia_town(state: CollectionState, world: World, lava: bool = True) -> bool:
    return can_reach_mafia_day(state, world) or can_reach_mafia_night(state, world) \
           or (lava and state.can_reach("Heating Up Mafia Town", player=world.player))


def can_reach_subcon_main(state: CollectionState, world: World) -> bool:
    return state.can_reach("Contractual Obligations", player=world.player) \
            or state.can_reach("The Subcon Well", player=world.player) \
            or state.can_reach("Toilet of Doom", player=world.player) \
            or state.can_reach("Queen Vanessa's Manor", player=world.player) \
            or state.can_reach("Mail Delivery Service", player=world.player)


def can_reach_subcon_arena(state: CollectionState, world: World) -> bool:
    return state.can_reach("Toilet of Doom", player=world.player) \
           or state.can_reach("Your Contract has Expired", player=world.player)


def can_clear_alpine(state: CollectionState, world: World) -> bool:
    return (state.can_reach(world.multiworld.get_location("Act Completion (The Birdhouse)", player=world.player))
            and state.can_reach(world.multiworld.get_location("Act Completion (The Lava Cake)", player=world.player))
            and state.can_reach(world.multiworld.get_location("Act Completion (The Twilight Bell)", player=world.player))
            and state.can_reach(world.multiworld.get_location("Act Completion (The Windmill)", player=world.player)))


def set_rules(world: World):
    w = world
    mw = world.multiworld
    p = world.player

    # First, chapter access
    starting_chapter = ChapterIndex(mw.StartingChapter[p].value)
    w.set_chapter_cost(starting_chapter, 0)

    # Chapter costs increase progressively. Randomly decide the chapter order, except for Finale
    chapter_list: typing.List[ChapterIndex] = [ChapterIndex.MAFIA, ChapterIndex.BIRDS,
                                               ChapterIndex.SUBCON, ChapterIndex.ALPINE]
    chapter_list.remove(starting_chapter)
    mw.random.shuffle(chapter_list)

    lowest_cost = mw.LowestChapterCost[p].value
    highest_cost = mw.HighestChapterCost[p].value
    chapter_count = 4
    cost_increment = highest_cost // chapter_count
    loop_count = 0

    for chapter in chapter_list:
        loop_count += 1
        value = lowest_cost + (cost_increment * loop_count)
        w.set_chapter_cost(chapter, mw.random.randint(value, min(value+cost_increment, highest_cost)))

    add_rule(mw.get_entrance("-> Mafia Town", p),
             lambda state: get_timepiece_count(state, w) >= w.get_chapter_cost(ChapterIndex.MAFIA))

    add_rule(mw.get_entrance("-> Battle of the Birds", p),
             lambda state: get_timepiece_count(state, w) >= w.get_chapter_cost(ChapterIndex.BIRDS))

    add_rule(mw.get_entrance("-> Subcon Forest", p),
             lambda state: get_timepiece_count(state, w) >= w.get_chapter_cost(ChapterIndex.SUBCON))

    add_rule(mw.get_entrance("-> Alpine Skyline", p),
             lambda state: get_timepiece_count(state, w) >= w.get_chapter_cost(ChapterIndex.ALPINE))

    add_rule(mw.get_entrance("-> The Birdhouse", p),
             lambda state: can_use_hat(state, w, HatType.BREWING))

    add_rule(mw.get_entrance("-> The Twilight Bell", p),
             lambda state: can_use_hat(state, w, HatType.DWELLER))

    add_rule(mw.get_entrance("-> Time's End", p),
             lambda state: get_timepiece_count(state, w) >= w.get_chapter_cost(ChapterIndex.FINALE)
             and can_use_hat(state, w, HatType.BREWING) and can_use_hat(state, w, HatType.DWELLER))

    # Now act access
    set_act_indirect_connections(w)

    if mw.ActRandomizer[p].value == 0:
        set_default_rift_connections(w)

    act_rules = {

        # Note that these are act entrances, not their corresponding exit regions
        "Spaceship - Time Rift A": lambda state: can_use_hat(state, w, HatType.BREWING)
        and state.can_reach(mw.get_region("Battle of the Birds", player=p)),

        "Spaceship - Time Rift B": lambda state: can_use_hat(state, w, HatType.DWELLER)
        and state.can_reach(mw.get_region("Alpine Skyline", player=p)),

        # Mafia Town ---------------------------------------------------------------------------------------------------
        "Mafia Town - Act 2": lambda state: can_clear_act(state, w, "Mafia Town - Act 1"),
        "Mafia Town - Act 3": lambda state: can_clear_act(state, w, "Mafia Town - Act 1"),

        "Mafia Town - Act 4": lambda state: can_clear_act(state, w, "Mafia Town - Act 2")
        and can_clear_act(state, w, "Mafia Town - Act 3"),

        "Mafia Town - Act 5": lambda state: can_clear_act(state, w, "Mafia Town - Act 6")
        and can_clear_act(state, w, "Mafia Town - Act 7"),

        "Mafia Town - Act 6": lambda state: can_clear_act(state, w, "Mafia Town - Act 4"),
        "Mafia Town - Act 7": lambda state: can_clear_act(state, w, "Mafia Town - Act 4"),

        # Battle of the Birds ------------------------------------------------------------------------------------------
        "Battle of the Birds - Act 2": lambda state: can_clear_act(state, w, "Battle of the Birds - Act 1"),
        "Battle of the Birds - Act 3": lambda state: can_clear_act(state, w, "Battle of the Birds - Act 1"),

        "Battle of the Birds - Act 4": lambda state: can_clear_act(state, w, "Battle of the Birds - Act 2")
        and can_clear_act(state, w, "Battle of the Birds - Act 3"),

        "Battle of the Birds - Act 5": lambda state: can_clear_act(state, w, "Battle of the Birds - Act 2")
        and can_clear_act(state, w, "Battle of the Birds - Act 3"),

        "Battle of the Birds - Act 6A": lambda state: can_clear_act(state, w, "Battle of the Birds - Act 4")
        and can_clear_act(state, w, "Battle of the Birds - Act 5"),

        "Battle of the Birds - Act 6B": lambda state: can_clear_act(state, w, "Battle of the Birds - Act 4")
        and can_clear_act(state, w, "Battle of the Birds - Act 5"),

        # Subcon Forest ------------------------------------------------------------------------------------------------

        # Acts 3 and 5 require their contracts, but 2 and 4 can be entered from any act besides finale.
        # Access to Contractual Obligations is required to get any contracts to begin with, however.
        "Subcon Forest - Act 2": lambda state: can_reach_subcon_main(state, w),
        "Subcon Forest - Act 3": lambda state: state.can_reach(mw.get_region("Contractual Obligations", p)),
        "Subcon Forest - Act 4": lambda state: can_reach_subcon_main(state, w),
        "Subcon Forest - Act 5": lambda state: state.can_reach(mw.get_region("Contractual Obligations", p)),

        # Alpine Skyline -----------------------------------------------------------------------------------------------
        "Alpine Skyline - Act 5": lambda state: can_clear_alpine(state, w),
    }
    for entrance in mw.get_entrances():
        if entrance.name in act_rules.keys():
            add_rule(entrance, act_rules[entrance.name])

    location: Location
    for loc in ahit_locations.keys():
        location = mw.get_location(loc, p)
        if location.parent_region.name == "Mafia Town":
            add_rule(location, lambda state: can_reach_mafia_town(state, w))
        elif location.parent_region.name == "Subcon Forest" and "Boss Arena Chest" not in location.name:
            add_rule(location, lambda state: can_reach_subcon_main(state, w))

    # Spaceship
    add_rule(mw.get_location("Spaceship - Rumbi", p),
             lambda state: get_timepiece_count(state, w) >= 4)
    add_rule(mw.get_location("Spaceship - Cooking Cat", p),
             lambda state: get_timepiece_count(state, w) >= 5)
    add_rule(mw.get_location("Mafia Boss Shop Item", p),
             lambda state: get_timepiece_count(state, w) >= 12
             and get_timepiece_count(state, w) >= w.get_chapter_cost(ChapterIndex.BIRDS))

    # Mafia Town
    add_rule(mw.get_location("Mafia Town - Above Boats", p),
             lambda state: can_use_hookshot(state, w))
    add_rule(mw.get_location("Mafia Town - Clock Tower Chest", p),
             lambda state: can_use_hookshot(state, w))
    add_rule(mw.get_location("Mafia Town - Top of Ruined Tower", p),
             lambda state: can_use_hat(state, w, HatType.ICE))
    add_rule(mw.get_location("Mafia Town - Ice Hat Cage", p),
             lambda state: can_use_hat(state, w, HatType.ICE))
    add_rule(mw.get_location("Mafia Town - Hot Air Balloon", p),
             lambda state: can_use_hat(state, w, HatType.ICE))
    add_rule(mw.get_location("Mafia Town - Top of Lighthouse", p),
             lambda state: can_use_hookshot(state, w))
    add_rule(mw.get_location("Mafia Town - Blue Vault Brewing Crate", p),
             lambda state: can_use_hat(state, w, HatType.BREWING))
    add_rule(mw.get_location("Mafia Town - Secret Cave", p),
             lambda state: can_use_hat(state, w, HatType.BREWING))
    add_rule(mw.get_location("Mafia Town - Behind HQ Chest", p),
             lambda state: state.can_reach("Down with the Mafia!", player=p)
             or state.can_reach(mw.get_location("Act Completion (Heating Up Mafia Town)", player=p)))

    add_rule(mw.get_location("Mafia HQ - Hallway Brewing Crate", p),
             lambda state: can_use_hat(state, w, HatType.BREWING))
    add_rule(mw.get_location("Mafia HQ - Secret Room", p),
             lambda state: can_use_hat(state, w, HatType.ICE))

    # Battle of the Birds
    add_rule(mw.get_location("Murder on the Owl Express - Raven Suite Room", p),
             lambda state: can_use_hat(state, w, HatType.BREWING))

    add_rule(mw.get_location("Dead Bird Studio Basement - Window Platform", p),
             lambda state: can_use_hookshot(state, w))
    add_rule(mw.get_location("Dead Bird Studio Basement - Cardboard Conductor", p),
             lambda state: can_use_hookshot(state, w))
    add_rule(mw.get_location("Dead Bird Studio Basement - Above Conductor Sign", p),
             lambda state: can_use_hookshot(state, w))
    add_rule(mw.get_location("Dead Bird Studio Basement - Disco Room", p),
             lambda state: can_use_hookshot(state, w))
    add_rule(mw.get_location("Dead Bird Studio Basement - Small Room", p),
             lambda state: can_use_hookshot(state, w))
    add_rule(mw.get_location("Dead Bird Studio Basement - Tightrope", p),
             lambda state: can_use_hookshot(state, w))
    add_rule(mw.get_location("Dead Bird Studio Basement - Cameras", p),
             lambda state: can_use_hookshot(state, w))
    add_rule(mw.get_location("Dead Bird Studio Basement - Locked Room", p),
             lambda state: can_use_hookshot(state, w))

    # Subcon Forest
    add_rule(mw.get_location("Subcon Forest - Dweller Stump", p),
             lambda state: can_use_hat(state, w, HatType.DWELLER))

    add_rule(mw.get_location("Subcon Forest - Dweller Floating Rocks", p),
             lambda state: can_use_hat(state, w, HatType.DWELLER))

    add_rule(mw.get_location("Subcon Forest - Dweller Platforming Tree A", p),
             lambda state: can_use_hat(state, w, HatType.DWELLER))  # Can be skipped, a bit tricky tho

    add_rule(mw.get_location("Subcon Forest - Dweller Platforming Tree B", p),
             lambda state: can_use_hat(state, w, HatType.DWELLER) or can_sdj(state, w))

    add_rule(mw.get_location("Subcon Forest - Giant Time Piece", p),
             lambda state: can_use_hat(state, w, HatType.DWELLER))

    add_rule(mw.get_location("Subcon Forest - Green and Purple Dweller Rocks", p),
             lambda state: can_use_hat(state, w, HatType.DWELLER))

    add_rule(mw.get_location("Subcon Forest - Dweller Shack", p),
             lambda state: can_use_hat(state, w, HatType.DWELLER))

    add_rule(mw.get_location("Subcon Forest - Tall Tree Hookshot Swing", p),
             lambda state: can_use_hat(state, w, HatType.DWELLER)
             and can_use_hookshot(state, w))

    add_rule(mw.get_location("Subcon Forest - Noose Treehouse", p),
             lambda state: can_use_hookshot(state, w))

    add_rule(mw.get_location("Subcon Forest - Boss Arena Chest", p),
             lambda state: can_reach_subcon_arena(state, w))

    # Alpine Skyline
    add_rule(mw.get_location("Alpine Skyline - The Birdhouse: Brewing Crate House", p),
             lambda state: can_use_hat(state, w, HatType.BREWING))

    add_rule(mw.get_location("Alpine Skyline - The Birdhouse: Dweller Platforms Relic", p),
             lambda state: can_use_hat(state, w, HatType.DWELLER) or can_sdj(state, w))

    add_rule(mw.get_location("Alpine Skyline - The Windmill: Time Trial", p),
             lambda state: can_use_hat(state, w, HatType.DWELLER) or can_sdj(state, w))

    add_rule(mw.get_location("Alpine Skyline - The Twilight Bell: Ice Platform", p),
             lambda state: can_use_hat(state, w, HatType.ICE) or can_sdj(state, w))

    # --------------------------------------------- Act completions --------------------------------------------- #

    # Spaceship
    add_rule(mw.get_location("Act Completion (Time Rift - Gallery)", p),
             lambda state: can_use_hat(state, w, HatType.BREWING) or can_sdj(state, w))

    # Mafia Town
    add_rule(mw.get_location("Act Completion (Cheating the Race)", p),
             lambda state: can_use_hat(state, w, HatType.TIME_STOP)
             or mw.CTRWithSprint[p].value > 0 and can_use_hat(state, w, HatType.SPRINT))

    # Battle of the Birds
    add_rule(mw.get_location("Act Completion (Train Rush)", p),
             lambda state: can_use_hookshot(state, w))

    add_rule(mw.get_location("Act Completion (Award Ceremony Boss)", p),
             lambda state: can_use_hookshot(state, w))

    # mw.get_location("Act Completion (Award Ceremony)", p).progress_type = LocationProgressType.EXCLUDED

    # Subcon Forest
    add_rule(mw.get_location("Act Completion (Toilet of Doom)", p),
             lambda state: can_use_hookshot(state, w))

    add_rule(mw.get_location("Act Completion (Mail Delivery Service)", p),
             lambda state: can_use_hat(state, w, HatType.SPRINT))

    # Alpine Skyline
    add_rule(mw.get_location("Act Completion (The Illness has Spread)", p),
             lambda state: can_use_hookshot(state, w))  # Just in case of act rando

    add_rule(mw.get_location("Act Completion (Time Rift - The Twilight Bell)", p),
             lambda state: can_use_hat(state, w, HatType.DWELLER))

    add_rule(mw.get_location("Act Completion (Time Rift - Curly Tail Trail)", p),
             lambda state: can_use_hat(state, w, HatType.ICE) or can_sdj(state, w))

    # Other stuff
    mw.completion_condition[p] = lambda state: \
        state.can_reach(mw.get_location("Act Completion (Time's End - The Finale)", player=p))

    alpine_entrance: Entrance = get_alpine_entrance(w)
    add_rule(alpine_entrance, lambda state: can_use_hookshot(state, w))


def get_alpine_entrance(world: World) -> Entrance:
    for region in world.multiworld.get_regions(world.player):
        if region.name == "Alpine Free Roam":
            return region.entrances[0]


def reg_act_connection(world: World, region_name: str, unlocked_entrance: str):
    region = world.multiworld.get_region(region_name, world.player)
    entrance = world.multiworld.get_entrance(unlocked_entrance, world.player)
    world.multiworld.register_indirect_condition(region, entrance)


def set_act_indirect_connections(world: World):
    w = world
    mw = world.multiworld
    p = world.player

    reg_act_connection(w, "Battle of the Birds", "Spaceship - Time Rift A")
    reg_act_connection(w, "Alpine Skyline", "Spaceship - Time Rift B")

    reg_act_connection(w, mw.get_entrance("Mafia Town - Act 1", p).connected_region.name, "Mafia Town - Act 2")
    reg_act_connection(w, mw.get_entrance("Mafia Town - Act 1", p).connected_region.name, "Mafia Town - Act 3")
    reg_act_connection(w, mw.get_entrance("Mafia Town - Act 2", p).connected_region.name, "Mafia Town - Act 4")
    reg_act_connection(w, mw.get_entrance("Mafia Town - Act 3", p).connected_region.name, "Mafia Town - Act 4")
    reg_act_connection(w, mw.get_entrance("Mafia Town - Act 6", p).connected_region.name, "Mafia Town - Act 5")
    reg_act_connection(w, mw.get_entrance("Mafia Town - Act 7", p).connected_region.name, "Mafia Town - Act 5")
    reg_act_connection(w, mw.get_entrance("Mafia Town - Act 4", p).connected_region.name, "Mafia Town - Act 6")
    reg_act_connection(w, mw.get_entrance("Mafia Town - Act 4", p).connected_region.name, "Mafia Town - Act 7")

    reg_act_connection(w, mw.get_entrance("Battle of the Birds - Act 1", p).connected_region.name,
                       "Battle of the Birds - Act 2")

    reg_act_connection(w, mw.get_entrance("Battle of the Birds - Act 1", p).connected_region.name,
                       "Battle of the Birds - Act 3")

    reg_act_connection(w, mw.get_entrance("Battle of the Birds - Act 2", p).connected_region.name,
                       "Battle of the Birds - Act 4")

    reg_act_connection(w, mw.get_entrance("Battle of the Birds - Act 2", p).connected_region.name,
                       "Battle of the Birds - Act 5")

    reg_act_connection(w, mw.get_entrance("Battle of the Birds - Act 3", p).connected_region.name,
                       "Battle of the Birds - Act 4")

    reg_act_connection(w, mw.get_entrance("Battle of the Birds - Act 3", p).connected_region.name,
                       "Battle of the Birds - Act 5")

    reg_act_connection(w, mw.get_entrance("Battle of the Birds - Act 4", p).connected_region.name,
                       "Battle of the Birds - Act 6A")

    reg_act_connection(w, mw.get_entrance("Battle of the Birds - Act 5", p).connected_region.name,
                       "Battle of the Birds - Act 6A")

    reg_act_connection(w, mw.get_entrance("Battle of the Birds - Act 4", p).connected_region.name,
                       "Battle of the Birds - Act 6B")

    reg_act_connection(w, mw.get_entrance("Battle of the Birds - Act 5", p).connected_region.name,
                       "Battle of the Birds - Act 6B")

    reg_act_connection(w, "Contractual Obligations", "Subcon Forest - Act 2")
    reg_act_connection(w, "Toilet of Doom", "Subcon Forest - Act 2")
    reg_act_connection(w, "Queen Vanessa's Manor", "Subcon Forest - Act 2")
    reg_act_connection(w, "Mail Delivery Service", "Subcon Forest - Act 2")

    reg_act_connection(w, "Contractual Obligations", "Subcon Forest - Act 3")

    reg_act_connection(w, "Contractual Obligations", "Subcon Forest - Act 4")
    reg_act_connection(w, "Toilet of Doom", "Subcon Forest - Act 4")
    reg_act_connection(w, "The Subcon Well", "Subcon Forest - Act 4")
    reg_act_connection(w, "Mail Delivery Service", "Subcon Forest - Act 4")

    reg_act_connection(w, "Contractual Obligations", "Subcon Forest - Act 5")

    reg_act_connection(w, mw.get_entrance("Subcon Forest - Act 1", p).connected_region.name, "Subcon Forest - Act 6")
    reg_act_connection(w, mw.get_entrance("Subcon Forest - Act 2", p).connected_region.name, "Subcon Forest - Act 6")
    reg_act_connection(w, mw.get_entrance("Subcon Forest - Act 3", p).connected_region.name, "Subcon Forest - Act 6")
    reg_act_connection(w, mw.get_entrance("Subcon Forest - Act 4", p).connected_region.name, "Subcon Forest - Act 6")
    reg_act_connection(w, mw.get_entrance("Subcon Forest - Act 5", p).connected_region.name, "Subcon Forest - Act 6")

    reg_act_connection(w, "The Birdhouse", "Alpine Skyline - Act 5")
    reg_act_connection(w, "The Lava Cake", "Alpine Skyline - Act 5")
    reg_act_connection(w, "The Windmill", "Alpine Skyline - Act 5")
    reg_act_connection(w, "The Twilight Bell", "Alpine Skyline - Act 5")


# See randomize_act_entrances() in Regions.py
def set_rift_indirect_connections(world: World, regions: typing.Dict[str, Region]):
    w = world
    mw = world.multiworld
    p = world.player

    for entrance in regions["Time Rift - Sewers"].entrances:
        add_rule(entrance, lambda state: can_clear_act(state, world, "Mafia Town - Act 4"))
        reg_act_connection(w, mw.get_entrance("Mafia Town - Act 4", p).connected_region.name, entrance.name)

    for entrance in regions["Time Rift - Bazaar"].entrances:
        add_rule(entrance, lambda state: can_clear_act(state, world, "Mafia Town - Act 6"))
        reg_act_connection(w, mw.get_entrance("Mafia Town - Act 6", p).connected_region.name, entrance.name)

    for entrance in regions["Time Rift - Mafia of Cooks"].entrances:
        add_rule(entrance, lambda state: has_combo(state, w, RelicType.BURGER))

    for entrance in regions["Time Rift - The Owl Express"].entrances:
        add_rule(entrance, lambda state: can_clear_act(state, world, "Battle of the Birds - Act 2"))
        add_rule(entrance, lambda state: can_clear_act(state, world, "Battle of the Birds - Act 3"))
        reg_act_connection(w, mw.get_entrance("Battle of the Birds - Act 2", p).connected_region.name, entrance.name)
        reg_act_connection(w, mw.get_entrance("Battle of the Birds - Act 3", p).connected_region.name, entrance.name)

    for entrance in regions["Time Rift - The Moon"].entrances:
        add_rule(entrance, lambda state: can_clear_act(state, world, "Battle of the Birds - Act 4"))
        add_rule(entrance, lambda state: can_clear_act(state, world, "Battle of the Birds - Act 5"))
        reg_act_connection(w, mw.get_entrance("Battle of the Birds - Act 4", p).connected_region.name, entrance.name)
        reg_act_connection(w, mw.get_entrance("Battle of the Birds - Act 5", p).connected_region.name, entrance.name)

    for entrance in regions["Time Rift - Dead Bird Studio"].entrances:
        add_rule(entrance, lambda state: has_combo(state, w, RelicType.TRAIN))

    for entrance in regions["Time Rift - Pipe"].entrances:
        add_rule(entrance, lambda state: can_clear_act(state, world, "Subcon Forest - Act 2"))
        reg_act_connection(w, mw.get_entrance("Subcon Forest - Act 2", p).connected_region.name, entrance.name)

    for entrance in regions["Time Rift - Village"].entrances:
        add_rule(entrance, lambda state: can_clear_act(state, world, "Subcon Forest - Act 4"))
        reg_act_connection(w, mw.get_entrance("Subcon Forest - Act 4", p).connected_region.name, entrance.name)

    for entrance in regions["Time Rift - Sleepy Subcon"].entrances:
        add_rule(entrance, lambda state: has_combo(state, w, RelicType.UFO))

    for entrance in regions["Time Rift - The Twilight Bell"].entrances:
        add_rule(entrance, lambda state: state.can_reach(mw.get_location("Act Completion (The Twilight Bell)", p)))

    for entrance in regions["Time Rift - Curly Tail Trail"].entrances:
        add_rule(entrance, lambda state: state.can_reach(mw.get_location("Act Completion (The Windmill)", p)))

    for entrance in regions["Time Rift - Alpine Skyline"].entrances:
        add_rule(entrance, lambda state: has_combo(state, w, RelicType.CRAYON))


# Basically the same as above, but without the need of the dict since we are just setting defaults
# Called if Act Rando is disabled
def set_default_rift_connections(world: World):
    w = world
    mw = world.multiworld
    p = world.player

    for entrance in mw.get_region("Time Rift - Sewers", p).entrances:
        add_rule(entrance, lambda state: can_clear_act(state, world, "Mafia Town - Act 4"))
        reg_act_connection(w, mw.get_region("Down with the Mafia!", p).name, entrance.name)

    for entrance in mw.get_region("Time Rift - Bazaar", p).entrances:
        add_rule(entrance, lambda state: can_clear_act(state, world, "Mafia Town - Act 6"))
        reg_act_connection(w, mw.get_region("Heating Up Mafia Town", p).name, entrance.name)

    for entrance in mw.get_region("Time Rift - Mafia of Cooks", p).entrances:
        add_rule(entrance, lambda state: has_combo(state, w, RelicType.BURGER))

    for entrance in mw.get_region("Time Rift - The Owl Express", p).entrances:
        add_rule(entrance, lambda state: can_clear_act(state, world, "Battle of the Birds - Act 2"))
        add_rule(entrance, lambda state: can_clear_act(state, world, "Battle of the Birds - Act 3"))
        reg_act_connection(w, mw.get_region("Murder on the Owl Express", p).name, entrance.name)
        reg_act_connection(w, mw.get_region("Picture Perfect", p).name, entrance.name)

    for entrance in mw.get_region("Time Rift - The Moon", p).entrances:
        add_rule(entrance, lambda state: can_clear_act(state, world, "Battle of the Birds - Act 4"))
        add_rule(entrance, lambda state: can_clear_act(state, world, "Battle of the Birds - Act 5"))
        reg_act_connection(w, mw.get_entrance("Battle of the Birds - Act 4", p).connected_region.name, entrance.name)
        reg_act_connection(w, mw.get_entrance("Battle of the Birds - Act 5", p).connected_region.name, entrance.name)

    for entrance in mw.get_region("Time Rift - Dead Bird Studio", p).entrances:
        add_rule(entrance, lambda state: has_combo(state, w, RelicType.TRAIN))

    for entrance in mw.get_region("Time Rift - Pipe", p).entrances:
        add_rule(entrance, lambda state: can_clear_act(state, world, "Subcon Forest - Act 2"))
        reg_act_connection(w, mw.get_region("The Subcon Well", p).name, entrance.name)

    for entrance in mw.get_region("Time Rift - Village", p).entrances:
        add_rule(entrance, lambda state: can_clear_act(state, world, "Subcon Forest - Act 4"))
        reg_act_connection(w, mw.get_region("Queen Vanessa's Manor", p).name, entrance.name)

    for entrance in mw.get_region("Time Rift - Sleepy Subcon", p).entrances:
        add_rule(entrance, lambda state: has_combo(state, w, RelicType.UFO))

    for entrance in mw.get_region("Time Rift - The Twilight Bell", p).entrances:
        add_rule(entrance, lambda state: state.can_reach(mw.get_location("Act Completion (The Twilight Bell)", p)))

    for entrance in mw.get_region("Time Rift - Curly Tail Trail", p).entrances:
        add_rule(entrance, lambda state: state.can_reach(mw.get_location("Act Completion (The Windmill)", p)))

    for entrance in mw.get_region("Time Rift - Alpine Skyline", p).entrances:
        add_rule(entrance, lambda state: has_combo(state, w, RelicType.CRAYON))
