from worlds.AutoWorld import World, CollectionState
from worlds.generic.Rules import add_rule, set_rule
from .Locations import location_table, tihs_locations, zipline_unlocks, is_location_valid, \
    contract_locations
from .Types import HatType, ChapterIndex
from BaseClasses import Location, Entrance, Region
import typing


act_connections = {
    "Mafia Town - Act 2": ["Mafia Town - Act 1"],
    "Mafia Town - Act 3": ["Mafia Town - Act 1"],
    "Mafia Town - Act 4": ["Mafia Town - Act 2", "Mafia Town - Act 3"],
    "Mafia Town - Act 6": ["Mafia Town - Act 4"],
    "Mafia Town - Act 7": ["Mafia Town - Act 4"],
    "Mafia Town - Act 5": ["Mafia Town - Act 6", "Mafia Town - Act 7"],

    "Battle of the Birds - Act 2": ["Battle of the Birds - Act 1"],
    "Battle of the Birds - Act 3": ["Battle of the Birds - Act 1"],
    "Battle of the Birds - Act 4": ["Battle of the Birds - Act 2", "Battle of the Birds - Act 3"],
    "Battle of the Birds - Act 5": ["Battle of the Birds - Act 2", "Battle of the Birds - Act 3"],
    "Battle of the Birds - Finale A": ["Battle of the Birds - Act 4", "Battle of the Birds - Act 5"],
    "Battle of the Birds - Finale B": ["Battle of the Birds - Finale A"],

    "Subcon Forest - Finale": ["Subcon Forest - Act 1", "Subcon Forest - Act 2",
                               "Subcon Forest - Act 3", "Subcon Forest - Act 4",
                               "Subcon Forest - Act 5"],

    "The Arctic Cruise - Act 2":  ["The Arctic Cruise - Act 1"],
    "The Arctic Cruise - Finale": ["The Arctic Cruise - Act 2"],
}


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


def can_hit_bells(state: CollectionState, world: World):
    if world.multiworld.UmbrellaLogic[world.player].value == 0:
        return True

    return state.has("Umbrella", world.player) or can_use_hat(state, world, HatType.BREWING)


# Only use for rifts
def can_clear_act(state: CollectionState, world: World, act_entrance: str) -> bool:
    entrance: Entrance = world.multiworld.get_entrance(act_entrance, world.player)
    if not state.can_reach(entrance.connected_region, player=world.player):
        return False

    if "Free Roam" in entrance.connected_region.name:
        return True

    name: str = format("Act Completion (%s)" % entrance.connected_region.name)
    return world.multiworld.get_location(name, world.player).access_rule(state)


def can_clear_alpine(state: CollectionState, world: World) -> bool:
    return (state.can_reach(world.multiworld.get_location("Act Completion (The Birdhouse)", player=world.player))
            and state.can_reach(world.multiworld.get_location("Act Completion (The Lava Cake)", player=world.player))
            and state.can_reach(world.multiworld.get_location("Act Completion (The Twilight Bell)", player=world.player))
            and state.can_reach(world.multiworld.get_location("Act Completion (The Windmill)", player=world.player)))


def set_rules(world: World):
    w = world
    mw = world.multiworld
    p = world.player

    dlc1: bool = bool(mw.EnableDLC1[p].value > 0)

    # First, chapter access
    starting_chapter = ChapterIndex(mw.StartingChapter[p].value)
    w.set_chapter_cost(starting_chapter, 0)

    # Chapter costs increase progressively. Randomly decide the chapter order, except for Finale
    chapter_list: typing.List[ChapterIndex] = [ChapterIndex.MAFIA, ChapterIndex.BIRDS,
                                               ChapterIndex.SUBCON, ChapterIndex.ALPINE]

    if dlc1:
        chapter_list.append(ChapterIndex.CRUISE)

    chapter_list.remove(starting_chapter)
    mw.random.shuffle(chapter_list)

    if dlc1:
        index = chapter_list.index(ChapterIndex.ALPINE)
        chapter_list.remove(ChapterIndex.CRUISE)
        pos = mw.random.randint(index, len(chapter_list))
        chapter_list.insert(pos, ChapterIndex.CRUISE)

    lowest_cost: int = mw.LowestChapterCost[p].value
    highest_cost: int = mw.HighestChapterCost[p].value

    max_cost_increase: int = 0
    if dlc1:
        max_cost_increase += 6

    highest_cost += min(max_cost_increase, mw.MaxExtraTimePieces[p].value)

    cost_increment: int = mw.ChapterCostIncrement[p].value
    min_difference: int = mw.ChapterCostMinDifference[p].value
    last_cost: int = 0
    cost: int
    loop_count: int = 0

    for chapter in chapter_list:
        min_range: int = lowest_cost + (cost_increment * loop_count)
        if min_range >= highest_cost:
            min_range = highest_cost-1

        value: int = mw.random.randint(min_range, min(highest_cost, max(lowest_cost, last_cost + cost_increment)))

        cost = mw.random.randint(value, min(value + cost_increment, highest_cost))
        if loop_count >= 1:
            if last_cost + min_difference > cost:
                cost = last_cost + min_difference

        cost = min(cost, highest_cost)
        w.set_chapter_cost(chapter, cost)
        last_cost = cost
        loop_count += 1

    minimum: int = mw.Chapter5MinCost[p].value
    maximum: int = mw.Chapter5MaxCost[p].value
    w.set_chapter_cost(ChapterIndex.FINALE, mw.random.randint(min(minimum, maximum), max(minimum, maximum)))

    add_rule(mw.get_entrance("Telescope -> Mafia Town", p),
             lambda state: state.has_group("Time Pieces", p, w.get_chapter_cost(ChapterIndex.MAFIA)))

    add_rule(mw.get_entrance("Telescope -> Battle of the Birds", p),
             lambda state: state.has_group("Time Pieces", p, w.get_chapter_cost(ChapterIndex.BIRDS)))

    add_rule(mw.get_entrance("Telescope -> Subcon Forest", p),
             lambda state: state.has_group("Time Pieces", p, w.get_chapter_cost(ChapterIndex.SUBCON)))

    add_rule(mw.get_entrance("Telescope -> Alpine Skyline", p),
             lambda state: state.has_group("Time Pieces", p, w.get_chapter_cost(ChapterIndex.ALPINE)))

    add_rule(mw.get_entrance("Telescope -> Time's End", p),
             lambda state: state.has_group("Time Pieces", p, w.get_chapter_cost(ChapterIndex.FINALE))
             and can_use_hat(state, w, HatType.BREWING) and can_use_hat(state, w, HatType.DWELLER))

    if dlc1:
        add_rule(mw.get_entrance("Telescope -> The Arctic Cruise", p),
                 lambda state: state.has_group("Time Pieces", p, w.get_chapter_cost(ChapterIndex.ALPINE))
                 and state.has_group("Time Pieces", p, w.get_chapter_cost(ChapterIndex.CRUISE)))

    set_indirect_connections(w)

    if mw.ActRandomizer[p].value == 0:
        set_default_rift_rules(w)

    location: Location
    for (key, data) in location_table.items():
        if not is_location_valid(w, key):
            continue

        if key in contract_locations.keys():
            continue

        location = mw.get_location(key, p)

        # Not all locations in Alpine can be reached from The Illness has Spread
        # as many of the ziplines are blocked off
        if data.region == "Alpine Skyline Area" and key not in tihs_locations:
            add_rule(location, lambda state: state.can_reach("Alpine Free Roam", "Region", p), "and")

        if data.region == "The Birdhouse" or data.region == "The Lava Cake" \
           or data.region == "The Windmill" or data.region == "The Twilight Bell":
            add_rule(location, lambda state: state.can_reach("Alpine Free Roam", "Region", p), "and")

        for hat in data.required_hats:
            if hat is not HatType.NONE:
                add_rule(location, lambda state: can_use_hat(state, w, hat))

        if data.required_tps > 0:
            add_rule(location, lambda state: state.has_group("Time Pieces", p, data.required_tps))

        if data.hookshot:
            add_rule(location, lambda state: can_use_hookshot(state, w))

        if data.umbrella and mw.UmbrellaLogic[p].value > 0:
            add_rule(location, lambda state: state.has("Umbrella", p))

        if data.dweller_bell > 0:
            if data.dweller_bell == 1:  # Required to be hit regardless of Dweller Mask
                add_rule(location, lambda state: can_hit_bells(state, w))
            else:  # Can bypass with Dweller Mask
                add_rule(location, lambda state: can_hit_bells(state, w) or can_use_hat(state, w, HatType.DWELLER))

    set_specific_rules(w)

    if mw.LogicDifficulty[p].value >= 1:
        mw.SDJLogic[p].value = 1

    if mw.SDJLogic[p].value > 0:
        set_sdj_rules(world)

    if mw.ShuffleAlpineZiplines[p].value > 0:
        set_alps_zipline_rules(w)

    for (key, acts) in act_connections.items():
        if "Arctic Cruise" in key and not dlc1:
            continue

        i: int = 1
        entrance: Entrance = mw.get_entrance(key, p)
        region: Region = entrance.connected_region
        access_rules: typing.List[typing.Callable[[CollectionState], bool]] = []
        entrance.parent_region.exits.remove(entrance)
        del entrance.parent_region

        # Entrances to this act that we have to set access_rules on
        entrances: typing.List[Entrance] = []

        for act in acts:
            act_entrance: Entrance = mw.get_entrance(act, p)
            access_rules.append(act_entrance.access_rule)
            required_region = act_entrance.connected_region
            name: str = format("%s: Connection %i" % (key, i))
            new_entrance: Entrance = connect_regions(required_region, region, name, p)
            entrances.append(new_entrance)

            # Copy access rules from act completions
            if "Free Roam" not in required_region.name:
                rule: typing.Callable[[CollectionState], bool]
                name = format("Act Completion (%s)" % required_region.name)
                rule = mw.get_location(name, p).access_rule
                access_rules.append(rule)

            i += 1

        for e in entrances:
            for rules in access_rules:
                add_rule(e, rules)

    mw.completion_condition[p] = lambda state: state.has("Time Piece Cluster", p)


def set_specific_rules(world: World):
    mw = world.multiworld
    w = world
    p = world.player
    dlc1: bool = bool(mw.EnableDLC1[p].value > 0)

    add_rule(mw.get_entrance("Alpine Skyline - Finale", p),
             lambda state: can_clear_alpine(state, w))

    # Normal logic
    if mw.LogicDifficulty[p].value == 0:
        add_rule(mw.get_entrance("-> The Birdhouse", p),
                 lambda state: can_use_hat(state, w, HatType.BREWING))

        add_rule(mw.get_location("Alpine Skyline - Yellow Band Hills", p),
                 lambda state: can_use_hat(state, w, HatType.BREWING))

        if dlc1:
            add_rule(mw.get_location("Act Completion (Time Rift - Deep Sea)", p),
                     lambda state: can_use_hat(state, w, HatType.DWELLER))

            add_rule(mw.get_location("Rock the Boat - Post Captain Rescue", p),
                     lambda state: can_use_hat(state, w, HatType.ICE))

            add_rule(mw.get_location("Act Completion (Rock the Boat)", p),
                     lambda state: can_use_hat(state, w, HatType.ICE))

    # Hard logic, includes SDJ stuff
    if mw.LogicDifficulty[p].value >= 1:
        add_rule(mw.get_location("Act Completion (Time Rift - The Twilight Bell)", p),
                 lambda state: can_use_hat(state, w, HatType.SPRINT) and state.has("Scooter Badge", p), "or")

    # Expert logic
    if mw.LogicDifficulty[p].value >= 2:
        set_rule(mw.get_location("Alpine Skyline - The Twilight Path", p), lambda state: True)
    else:
        add_rule(mw.get_entrance("-> The Twilight Bell", p),
                 lambda state: can_use_hat(state, w, HatType.DWELLER))

    # Cooking Cat requires the player to either have a full relic set, or have 1 relic missing from a set
    # AND have the base piece
    add_rule(mw.get_location("Spaceship - Cooking Cat", p),
             lambda state: state.has("Relic (Burger Patty)", p)
             or state.has("Relic (Mountain Set)", p)
             or (state.count_group("UFO", p) >= 3 and state.has("Relic (UFO)", p))
             or (state.count_group("Crayon", p) >= 3 and state.has("Relic (Crayon Box)", p))
             or (state.count_group("Cake", p) >= 3 and state.has("Relic (Cake Stand)", p))
             or (state.has("Relic (Necklace Bust)", p)))

    add_rule(mw.get_location("Mafia Town - Behind HQ Chest", p),
             lambda state: state.can_reach("Act Completion (Heating Up Mafia Town)", "Location", p)
             or state.can_reach("Down with the Mafia!", "Region", p)
             or state.can_reach("Cheating the Race", "Region", p)
             or state.can_reach("The Golden Vault", "Region", p))

    # Old guys don't appear in SCFOS
    add_rule(mw.get_location("Mafia Town - Old Man (Steel Beams)", p),
             lambda state: state.can_reach("Welcome to Mafia Town", "Region", p)
             or state.can_reach("Barrel Battle", "Region", p)
             or state.can_reach("Cheating the Race", "Region", p)
             or state.can_reach("The Golden Vault", "Region", p)
             or state.can_reach("Down with the Mafia!", "Region", p))

    add_rule(mw.get_location("Mafia Town - Old Man (Seaside Spaghetti)", p),
             lambda state: state.can_reach("Welcome to Mafia Town", "Region", p)
             or state.can_reach("Barrel Battle", "Region", p)
             or state.can_reach("Cheating the Race", "Region", p)
             or state.can_reach("The Golden Vault", "Region", p)
             or state.can_reach("Down with the Mafia!", "Region", p))

    # Only available outside She Came from Outer Space
    add_rule(mw.get_location("Mafia Town - Mafia Geek Platform", p),
             lambda state: state.can_reach("Welcome to Mafia Town", "Region", p)
             or state.can_reach("Barrel Battle", "Region", p)
             or state.can_reach("Down with the Mafia!", "Region", p)
             or state.can_reach("Cheating the Race", "Region", p)
             or state.can_reach("Heating Up Mafia Town", "Region", p)
             or state.can_reach("The Golden Vault", "Region", p))

    # Only available outside Down with the Mafia! (for some reason)
    add_rule(mw.get_location("Mafia Town - On Scaffolding", p),
             lambda state: state.can_reach("Welcome to Mafia Town", "Region", p)
             or state.can_reach("Barrel Battle", "Region", p)
             or state.can_reach("She Came from Outer Space", "Region", p)
             or state.can_reach("Cheating the Race", "Region", p)
             or state.can_reach("Heating Up Mafia Town", "Region", p)
             or state.can_reach("The Golden Vault", "Region", p))

    # For some reason, the brewing crate is removed in HUMT
    set_rule(mw.get_location("Mafia Town - Secret Cave", p),
             lambda state: state.can_reach("Heating Up Mafia Town", "Region", p)
             or can_use_hat(state, w, HatType.BREWING))

    # Can bounce across the lava to get this without Hookshot (need to die though :P)
    set_rule(mw.get_location("Mafia Town - Above Boats", p),
             lambda state: state.can_reach("Heating Up Mafia Town", "Region", p)
             or can_use_hookshot(state, w))

    set_rule(mw.get_location("Act Completion (Cheating the Race)", p),
             lambda state: can_use_hat(state, w, HatType.TIME_STOP)
             or mw.CTRWithSprint[p].value > 0 and can_use_hat(state, w, HatType.SPRINT))

    add_rule(mw.get_entrance("DBS -> Badge Seller", p),
             lambda state: state.can_reach("Dead Bird Studio", "Region", p))

    set_rule(mw.get_location("Subcon Forest - Boss Arena Chest", p),
             lambda state: state.can_reach("Toilet of Doom", "Region", p)
             or state.can_reach("Your Contract has Expired", "Region", p))

    if mw.UmbrellaLogic[p].value > 0:
        add_rule(mw.get_location("Act Completion (Toilet of Doom)", p),
                 lambda state: state.has("Umbrella", p) or can_use_hat(state, w, HatType.BREWING))

    set_rule(mw.get_location("Act Completion (Time Rift - Village)", p),
             lambda state: can_use_hat(state, w, HatType.BREWING) or state.has("Umbrella", p)
             or can_use_hat(state, w, HatType.DWELLER))

    add_rule(mw.get_entrance("Subcon Forest - Act 2", p),
             lambda state: state.has("Snatcher's Contract - The Subcon Well", p)),

    add_rule(mw.get_entrance("Subcon Forest - Act 3", p),
             lambda state: state.has("Snatcher's Contract - Toilet of Doom", p)),

    add_rule(mw.get_entrance("Subcon Forest - Act 4", p),
             lambda state: state.has("Snatcher's Contract - Queen Vanessa's Manor", p)),

    add_rule(mw.get_entrance("Subcon Forest - Act 5", p),
             lambda state: state.has("Snatcher's Contract - Mail Delivery Service", p)),

    add_rule(mw.get_location("Alpine Skyline - Mystifying Time Mesa: Zipline", p),
             lambda state: can_use_hat(state, w, HatType.SPRINT) or can_use_hat(state, w, HatType.TIME_STOP))

    for entrance in mw.get_region("Alpine Free Roam", p).entrances:
        add_rule(entrance, lambda state: can_use_hookshot(state, w))
        if mw.UmbrellaLogic[p].value > 0:
            add_rule(entrance, lambda state: state.has("Umbrella", p))

    if mw.EnableDLC1[p].value > 0:
        add_rule(mw.get_entrance("Cruise Ship Entrance BV", p), lambda state: can_use_hookshot(state, w))


def set_sdj_rules(world: World):
    add_rule(world.multiworld.get_location("Subcon Forest - Long Tree Climb Chest", world.player),
             lambda state: can_sdj(state, world), "or")

    add_rule(world.multiworld.get_location("Subcon Forest - Green and Purple Dweller Rocks", world.player),
             lambda state: can_sdj(state, world), "or")

    add_rule(world.multiworld.get_location("Alpine Skyline - The Birdhouse: Dweller Platforms Relic", world.player),
             lambda state: can_sdj(state, world), "or")

    add_rule(world.multiworld.get_location("Act Completion (Time Rift - Gallery)", world.player),
             lambda state: can_sdj(state, world), "or")

    add_rule(world.multiworld.get_location("Act Completion (Time Rift - Curly Tail Trail)", world.player),
             lambda state: can_sdj(state, world), "or")


def set_alps_zipline_rules(world: World):
    add_rule(world.multiworld.get_entrance("-> The Birdhouse", world.player),
             lambda state: state.has("Zipline Unlock - The Birdhouse Path", world.player))

    add_rule(world.multiworld.get_entrance("-> The Lava Cake", world.player),
             lambda state: state.has("Zipline Unlock - The Lava Cake Path", world.player))

    add_rule(world.multiworld.get_entrance("-> The Windmill", world.player),
             lambda state: state.has("Zipline Unlock - The Windmill Path", world.player))

    add_rule(world.multiworld.get_entrance("-> The Twilight Bell", world.player),
             lambda state: state.has("Zipline Unlock - The Twilight Bell Path", world.player))

    for (loc, zipline) in zipline_unlocks.items():
        add_rule(world.multiworld.get_location(loc, world.player), lambda state: state.has(zipline, world.player))


def reg_act_connection(world: World, region: typing.Union[str, Region], unlocked_entrance: typing.Union[str, Entrance]):
    reg: Region
    entrance: Entrance
    if isinstance(region, str):
        reg = world.multiworld.get_region(region, world.player)
    else:
        reg = region

    if isinstance(unlocked_entrance, str):
        entrance = world.multiworld.get_entrance(unlocked_entrance, world.player)
    else:
        entrance = unlocked_entrance

    world.multiworld.register_indirect_condition(reg, entrance)


def set_indirect_connections(world: World):
    reg_act_connection(world, "The Birdhouse", "Alpine Skyline - Finale")
    reg_act_connection(world, "The Lava Cake", "Alpine Skyline - Finale")
    reg_act_connection(world, "The Windmill", "Alpine Skyline - Finale")
    reg_act_connection(world, "The Twilight Bell", "Alpine Skyline - Finale")


# See randomize_act_entrances in Regions.py
# Called BEFORE set_rules!
def set_rift_rules(world: World, regions: typing.Dict[str, Region]):
    w = world
    mw = world.multiworld
    p = world.player

    # This is accessing the regions in place of these time rifts, so we can set the rules on all the entrances.
    for entrance in regions["Time Rift - Gallery"].entrances:
        add_rule(entrance, lambda state: can_use_hat(state, w, HatType.BREWING)
                 and state.has_group("Time Pieces", p, w.get_chapter_cost(ChapterIndex.BIRDS)))

    for entrance in regions["Time Rift - The Lab"].entrances:
        add_rule(entrance, lambda state: can_use_hat(state, w, HatType.DWELLER)
                 and state.has_group("Time Pieces", p, w.get_chapter_cost(ChapterIndex.ALPINE)))

    for entrance in regions["Time Rift - Sewers"].entrances:
        add_rule(entrance, lambda state: can_clear_act(state, w, "Mafia Town - Act 4"))
        reg_act_connection(w, mw.get_entrance("Mafia Town - Act 4", p).connected_region, entrance)

    for entrance in regions["Time Rift - Bazaar"].entrances:
        add_rule(entrance, lambda state: can_clear_act(state, w, "Mafia Town - Act 6"))
        reg_act_connection(w, mw.get_entrance("Mafia Town - Act 6", p).connected_region, entrance)

    for entrance in regions["Time Rift - Mafia of Cooks"].entrances:
        add_rule(entrance, lambda state: has_relic_combo(state, w, "Burger"))

    for entrance in regions["Time Rift - The Owl Express"].entrances:
        add_rule(entrance, lambda state: can_clear_act(state, w, "Battle of the Birds - Act 2"))
        add_rule(entrance, lambda state: can_clear_act(state, w, "Battle of the Birds - Act 3"))
        reg_act_connection(w, mw.get_entrance("Battle of the Birds - Act 2", p).connected_region, entrance)
        reg_act_connection(w, mw.get_entrance("Battle of the Birds - Act 3", p).connected_region, entrance)

    for entrance in regions["Time Rift - The Moon"].entrances:
        add_rule(entrance, lambda state: can_clear_act(state, w, "Battle of the Birds - Act 4"))
        add_rule(entrance, lambda state: can_clear_act(state, w, "Battle of the Birds - Act 5"))
        reg_act_connection(w, mw.get_entrance("Battle of the Birds - Act 4", p).connected_region, entrance)
        reg_act_connection(w, mw.get_entrance("Battle of the Birds - Act 5", p).connected_region, entrance)

    for entrance in regions["Time Rift - Dead Bird Studio"].entrances:
        add_rule(entrance, lambda state: has_relic_combo(state, w, "Train"))

    for entrance in regions["Time Rift - Pipe"].entrances:
        add_rule(entrance, lambda state: can_clear_act(state, w, "Subcon Forest - Act 2"))
        reg_act_connection(w, mw.get_entrance("Subcon Forest - Act 2", p).connected_region, entrance)

    for entrance in regions["Time Rift - Village"].entrances:
        add_rule(entrance, lambda state: can_clear_act(state, w, "Subcon Forest - Act 4"))
        reg_act_connection(w, mw.get_entrance("Subcon Forest - Act 4", p).connected_region, entrance)

    for entrance in regions["Time Rift - Sleepy Subcon"].entrances:
        add_rule(entrance, lambda state: has_relic_combo(state, w, "UFO"))

    for entrance in regions["Time Rift - Curly Tail Trail"].entrances:
        add_rule(entrance, lambda state: state.has("Windmill Cleared", p))

    for entrance in regions["Time Rift - The Twilight Bell"].entrances:
        add_rule(entrance, lambda state: state.has("Twilight Bell Cleared", p))

    for entrance in regions["Time Rift - Alpine Skyline"].entrances:
        add_rule(entrance, lambda state: has_relic_combo(state, w, "Crayon"))

    if mw.EnableDLC1[p].value > 0:
        for entrance in regions["Time Rift - Balcony"].entrances:
            add_rule(entrance, lambda state: can_clear_act(state, w, "The Arctic Cruise - Finale"))

        for entrance in regions["Time Rift - Deep Sea"].entrances:
            add_rule(entrance, lambda state: has_relic_combo(state, w, "Cake"))

        # for entrance in regions["Time Rift - Tour"].entrances:
        #   add_rule(entrance, lambda state: state.has_group("Time Pieces", p, mw.TourRequiredTimePieces[p].value))


# Basically the same as above, but without the need of the dict since we are just setting defaults
# Called if Act Rando is disabled
def set_default_rift_rules(world: World):
    w = world
    mw = world.multiworld
    p = world.player

    for entrance in mw.get_region("Time Rift - Gallery", p).entrances:
        add_rule(entrance, lambda state: can_use_hat(state, w, HatType.BREWING)
                 and state.has_group("Time Pieces", p, w.get_chapter_cost(ChapterIndex.BIRDS)))

    for entrance in mw.get_region("Time Rift - The Lab", p).entrances:
        add_rule(entrance, lambda state: can_use_hat(state, w, HatType.DWELLER)
                 and state.has_group("Time Pieces", p, w.get_chapter_cost(ChapterIndex.ALPINE)))

    for entrance in mw.get_region("Time Rift - Sewers", p).entrances:
        add_rule(entrance, lambda state: can_clear_act(state, world, "Mafia Town - Act 4"))
        reg_act_connection(w, "Down with the Mafia!", entrance.name)

    for entrance in mw.get_region("Time Rift - Bazaar", p).entrances:
        add_rule(entrance, lambda state: can_clear_act(state, world, "Mafia Town - Act 6"))
        reg_act_connection(w, "Heating Up Mafia Town", entrance.name)

    for entrance in mw.get_region("Time Rift - Mafia of Cooks", p).entrances:
        add_rule(entrance, lambda state: has_relic_combo(state, w, "Burger"))

    for entrance in mw.get_region("Time Rift - The Owl Express", p).entrances:
        add_rule(entrance, lambda state: can_clear_act(state, world, "Battle of the Birds - Act 2"))
        add_rule(entrance, lambda state: can_clear_act(state, world, "Battle of the Birds - Act 3"))
        reg_act_connection(w, "Murder on the Owl Express", entrance.name)
        reg_act_connection(w, "Picture Perfect", entrance.name)

    for entrance in mw.get_region("Time Rift - The Moon", p).entrances:
        add_rule(entrance, lambda state: can_clear_act(state, world, "Battle of the Birds - Act 4"))
        add_rule(entrance, lambda state: can_clear_act(state, world, "Battle of the Birds - Act 5"))
        reg_act_connection(w, "Train Rush", entrance.name)
        reg_act_connection(w, "The Big Parade", entrance.name)

    for entrance in mw.get_region("Time Rift - Dead Bird Studio", p).entrances:
        add_rule(entrance, lambda state: has_relic_combo(state, w, "Train"))

    for entrance in mw.get_region("Time Rift - Pipe", p).entrances:
        add_rule(entrance, lambda state: can_clear_act(state, world, "Subcon Forest - Act 2"))
        reg_act_connection(w, "The Subcon Well", entrance.name)

    for entrance in mw.get_region("Time Rift - Village", p).entrances:
        add_rule(entrance, lambda state: can_clear_act(state, world, "Subcon Forest - Act 4"))
        reg_act_connection(w, "Queen Vanessa's Manor", entrance.name)

    for entrance in mw.get_region("Time Rift - Sleepy Subcon", p).entrances:
        add_rule(entrance, lambda state: has_relic_combo(state, w, "UFO"))

    for entrance in mw.get_region("Time Rift - Curly Tail Trail", p).entrances:
        add_rule(entrance, lambda state: state.has("Windmill Cleared", p))

    for entrance in mw.get_region("Time Rift - The Twilight Bell", p).entrances:
        add_rule(entrance, lambda state: state.has("Twilight Bell Cleared", p))

    for entrance in mw.get_region("Time Rift - Alpine Skyline", p).entrances:
        add_rule(entrance, lambda state: has_relic_combo(state, w, "Crayon"))

    if mw.EnableDLC1[p].value > 0:
        for entrance in mw.get_region("Time Rift - Balcony", p).entrances:
            add_rule(entrance, lambda state: can_clear_act(state, w, "The Arctic Cruise - Finale"))

        for entrance in mw.get_region("Time Rift - Deep Sea", p).entrances:
            add_rule(entrance, lambda state: has_relic_combo(state, w, "Cake"))

        # for entrance in mw.get_region("Time Rift - Tour", p).entrances:
        #   add_rule(entrance, lambda state: state.has_group("Time Pieces", p, mw.TourRequiredTimePieces[p].value))


def connect_regions(start_region: Region, exit_region: Region, entrancename: str, player: int) -> Entrance:
    entrance = Entrance(player, entrancename, start_region)
    start_region.exits.append(entrance)
    entrance.connect(exit_region)
    return entrance
