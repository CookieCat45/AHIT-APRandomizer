from ..AutoWorld import World, CollectionState
from ..generic.Rules import add_rule, set_rule
from .Locations import location_table, humt_locations
from .Types import HatType, ChapterIndex
from BaseClasses import Location, Entrance, Region
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
    return can_use_hat(state, world, HatType.SPRINT)


def can_use_hookshot(state: CollectionState, world: World):
    return state.has("Hookshot Badge", world.player)


def has_relic_combo(state: CollectionState, world: World, relic: str) -> bool:
    return state.has_group(relic, world.player, len(world.item_name_groups[relic]))


def get_relic_count(state: CollectionState, world: World, relic: str) -> int:
    return state.count_group(relic, world.player)


def can_clear_act(state: CollectionState, world: World, act_entrance: str) -> bool:
    entrance: Entrance = world.multiworld.get_entrance(act_entrance, world.player)
    if not state.can_reach(entrance, player=world.player):
        return False

    if "Free Roam" in entrance.connected_region.name:
        return True

    name: str = format("Act Completion (%s)" % entrance.connected_region.name)
    return world.multiworld.get_location(name, world.player).access_rule(state)


def can_reach_mafia_day(state: CollectionState, world: World) -> bool:
    return state.can_reach("Welcome to Mafia Town", player=world.player) \
        or state.can_reach("Barrel Battle", player=world.player) \
        or state.can_reach("Cheating the Race", player=world.player) \
        or state.can_reach("The Golden Vault", player=world.player)


def can_reach_mafia_night(state: CollectionState, world: World) -> bool:
    return state.can_reach("She Came from Outer Space", player=world.player) \
        or state.can_reach("Down with the Mafia!", player=world.player)


def can_reach_mafia_town(state: CollectionState, world: World, lava: bool = False) -> bool:
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
    cost_increment = mw.ChapterCostIncrement[p].value
    loop_count = 0

    for chapter in chapter_list:
        value = mw.random.randint(lowest_cost + (cost_increment * loop_count),
                                  min(highest_cost, lowest_cost + (cost_increment * (loop_count+1))))

        w.set_chapter_cost(chapter, mw.random.randint(value, min(value+cost_increment, highest_cost)))
        loop_count += 1

    minimum = mw.Chapter5MinCost[p].value
    maximum = mw.Chapter5MaxCost[p].value
    w.set_chapter_cost(ChapterIndex.FINALE, mw.random.randint(min(minimum, maximum), max(minimum, maximum)))

    add_rule(mw.get_entrance("-> Mafia Town", p),
             lambda state: state.has_group("Time Pieces", p, w.get_chapter_cost(ChapterIndex.MAFIA)))

    add_rule(mw.get_entrance("-> Battle of the Birds", p),
             lambda state: state.has_group("Time Pieces", p, w.get_chapter_cost(ChapterIndex.BIRDS)))

    add_rule(mw.get_entrance("-> Subcon Forest", p),
             lambda state: state.has_group("Time Pieces", p, w.get_chapter_cost(ChapterIndex.SUBCON)))

    add_rule(mw.get_entrance("-> Alpine Skyline", p),
             lambda state: state.has_group("Time Pieces", p, w.get_chapter_cost(ChapterIndex.ALPINE)))

    add_rule(mw.get_entrance("-> The Birdhouse", p),
             lambda state: can_use_hat(state, w, HatType.BREWING))

    add_rule(mw.get_entrance("-> The Twilight Bell", p),
             lambda state: can_use_hat(state, w, HatType.DWELLER))

    add_rule(mw.get_entrance("-> Time's End", p),
             lambda state: state.has_group("Time Pieces", p, w.get_chapter_cost(ChapterIndex.FINALE))
             and can_use_hat(state, w, HatType.BREWING) and can_use_hat(state, w, HatType.DWELLER))

    set_act_indirect_connections(w)
    if mw.ActRandomizer[p].value == 0:
        set_default_rift_connections(w)

    act_rules = {
        # Note that these are act entrances, not their corresponding exit regions
        "Spaceship - Time Rift A": lambda state: can_use_hat(state, w, HatType.BREWING)
        and state.has_group("Time Pieces", p, w.get_chapter_cost(ChapterIndex.BIRDS)),

        "Spaceship - Time Rift B": lambda state: can_use_hat(state, w, HatType.DWELLER)
        and state.has_group("Time Pieces", p, w.get_chapter_cost(ChapterIndex.ALPINE)),

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

        "Battle of the Birds - Act 6B": lambda state: can_clear_act(state, w, "Battle of the Birds - Act 6A"),

        # Subcon Forest ------------------------------------------------------------------------------------------------

        # You only need to be able to reach the forest for these to get the contracts or access the entrances.
        # TODO: add an option to shuffle contracts into pool as items instead
        "Subcon Forest - Act 2": lambda state: can_reach_subcon_main(state, w),
        "Subcon Forest - Act 3": lambda state: can_reach_subcon_main(state, w),
        "Subcon Forest - Act 4": lambda state: can_reach_subcon_main(state, w),
        "Subcon Forest - Act 5": lambda state: can_reach_subcon_main(state, w),

        "Subcon Forest - Act 6": lambda state: can_clear_act(state, w, "Subcon Forest - Act 1")
        and can_clear_act(state, w, "Subcon Forest - Act 2")
        and can_clear_act(state, w, "Subcon Forest - Act 3")
        and can_clear_act(state, w, "Subcon Forest - Act 4")
        and can_clear_act(state, w, "Subcon Forest - Act 5"),

        # Alpine Skyline -----------------------------------------------------------------------------------------------
        "Alpine Skyline - Act 5": lambda state: can_clear_alpine(state, w),
    }

    for entrance in mw.get_entrances():
        if entrance.name in act_rules.keys():
            add_rule(entrance, act_rules[entrance.name])

    location: Location
    for (key, data) in location_table.items():
        location = mw.get_location(key, p)
        if data.region == "Mafia Town":
            add_rule(location, lambda state: can_reach_mafia_town(state, w, bool(key in humt_locations)))
        elif data.region == "Subcon Forest":
            add_rule(location, lambda state: can_reach_subcon_main(state, w))

        for hat in data.required_hats:
            if hat is not HatType.NONE:
                add_rule(location, lambda state: can_use_hat(state, w, hat))

        if data.required_tps > 0:
            add_rule(location, lambda state: state.has_group("Time Pieces", p, data.required_tps))

        if data.hookshot:
            add_rule(location, lambda state: can_use_hookshot(state, w))

    # ----- Special Rules ----- #

    set_rule(mw.get_location("Mafia Town - Behind HQ Chest", p),
             lambda state: state.can_reach("Down with the Mafia!", player=p)
             or state.can_reach("Heating Up Mafia Town", player=p))

    # For some reason, the brewing crate is removed in HUMT
    set_rule(mw.get_location("Mafia Town - Secret Cave", p),
             lambda state: state.can_reach("Heating Up Mafia Town", player=p)
             or (can_reach_mafia_town(state, w) and can_use_hat(state, w, HatType.BREWING)))

    # Can bounce across the lava to get this without Hookshot (need to die though :P)
    set_rule(mw.get_location("Mafia Town - Above Boats", p),
             lambda state: state.can_reach("Heating Up Mafia Town", player=p)
             or (can_reach_mafia_town(state, w) and can_use_hookshot(state, w)))

    add_rule(mw.get_location("Act Completion (Cheating the Race)", p),
             lambda state: can_use_hat(state, w, HatType.TIME_STOP)
             or mw.CTRWithSprint[p].value > 0 and can_use_hat(state, w, HatType.SPRINT))

    set_rule(mw.get_location("Subcon Forest - Boss Arena Chest", p),
             lambda state: can_reach_subcon_arena(state, w))

    for entrance in mw.get_region("Alpine Free Roam", p).entrances:
        add_rule(entrance, lambda state: can_use_hookshot(state, w))

    # set SDJ rules last
    if mw.SDJLogic[p].value > 0:
        set_sdj_rules(world)

    mw.completion_condition[p] = lambda state: can_use_hat(state, w, HatType.BREWING) \
        and can_use_hat(state, w, HatType.DWELLER) \
        and can_use_hookshot(state, w) \
        and state.has_group("Time Pieces", p, w.get_chapter_cost(ChapterIndex.FINALE))


def set_sdj_rules(world: World):
    set_rule(world.multiworld.get_location("Alpine Skyline - The Birdhouse: Dweller Platforms Relic", world.player),
             lambda state: can_use_hat(state, world, HatType.DWELLER) or can_sdj(state, world))

    set_rule(world.multiworld.get_location("Alpine Skyline - The Windmill: Time Trial", world.player),
             lambda state: can_use_hat(state, world, HatType.DWELLER) or can_sdj(state, world))

    set_rule(world.multiworld.get_location("Alpine Skyline - The Twilight Bell: Ice Platform", world.player),
             lambda state: can_use_hat(state, world, HatType.ICE) or can_sdj(state, world))

    set_rule(world.multiworld.get_location("Act Completion (Time Rift - Gallery)", world.player),
             lambda state: can_use_hat(state, world, HatType.BREWING) or can_sdj(state, world))

    set_rule(world.multiworld.get_location("Act Completion (Time Rift - Curly Tail Trail)", world.player),
             lambda state: can_use_hat(state, world, HatType.ICE) or can_sdj(state, world))


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
    reg_act_connection(w, "The Subcon Well", "Subcon Forest - Act 3")
    reg_act_connection(w, "Queen Vanessa's Manor", "Subcon Forest - Act 3")
    reg_act_connection(w, "Mail Delivery Service", "Subcon Forest - Act 3")

    reg_act_connection(w, "Contractual Obligations", "Subcon Forest - Act 4")
    reg_act_connection(w, "Toilet of Doom", "Subcon Forest - Act 4")
    reg_act_connection(w, "The Subcon Well", "Subcon Forest - Act 4")
    reg_act_connection(w, "Mail Delivery Service", "Subcon Forest - Act 4")

    reg_act_connection(w, "Contractual Obligations", "Subcon Forest - Act 5")
    reg_act_connection(w, "Toilet of Doom", "Subcon Forest - Act 5")
    reg_act_connection(w, "Queen Vanessa's Manor", "Subcon Forest - Act 5")
    reg_act_connection(w, "The Subcon Well", "Subcon Forest - Act 5")

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
        add_rule(entrance, lambda state: has_relic_combo(state, w, "Burger"))

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
        add_rule(entrance, lambda state: has_relic_combo(state, w, "Train"))

    for entrance in regions["Time Rift - Pipe"].entrances:
        add_rule(entrance, lambda state: can_clear_act(state, world, "Subcon Forest - Act 2"))
        reg_act_connection(w, mw.get_entrance("Subcon Forest - Act 2", p).connected_region.name, entrance.name)

    for entrance in regions["Time Rift - Village"].entrances:
        add_rule(entrance, lambda state: can_clear_act(state, world, "Subcon Forest - Act 4"))
        reg_act_connection(w, mw.get_entrance("Subcon Forest - Act 4", p).connected_region.name, entrance.name)

    for entrance in regions["Time Rift - Sleepy Subcon"].entrances:
        add_rule(entrance, lambda state: has_relic_combo(state, w, "UFO"))

    for entrance in regions["Time Rift - Alpine Skyline"].entrances:
        add_rule(entrance, lambda state: has_relic_combo(state, w, "Crayon"))


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

    for entrance in mw.get_region("Time Rift - Pipe", p).entrances:
        add_rule(entrance, lambda state: can_clear_act(state, world, "Subcon Forest - Act 2"))
        reg_act_connection(w, mw.get_region("The Subcon Well", p).name, entrance.name)

    for entrance in mw.get_region("Time Rift - Village", p).entrances:
        add_rule(entrance, lambda state: can_clear_act(state, world, "Subcon Forest - Act 4"))
        reg_act_connection(w, mw.get_region("Queen Vanessa's Manor", p).name, entrance.name)
