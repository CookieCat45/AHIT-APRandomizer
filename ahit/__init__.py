from BaseClasses import Item, ItemClassification, Region, LocationProgressType

from .Items import HatInTimeItem, item_table, time_pieces, item_frequencies, item_dlc_enabled, junk_weights,\
    create_item, create_multiple_items, create_junk_items, relic_groups, act_contracts, alps_hooks

from .Regions import create_region, create_regions, connect_regions, randomize_act_entrances, chapter_act_info, \
    create_events, chapter_regions, act_chapters

from .Locations import HatInTimeLocation, location_table, get_total_locations, contract_locations
from .Types import HatDLC, HatType, ChapterIndex
from .Options import ahit_options
from worlds.AutoWorld import World
from .Rules import set_rules
import typing


class HatInTimeWorld(World):
    """
    A Hat in Time is a cute-as-heck 3D platformer featuring a little girl who stitches hats for wicked powers!
    Freely explore giant worlds and recover Time Pieces to travel to new heights!
    """

    game = "A Hat in Time"
    data_version = 1

    item_name_to_id = {name: data.code for name, data in item_table.items()}
    location_name_to_id = {name: data.id for name, data in location_table.items()}

    option_definitions = ahit_options

    hat_craft_order: typing.List[HatType]
    hat_yarn_costs: typing.Dict[HatType, int]
    chapter_timepiece_costs: typing.Dict[ChapterIndex, int]
    act_connections: typing.Dict[str, str] = {}

    item_name_groups = relic_groups
    item_name_groups["Time Pieces"] = set({})
    for name in time_pieces.keys():
        item_name_groups["Time Pieces"].add(name)

    def generate_early(self):
        # If our starting chapter is 4, force hookshot into inventory.
        # Starting chapter 3/4 is banned in act rando, because they don't have enough starting acts
        start_chapter: int = self.multiworld.StartingChapter[self.player].value
        if start_chapter == 4 or start_chapter == 3:
            if self.multiworld.ActRandomizer[self.player].value == 0:
                if start_chapter == 4:
                    self.multiworld.push_precollected(self.create_item("Hookshot Badge"))
            else:
                self.multiworld.StartingChapter[self.player].value = self.multiworld.random.randint(1, 2)

        if self.multiworld.StartWithCompassBadge[self.player].value > 0:
            self.multiworld.push_precollected(self.create_item("Compass Badge"))

    def create_items(self):
        self.hat_yarn_costs = {HatType.SPRINT: -1, HatType.BREWING: -1, HatType.ICE: -1,
                               HatType.DWELLER: -1, HatType.TIME_STOP: -1}

        self.hat_craft_order = [HatType.SPRINT, HatType.BREWING, HatType.ICE,
                                HatType.DWELLER, HatType.TIME_STOP]

        # Item Pool
        itempool: typing.List[Item] = []
        self.calculate_yarn_costs()

        self.topology_present = self.multiworld.ActRandomizer[self.player].value
        yarn_pool: typing.List[Item] = create_multiple_items(self, "Yarn", self.multiworld.YarnAvailable[self.player].value)
        itempool += yarn_pool

        if self.multiworld.RandomizeHatOrder[self.player].value > 0:
            self.multiworld.random.shuffle(self.hat_craft_order)

        for name in item_table.keys():
            if name == "Yarn":
                continue

            if not item_dlc_enabled(self, name):
                continue

            item_type: ItemClassification = item_table.get(name).classification
            if item_type is ItemClassification.filler or item_type is ItemClassification.trap:
                continue

            if name in act_contracts.keys() and self.multiworld.ShuffleActContracts[self.player].value == 0:
                continue

            if name in alps_hooks.keys() and self.multiworld.ShuffleAlpineZiplines[self.player].value == 0:
                continue

            itempool += create_multiple_items(self, name, item_frequencies.get(name, 1))

        create_events(self)
        total_locations: int = get_total_locations(self)
        itempool += create_junk_items(self, total_locations-len(itempool))
        self.multiworld.itempool += itempool

    def create_regions(self):
        create_regions(self)

        # place default contract locations if contract shuffle is off so logic can still utilize them
        if self.multiworld.ShuffleActContracts[self.player].value == 0:
            for name in contract_locations.keys():
                self.multiworld.get_location(name, self.player).place_locked_item(create_item(self, name))
        else:
            # The bag trap contract check needs to be excluded, because if the player has the Subcon Well contract,
            # the trap will not activate, locking the player out of the check permanently
            self.multiworld.get_location("Snatcher's Contract - The Subcon Well",
                                         self.player).progress_type = LocationProgressType.EXCLUDED

    def set_rules(self):
        self.act_connections = {}
        self.chapter_timepiece_costs = {ChapterIndex.MAFIA: -1,
                                        ChapterIndex.BIRDS: -1,
                                        ChapterIndex.SUBCON: -1,
                                        ChapterIndex.ALPINE: -1,
                                        ChapterIndex.FINALE: -1,
                                        ChapterIndex.CRUISE: -1,
                                        ChapterIndex.METRO: -1}

        if self.multiworld.ActRandomizer[self.player].value > 0:
            randomize_act_entrances(self)

        set_rules(self)

    def create_item(self, name: str) -> Item:
        return create_item(self, name)

    def write_spoiler_header(self, spoiler_handle: typing.TextIO):
        for i in self.chapter_timepiece_costs.keys():
            spoiler_handle.write("Chapter %i Cost: %i\n" % (i, self.chapter_timepiece_costs[ChapterIndex(i)]))

        for hat in self.hat_craft_order:
            spoiler_handle.write("Hat Cost: %s: %i\n" % (hat, self.hat_yarn_costs[hat]))

    def fill_slot_data(self) -> dict:
        slot_data: dict = {"SprintYarnCost": self.hat_yarn_costs[HatType.SPRINT],
                           "BrewingYarnCost": self.hat_yarn_costs[HatType.BREWING],
                           "IceYarnCost": self.hat_yarn_costs[HatType.ICE],
                           "DwellerYarnCost": self.hat_yarn_costs[HatType.DWELLER],
                           "TimeStopYarnCost": self.hat_yarn_costs[HatType.TIME_STOP],
                           "Chapter1Cost": self.chapter_timepiece_costs[ChapterIndex.MAFIA],
                           "Chapter2Cost": self.chapter_timepiece_costs[ChapterIndex.BIRDS],
                           "Chapter3Cost": self.chapter_timepiece_costs[ChapterIndex.SUBCON],
                           "Chapter4Cost": self.chapter_timepiece_costs[ChapterIndex.ALPINE],
                           "Chapter5Cost": self.chapter_timepiece_costs[ChapterIndex.FINALE],
                           "Hat1": int(self.hat_craft_order[0]),
                           "Hat2": int(self.hat_craft_order[1]),
                           "Hat3": int(self.hat_craft_order[2]),
                           "Hat4": int(self.hat_craft_order[3]),
                           "Hat5": int(self.hat_craft_order[4])}

        if self.multiworld.ActRandomizer[self.player].value > 0:
            for name in self.act_connections.keys():
                slot_data[name] = self.act_connections[name]

        for option_name in ahit_options:
            option = getattr(self.multiworld, option_name)[self.player]
            slot_data[option_name] = option.value

        return slot_data

    def extend_hint_information(self, hint_data: typing.Dict[int, typing.Dict[int, str]]):
        new_hint_data = {}
        for key, data in location_table.items():
            if data.region not in act_chapters.keys():
                continue

            location = self.multiworld.get_location(key, self.player)
            new_hint_data[location.address] = self.get_shuffled_region(location.parent_region.name)

        hint_data[self.player] = new_hint_data

    def calculate_yarn_costs(self):
        mw = self.multiworld
        p = self.player
        min_yarn_cost = int(min(mw.YarnCostMin[p].value, mw.YarnCostMax[p].value))
        max_yarn_cost = int(max(mw.YarnCostMin[p].value, mw.YarnCostMax[p].value))

        max_cost: int = 0
        for i in range(5):
            cost = mw.random.randint(min(min_yarn_cost, max_yarn_cost), max(max_yarn_cost, min_yarn_cost))
            self.hat_yarn_costs[HatType(i)] = cost
            max_cost += cost

        available_yarn = mw.YarnAvailable[p].value
        if max_cost > available_yarn:
            mw.YarnAvailable[p].value = max_cost
            available_yarn = max_cost

        # make sure we always have at least 8 extra
        if max_cost + 8 > available_yarn:
            mw.YarnAvailable[p].value += (max_cost + 8) - available_yarn

    def set_chapter_cost(self, chapter: ChapterIndex, cost: int):
        self.chapter_timepiece_costs[chapter] = cost

    def get_chapter_cost(self, chapter: ChapterIndex) -> int:
        return self.chapter_timepiece_costs.get(chapter)

    # Sets an act entrance in slot data by specifying the Hat_ChapterActInfo, to be used in-game
    def update_chapter_act_info(self, original_region: Region, new_region: Region):
        original_act_info = chapter_act_info[original_region.name]
        new_act_info = chapter_act_info[new_region.name]
        self.act_connections[original_act_info] = new_act_info

    def get_shuffled_region(self, region: str) -> str:
        if region not in chapter_act_info.keys():
            return region

        ci: str = chapter_act_info[region]
        for name in self.act_connections.keys():
            if ci == name:
                for key in chapter_act_info.keys():
                    if chapter_act_info[key] == self.act_connections[ci]:
                        return key

        return ""
