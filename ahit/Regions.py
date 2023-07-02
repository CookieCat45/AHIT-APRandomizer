from ..AutoWorld import World
from BaseClasses import Region, Entrance, ItemClassification, Location
from .Locations import HatInTimeLocation, location_table, storybook_pages, event_locs
from .Items import HatInTimeItem
from .Types import ChapterIndex
import typing
from .Rules import set_rift_rules


# ChapterIndex: region
chapter_regions = {
    ChapterIndex.SPACESHIP: "Spaceship",
    ChapterIndex.MAFIA: "Mafia Town",
    ChapterIndex.BIRDS: "Battle of the Birds",
    ChapterIndex.SUBCON: "Subcon Forest",
    ChapterIndex.ALPINE: "Alpine Skyline",
    ChapterIndex.FINALE: "Time's End",
    ChapterIndex.CRUISE: "Arctic Cruise",
    ChapterIndex.METRO: "Nyakuza Metro",
}

# entrance: region
act_entrances = {
    "Spaceship - Time Rift A":        "Time Rift - Gallery",
    "Spaceship - Time Rift B":        "Time Rift - The Lab",

    "Mafia Town - Act 1":             "Welcome to Mafia Town",
    "Mafia Town - Act 2":             "Barrel Battle",
    "Mafia Town - Act 3":             "She Came from Outer Space",
    "Mafia Town - Act 4":             "Down with the Mafia!",
    "Mafia Town - Act 5":             "Cheating the Race",
    "Mafia Town - Act 6":             "Heating Up Mafia Town",
    "Mafia Town - Act 7":             "The Golden Vault",

    "Battle of the Birds - Act 1":              "Dead Bird Studio",
    "Battle of the Birds - Act 2":              "Murder on the Owl Express",
    "Battle of the Birds - Act 3":              "Picture Perfect",
    "Battle of the Birds - Act 4":              "Train Rush",
    "Battle of the Birds - Act 5":              "The Big Parade",
    "Battle of the Birds - Finale A":             "Award Ceremony",
    "Battle of the Birds - Finale B":             "Dead Bird Studio Basement",

    "Subcon Forest - Act 1":            "Contractual Obligations",
    "Subcon Forest - Act 2":            "The Subcon Well",
    "Subcon Forest - Act 3":            "Toilet of Doom",
    "Subcon Forest - Act 4":            "Queen Vanessa's Manor",
    "Subcon Forest - Act 5":            "Mail Delivery Service",
    "Subcon Forest - Finale":            "Your Contract has Expired",

    "Alpine Skyline - Free Roam":        "Alpine Free Roam",
    "Alpine Skyline - Finale":            "The Illness has Spread",
}

act_chapters = {
    "Time Rift - Gallery":          "Spaceship",
    "Time Rift - The Lab":          "Spaceship",

    "Welcome to Mafia Town":        "Mafia Town",
    "Barrel Battle":                "Mafia Town",
    "She Came from Outer Space":    "Mafia Town",
    "Down with the Mafia!":         "Mafia Town",
    "Cheating the Race":            "Mafia Town",
    "Heating Up Mafia Town":        "Mafia Town",
    "The Golden Vault":             "Mafia Town",
    "Time Rift - Mafia of Cooks":   "Mafia Town",
    "Time Rift - Sewers":           "Mafia Town",
    "Time Rift - Bazaar":           "Mafia Town",

    "Dead Bird Studio":             "Battle of the Birds",
    "Murder on the Owl Express":    "Battle of the Birds",
    "Picture Perfect":              "Battle of the Birds",
    "Train Rush":                   "Battle of the Birds",
    "The Big Parade":               "Battle of the Birds",
    "Award Ceremony":               "Battle of the Birds",
    "Dead Bird Studio Basement":    "Battle of the Birds",
    "Time Rift - Dead Bird Studio": "Battle of the Birds",
    "Time Rift - The Owl Express":  "Battle of the Birds",
    "Time Rift - The Moon":         "Battle of the Birds",

    "Contractual Obligations":      "Subcon Forest",
    "The Subcon Well":              "Subcon Forest",
    "Toilet of Doom":               "Subcon Forest",
    "Queen Vanessa's Manor":        "Subcon Forest",
    "Mail Delivery Service":        "Subcon Forest",
    "Your Contract has Expired":    "Subcon Forest",
    "Time Rift - Sleepy Subcon":    "Subcon Forest",
    "Time Rift - Pipe":             "Subcon Forest",
    "Time Rift - Village":          "Subcon Forest",

    "Alpine Free Roam":                 "Alpine Skyline",
    "The Illness has Spread":           "Alpine Skyline",
    "Time Rift - Alpine Skyline":       "Alpine Skyline",
    "Time Rift - The Twilight Bell":    "Alpine Skyline",
    "Time Rift - Curly Tail Trail":     "Alpine Skyline",

    "The Finale":                       "Time's End"
}

# Hat_ChapterActInfo, from the game files to be used in act shuffle
chapter_act_info = {
    "Time Rift - Gallery":          "hatintime_chapterinfo.spaceship.Spaceship_WaterRift_Gallery",
    "Time Rift - The Lab":          "hatintime_chapterinfo.spaceship.Spaceship_WaterRift_MailRoom",

    "Welcome to Mafia Town":        "hatintime_chapterinfo.MafiaTown.MafiaTown_Welcome",
    "Barrel Battle":                "hatintime_chapterinfo.MafiaTown.MafiaTown_BarrelBattle",
    "She Came from Outer Space":    "hatintime_chapterinfo.MafiaTown.MafiaTown_AlienChase",
    "Down with the Mafia!":         "hatintime_chapterinfo.MafiaTown.MafiaTown_MafiaBoss",
    "Cheating the Race":            "hatintime_chapterinfo.MafiaTown.MafiaTown_Race",
    "Heating Up Mafia Town":        "hatintime_chapterinfo.MafiaTown.MafiaTown_Lava",
    "The Golden Vault":             "hatintime_chapterinfo.MafiaTown.MafiaTown_GoldenVault",
    "Time Rift - Mafia of Cooks":   "hatintime_chapterinfo.MafiaTown.MafiaTown_CaveRift_Mafia",
    "Time Rift - Sewers":           "hatintime_chapterinfo.MafiaTown.MafiaTown_WaterRift_Easy",
    "Time Rift - Bazaar":           "hatintime_chapterinfo.MafiaTown.MafiaTown_WaterRift_Hard",

    "Dead Bird Studio":             "hatintime_chapterinfo.BattleOfTheBirds.BattleOfTheBirds_DeadBirdStudio",
    "Murder on the Owl Express":    "hatintime_chapterinfo.BattleOfTheBirds.BattleOfTheBirds_Murder",
    "Picture Perfect":              "hatintime_chapterinfo.BattleOfTheBirds.BattleOfTheBirds_PicturePerfect",
    "Train Rush":                   "hatintime_chapterinfo.BattleOfTheBirds.BattleOfTheBirds_TrainRush",
    "The Big Parade":               "hatintime_chapterinfo.BattleOfTheBirds.BattleOfTheBirds_Parade",
    "Award Ceremony":               "hatintime_chapterinfo.BattleOfTheBirds.BattleOfTheBirds_AwardCeremony",
    "Dead Bird Studio Basement":    "DeadBirdBasement",  # Dead Bird Studio Basement has no ChapterActInfo
    "Time Rift - Dead Bird Studio": "hatintime_chapterinfo.BattleOfTheBirds.BattleOfTheBirds_CaveRift_Basement",
    "Time Rift - The Owl Express":  "hatintime_chapterinfo.BattleOfTheBirds.BattleOfTheBirds_WaterRift_Panels",
    "Time Rift - The Moon":         "hatintime_chapterinfo.BattleOfTheBirds.BattleOfTheBirds_WaterRift_Parade",

    "Contractual Obligations":      "hatintime_chapterinfo.subconforest.SubconForest_IceWall",
    "The Subcon Well":              "hatintime_chapterinfo.subconforest.SubconForest_Cave",
    "Toilet of Doom":               "hatintime_chapterinfo.subconforest.SubconForest_Toilet",
    "Queen Vanessa's Manor":        "hatintime_chapterinfo.subconforest.SubconForest_Manor",
    "Mail Delivery Service":        "hatintime_chapterinfo.subconforest.SubconForest_MailDelivery",
    "Your Contract has Expired":    "hatintime_chapterinfo.subconforest.SubconForest_SnatcherBoss",
    "Time Rift - Sleepy Subcon":    "hatintime_chapterinfo.subconforest.SubconForest_CaveRift_Raccoon",
    "Time Rift - Pipe":             "hatintime_chapterinfo.subconforest.SubconForest_WaterRift_Hookshot",
    "Time Rift - Village":          "hatintime_chapterinfo.subconforest.SubconForest_WaterRift_Dwellers",

    "Alpine Free Roam":                 "hatintime_chapterinfo.AlpineSkyline.AlpineSkyline_IntroMountain",
    "The Illness has Spread":           "hatintime_chapterinfo.AlpineSkyline.AlpineSkyline_Finale",
    "Time Rift - Alpine Skyline":       "hatintime_chapterinfo.AlpineSkyline.AlpineSkyline_CaveRift_Alpine",
    "Time Rift - The Twilight Bell":    "hatintime_chapterinfo.AlpineSkyline.AlpineSkyline_WaterRift_Goats",
    "Time Rift - Curly Tail Trail":     "hatintime_chapterinfo.AlpineSkyline.AlpineSkyline_WaterRift_Cats",

    "The Finale":                       "hatintime_chapterinfo.TheFinale.TheFinale_FinalBoss"
}

# The first three acts of a chapter in act rando can't be any of these
first_chapter_blacklist = [
    "Cheating the Race",

    "Train Rush",
    "Dead Bird Studio Basement",

    "The Subcon Well",
    "Toilet of Doom",
    "Mail Delivery Service",
    "Time Rift - Pipe",
    "Time Rift - Village",

    "Alpine Free Roam",
    "The Illness has Spread",
    "Time Rift - The Twilight Bell",
    "Time Rift - Curly Tail Trail",

    "Time Rift - Gallery",
]

# One of the first three acts of a chapter in act rando must be one of these
first_chapter_guaranteed_acts = [
    "Welcome to Mafia Town",
    "Barrel Battle",
    "She Came from Outer Space",
    "Down with the Mafia!",
    "The Golden Vault",

    "Contractual Obligations",
]

# Acts blacklisted in act shuffle
# entrance: region
blacklisted_acts = {
    "Battle of the Birds - Finale A": "Award Ceremony",
}

# region: list[Region]
rift_access_regions = {
    "Time Rift - Sewers":         ["Welcome to Mafia Town", "Barrel Battle", "She Came from Outer Space",
                                   "Down with the Mafia!", "Cheating the Race", "Heating Up Mafia Town",
                                   "The Golden Vault"],

    "Time Rift - Bazaar":         ["Welcome to Mafia Town", "Barrel Battle", "She Came from Outer Space",
                                   "Down with the Mafia!", "Cheating the Race", "Heating Up Mafia Town",
                                   "The Golden Vault"],

    "Time Rift - Mafia of Cooks": ["Welcome to Mafia Town", "Barrel Battle", "She Came from Outer Space",
                                   "Down with the Mafia!", "Cheating the Race", "The Golden Vault"],

    "Time Rift - The Owl Express":      ["Murder on the Owl Express"],
    "Time Rift - The Moon":             ["Picture Perfect", "The Big Parade"],
    "Time Rift - Dead Bird Studio":     ["Dead Bird Studio"],

    "Time Rift - Pipe":          ["Contractual Obligations", "The Subcon Well",
                                  "Toilet of Doom", "Queen Vanessa's Manor",
                                  "Mail Delivery Service"],

    "Time Rift - Village":       ["Contractual Obligations", "The Subcon Well",
                                  "Toilet of Doom", "Queen Vanessa's Manor",
                                  "Mail Delivery Service"],

    "Time Rift - Sleepy Subcon": ["Contractual Obligations", "The Subcon Well",
                                  "Toilet of Doom", "Queen Vanessa's Manor",
                                  "Mail Delivery Service"],

    "Time Rift - The Twilight Bell": ["Alpine Free Roam"],
    "Time Rift - Curly Tail Trail":  ["Alpine Free Roam"],
    "Time Rift - Alpine Skyline":    ["Alpine Free Roam"],
}


def create_regions(world: World):
    w = world
    mw = world.multiworld

    menu = create_region(w, "Menu")
    spaceship = create_region_and_connect(w, "Spaceship", "-> Spaceship", menu)
    create_region_and_connect(w, "Time Rift - Gallery", "Spaceship - Time Rift A", spaceship)
    create_region_and_connect(w, "Time Rift - The Lab", "Spaceship - Time Rift B", spaceship)
    create_region_and_connect(w, "Time's End", "-> Time's End", spaceship)

    mafia_town = create_region_and_connect(w, "Mafia Town", "-> Mafia Town", spaceship)
    mt_act1 = create_region_and_connect(w, "Welcome to Mafia Town", "Mafia Town - Act 1", mafia_town)
    mt_act2 = create_region_and_connect(w, "Barrel Battle", "Mafia Town - Act 2", mafia_town)
    mt_act3 = create_region_and_connect(w, "She Came from Outer Space", "Mafia Town - Act 3", mafia_town)
    mt_act4 = create_region_and_connect(w, "Down with the Mafia!", "Mafia Town - Act 4", mafia_town)
    mt_act6 = create_region_and_connect(w, "Heating Up Mafia Town", "Mafia Town - Act 6", mafia_town)
    mt_act5 = create_region_and_connect(w, "Cheating the Race", "Mafia Town - Act 5", mafia_town)
    mt_act7 = create_region_and_connect(w, "The Golden Vault", "Mafia Town - Act 7", mafia_town)

    botb = create_region_and_connect(w, "Battle of the Birds", "-> Battle of the Birds", spaceship)
    create_region_and_connect(w, "Dead Bird Studio", "Battle of the Birds - Act 1", botb)
    create_region_and_connect(w, "Murder on the Owl Express", "Battle of the Birds - Act 2", botb)
    create_region_and_connect(w, "Picture Perfect", "Battle of the Birds - Act 3", botb)
    create_region_and_connect(w, "Train Rush", "Battle of the Birds - Act 4", botb)
    create_region_and_connect(w, "The Big Parade", "Battle of the Birds - Act 5", botb)
    create_region_and_connect(w, "Award Ceremony", "Battle of the Birds - Finale A", botb)
    create_region_and_connect(w, "Dead Bird Studio Basement", "Battle of the Birds - Finale B", botb)
    create_rift_connections(w, create_region(w, "Time Rift - Dead Bird Studio"))
    create_rift_connections(w, create_region(w, "Time Rift - The Owl Express"))
    create_rift_connections(w, create_region(w, "Time Rift - The Moon"))

    subcon_forest = create_region_and_connect(w, "Subcon Forest", "-> Subcon Forest", spaceship)
    sf_act1 = create_region_and_connect(w, "Contractual Obligations", "Subcon Forest - Act 1", subcon_forest)
    sf_act2 = create_region_and_connect(w, "The Subcon Well", "Subcon Forest - Act 2", subcon_forest)
    sf_act3 = create_region_and_connect(w, "Toilet of Doom", "Subcon Forest - Act 3", subcon_forest)
    sf_act4 = create_region_and_connect(w, "Queen Vanessa's Manor", "Subcon Forest - Act 4", subcon_forest)
    sf_act5 = create_region_and_connect(w, "Mail Delivery Service", "Subcon Forest - Act 5", subcon_forest)
    create_region_and_connect(w, "Your Contract has Expired", "Subcon Forest - Finale", subcon_forest)

    # Alpine is all considered one act, besides finale/rifts
    alpine_skyline = create_region_and_connect(w, "Alpine Skyline",  "-> Alpine Skyline", spaceship)
    alpine_freeroam = create_region_and_connect(w, "Alpine Free Roam", "Alpine Skyline - Free Roam", alpine_skyline)

    # Needs to be a separate region because it can be accessed from both free roam and Illness, Illness w/o hookshot
    goat_village = create_region_and_connect(w, "Goat Village", "Alpine Free Roam -> Goat Village", alpine_freeroam)

    create_region_and_connect(w, "The Birdhouse", "-> The Birdhouse", alpine_freeroam)
    create_region_and_connect(w, "The Lava Cake", "-> The Lava Cake", alpine_freeroam)
    create_region_and_connect(w, "The Windmill", "-> The Windmill", alpine_freeroam)
    create_region_and_connect(w, "The Twilight Bell", "-> The Twilight Bell", alpine_freeroam)

    illness = create_region_and_connect(w, "The Illness has Spread", "Alpine Skyline - Finale", alpine_skyline)
    connect_regions(illness, goat_village, "The Illness has Spread -> Goat Village", w.player)
    create_rift_connections(w, create_region(w, "Time Rift - Alpine Skyline"))
    create_rift_connections(w, create_region(w, "Time Rift - The Twilight Bell"))
    create_rift_connections(w, create_region(w, "Time Rift - Curly Tail Trail"))

    # force recache
    world.multiworld.get_region("Alpine Free Roam", w.player)

    mt_area: Region = create_region(w, "Mafia Town Area")
    connect_regions(mt_act1, mt_area, "Mafia Town Entrance WTMT", w.player)
    connect_regions(mt_act2, mt_area, "Mafia Town Entrance BB", w.player)
    connect_regions(mt_act3, mt_area, "Mafia Town Entrance SCFOS", w.player)
    connect_regions(mt_act4, mt_area, "Mafia Town Entrance DWTM", w.player)
    connect_regions(mt_act5, mt_area, "Mafia Town Entrance CTR", w.player)
    connect_regions(mt_act7, mt_area, "Mafia Town Entrance TGV", w.player)

    create_rift_connections(w, create_region(w, "Time Rift - Mafia of Cooks"))
    create_rift_connections(w, create_region(w, "Time Rift - Sewers"))
    create_rift_connections(w, create_region(w, "Time Rift - Bazaar"))

    sf_area: Region = create_region(w, "Subcon Forest Area")
    connect_regions(sf_act1, sf_area, "Subcon Forest Entrance CO", w.player)
    connect_regions(sf_act2, sf_area, "Subcon Forest Entrance SW", w.player)
    connect_regions(sf_act3, sf_area, "Subcon Forest Entrance TOD", w.player)
    connect_regions(sf_act4, sf_area, "Subcon Forest Entrance QVM", w.player)
    connect_regions(sf_act5, sf_area, "Subcon Forest Entrance MDS", w.player)

    create_rift_connections(w, create_region(w, "Time Rift - Sleepy Subcon"))
    create_rift_connections(w, create_region(w, "Time Rift - Pipe"))
    create_rift_connections(w, create_region(w, "Time Rift - Village"))

    badge_seller = create_region(w, "Badge Seller")
    connect_regions(mt_area, badge_seller, "Mafia Town Area -> Badge Seller", w.player)
    connect_regions(mt_act6, badge_seller, "Heating Up Mafia Town -> Badge Seller", w.player)
    connect_regions(sf_area, badge_seller, "Subcon Forest Area -> Badge Seller", w.player)

    connect_regions(mw.get_region("Dead Bird Studio", w.player), badge_seller,
                    "Dead Bird Studio -> Badge Seller", w.player)

    connect_regions(mw.get_region("Picture Perfect", w.player), badge_seller,
                    "Picture Perfect -> Badge Seller", w.player)

    connect_regions(mw.get_region("Train Rush", w.player), badge_seller,
                    "Train Rush -> Badge Seller", w.player)

    connect_regions(mw.get_region("Alpine Free Roam", w.player), badge_seller,
                    "Alpine Free Roam -> Badge Seller", w.player)

    # force recache
    mw.get_region("Time Rift - Sewers", w.player)


def create_rift_connections(world: World, region: Region):
    i = 1
    for name in rift_access_regions[region.name]:
        act_region = world.multiworld.get_region(name, world.player)
        entrance_name = "{name} Portal - Entrance {num}"
        connect_regions(act_region, region, entrance_name.format(name=region.name, num=i), world.player)
        i += 1


def randomize_act_entrances(world: World):
    entrance_list: typing.List[Entrance] = get_act_entrances(world)
    region_list: typing.List[Region] = get_act_regions(world)
    world.multiworld.random.shuffle(entrance_list)
    world.multiworld.random.shuffle(region_list)

    # Guarantee that first three accessible acts are completable and that one of them is a location-dense area
    act_whitelist: typing.List[Region] = []
    for region in region_list.copy():
        if region.name not in first_chapter_blacklist:
            act_whitelist.append(region)

    has_guaranteed_act: bool = False
    count: int = 0
    first_chapter_entrances: typing.List[Entrance] = get_first_chapter_region(world).exits.copy()
    world.multiworld.random.shuffle(first_chapter_entrances)
    world.multiworld.random.shuffle(act_whitelist)

    for entrance in first_chapter_entrances:
        if "Act 1" not in entrance.name \
         and "Act 2" not in entrance.name \
         and "Act 3" not in entrance.name:
            continue

        if entrance.name in blacklisted_acts.keys():
            continue

        region: Region = act_whitelist[world.multiworld.random.randint(0, len(act_whitelist)-1)]
        if not has_guaranteed_act:
            if count >= 2 or world.multiworld.random.randint(0, 3) == 1:
                region = world.multiworld.get_region(
                    first_chapter_guaranteed_acts
                    [world.multiworld.random.randint(0, len(first_chapter_guaranteed_acts)-1)], world.player)
                has_guaranteed_act = True
            elif region.name in first_chapter_guaranteed_acts:
                has_guaranteed_act = True

        world.update_chapter_act_info(entrance.connected_region, region)
        reconnect_regions(entrance, entrance.parent_region, region)
        entrance_list.remove(entrance)
        region_list.remove(region)
        act_whitelist.remove(region)
        count += 1
        if count >= 3:
            break

    # Gather Time Rifts but separate the Alpine ones, so we don't accidentally make Alpine Free Roam inaccessible
    time_rifts: typing.List[Region] = []
    alpine_time_rifts: typing.List[Region] = []
    for region in world.multiworld.get_regions(world.player):
        if "Time Rift" in region.name and region.name in rift_access_regions.keys():
            if region.name == "Time Rift - Curly Tail Trail" or region.name == "Time Rift - The Twilight Bell" \
             or region.name == "Time Rift - Alpine Skyline":
                alpine_time_rifts.append(region)
            else:
                time_rifts.append(region)

    rift_dict: typing.Dict[str, Region] = {}
    block_attempts: int = 0
    chapter_rift_blocks: typing.Dict[ChapterIndex, typing.List[ChapterIndex]] = {ChapterIndex.MAFIA: [],
                                                                                 ChapterIndex.BIRDS: [],
                                                                                 ChapterIndex.SUBCON: [],
                                                                                 ChapterIndex.ALPINE: []}

    # First, map Alpine Free Roam to something other than its own Time Rift
    alpine = world.multiworld.get_region("Alpine Free Roam", world.player)
    e = entrance_list[world.multiworld.random.randint(0, len(entrance_list) - 1)]

    # Obviously don't map it to the finale, that's impossible
    while e.name == "Alpine Skyline - Finale":
        e = entrance_list[world.multiworld.random.randint(0, len(entrance_list) - 1)]

    original_region: Region

    # There are about 40% Time Rifts vs Acts in the game, so 40% chance to be mapped to a Time Rift
    if world.multiworld.random.randint(1, 5) > 2:
        original_region = e.connected_region
        reconnect_regions(e, e.parent_region, alpine)
        world.update_chapter_act_info(original_region, alpine)
    else:
        original_region = time_rifts[world.multiworld.random.randint(0, len(time_rifts) - 1)]
        connect_time_rift(original_region, alpine, e, world)
        world.update_chapter_act_info(original_region, alpine)
        rift_dict.setdefault(original_region.name, alpine)
        time_rifts.remove(original_region)

    alpine_freeroam_chapter = [index for index, name in chapter_regions.items()
                               if name == act_chapters[original_region.name]][0]

    entrance_list.remove(e)
    region_list.remove(alpine)

    while len(entrance_list) > 0 or len(region_list) > 0 or len(time_rifts) > 0:
        entrance = entrance_list[world.multiworld.random.randint(0, len(entrance_list) - 1)]

        # Rifts first
        if len(time_rifts) > 0:
            target_region = region_list[world.multiworld.random.randint(0, len(region_list)-1)]

            # Do Alpine time rifts first
            if len(alpine_time_rifts) > 0:
                rift_region = alpine_time_rifts[world.multiworld.random.randint(0, len(alpine_time_rifts)-1)]
            else:
                rift_region = time_rifts[world.multiworld.random.randint(0, len(time_rifts) - 1)]

            # Make sure the target region and Time Rift do not share the same original chapter
            # Unless the target region is a Time Rift
            if act_chapters[rift_region.name] == act_chapters[target_region.name] \
               and "Time Rift" not in target_region.name:
                continue

            rift_chapter_index = [index for index, name in chapter_regions.items()
                                  if name == act_chapters[rift_region.name]][0]
            target_chapter_index = [index for index, name in chapter_regions.items()
                                    if name == act_chapters[target_region.name]][0]

            # Don't place anything onto an Alpine time rift that originates
            # from the chapter that has Alpine Free Roam.
            if target_chapter_index is not ChapterIndex.SPACESHIP:
                if rift_chapter_index is ChapterIndex.ALPINE and target_chapter_index is alpine_freeroam_chapter:
                    continue

            # If target act is from chapter 1 or 3,
            # we can't have more than one non-rift act from the target act's chapter in a Time Rift
            # in the same chapter.
            if target_chapter_index in chapter_rift_blocks[rift_chapter_index] and block_attempts < 200:
                block_attempts += 1
                continue

            block_attempts = 0

            if rift_chapter_index is not ChapterIndex.SPACESHIP \
               and target_chapter_index is ChapterIndex.MAFIA or target_chapter_index is ChapterIndex.SUBCON:
                chapter_rift_blocks[rift_chapter_index] += [target_chapter_index]

            # Finally, connect the Time Rift
            connect_time_rift(rift_region, target_region, entrance, world)

            # Store in our dict (see set_rift_indirect_connections)
            rift_dict.setdefault(rift_region.name, target_region)

            if rift_region in time_rifts:
                time_rifts.remove(rift_region)
            elif rift_region in alpine_time_rifts:
                alpine_time_rifts.remove(rift_region)

            entrance_list.remove(entrance)
            region_list.remove(target_region)
        else:
            original_region = entrance.connected_region
            region = region_list[world.multiworld.random.randint(0, len(region_list) - 1)]
            reconnect_regions(entrance, entrance.parent_region, region)
            world.update_chapter_act_info(original_region, region)

            region_list.remove(region)
            entrance_list.remove(entrance)

    # Add in blacklisted acts with their defaults
    for name in blacklisted_acts.keys():
        blacklisted_region: Region = world.multiworld.get_region(blacklisted_acts[name], world.player)
        world.update_chapter_act_info(blacklisted_region, blacklisted_region)

    set_rift_rules(world, rift_dict)


def connect_time_rift(rift_region: Region, target_region: Region, entrance: Entrance, world: World):
    # Grab the Time Rift's current entrances
    rift_entrances: typing.List[Entrance] = []
    for e in rift_region.entrances:
        rift_entrances.append(e)

    rift_region.entrances.clear()

    # Connect the entrance to our Time Rift
    world.update_chapter_act_info(entrance.connected_region, rift_region)
    reconnect_regions(entrance, entrance.parent_region, rift_region)

    # Connect the Time Rift's old entrances to our target region
    for e in rift_entrances:
        reconnect_regions(e, e.parent_region, target_region)

    # Update ChapterActInfo data
    world.update_chapter_act_info(rift_region, target_region)


def get_act_entrances(world: World, exclude_blacklisted: bool = True) -> typing.List[Entrance]:
    entrance_list: typing.List[Entrance] = []
    for region in world.multiworld.get_regions(world.player):
        if region.name in act_entrances.values():
            for entrance in region.entrances:
                if entrance.name in act_entrances.keys():
                    if exclude_blacklisted is False or entrance.name not in blacklisted_acts.keys():
                        entrance_list.append(entrance)

    return entrance_list


def get_act_regions(world: World, exclude_blacklisted: bool = True) -> typing.List[Region]:
    act_list: typing.List[Region] = []
    for region in world.multiworld.get_regions(world.player):
        if region.name in act_entrances.values():
            if exclude_blacklisted is False or region.name not in blacklisted_acts.values():
                act_list.append(region)

    return act_list


def create_region(world: World, name: str) -> Region:
    reg = Region(name, world.player, world.multiworld)

    for (key, data) in location_table.items():
        if data.region == name:
            if key in storybook_pages.keys() \
               and world.multiworld.ShuffleStorybookPages[world.player].value == 0:
                continue

            location = HatInTimeLocation(world.player, key, data.id, reg)
            reg.locations.append(location)

    world.multiworld.regions.append(reg)
    return reg


def connect_regions(start_region: Region, exit_region: Region, entrancename: str, player: int):
    entrance = Entrance(player, entrancename, start_region)
    start_region.exits.append(entrance)
    entrance.connect(exit_region)


# Takes an entrance, removes its old connections, and reconnects it between the two regions specified.
def reconnect_regions(entrance: Entrance, start_region: Region, exit_region: Region):
    if entrance in entrance.connected_region.entrances:
        entrance.connected_region.entrances.remove(entrance)

    if entrance in entrance.parent_region.exits:
        entrance.parent_region.exits.remove(entrance)

    if entrance in start_region.exits:
        start_region.exits.remove(entrance)

    if entrance in exit_region.entrances:
        exit_region.entrances.remove(entrance)

    entrance.parent_region = start_region
    start_region.exits.append(entrance)
    entrance.connect(exit_region)


def create_region_and_connect(world: World,
                              name: str, entrancename: str, connected_region: Region, is_exit: bool = True) -> Region:

    reg: Region = create_region(world, name)
    entrance_region: Region
    exit_region: Region

    if is_exit:
        entrance_region = connected_region
        exit_region = reg
    else:
        entrance_region = reg
        exit_region = connected_region

    connect_regions(entrance_region, exit_region, entrancename, world.player)
    return reg


def get_first_chapter_region(world: World) -> Region:
    start_chapter: ChapterIndex = world.multiworld.StartingChapter[world.player]
    return world.multiworld.get_region(chapter_regions.get(start_chapter), world.player)


def get_act_original_chapter(world: World, act_name: str) -> Region:
    return world.multiworld.get_region(act_chapters[act_name], world.player)


def create_events(world: World) -> int:
    w = world
    mw = w.multiworld
    count: int = 0

    for (name, data) in event_locs.items():
        event: Location = create_event(name, mw.get_region(data.region, w.player), w)
        act_completion: str = format("Act Completion (%s)" % data.region)
        event.access_rule = mw.get_location(act_completion, w.player).access_rule
        count += 1

    return count


def create_event(name: str, region: Region, world: World) -> Location:
    event = HatInTimeLocation(world.player, name, None, region)
    region.locations.append(event)
    event.place_locked_item(HatInTimeItem(name, ItemClassification.progression, None, world.player))
    return event
