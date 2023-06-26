from enum import IntEnum, IntFlag


class HatType(IntEnum):
    NONE = -1
    SPRINT = 0
    BREWING = 1
    ICE = 2
    DWELLER = 3
    TIME_STOP = 4


class RelicType(IntEnum):
    BURGER = 0
    TRAIN = 1
    UFO = 2
    CRAYON = 3
    CAKE = 4
    NECKLACE = 5


class HatDLC(IntFlag):
    none = 0b000
    dlc1 = 0b001
    dlc2 = 0b010
    death_wish = 0b100


class ChapterIndex(IntEnum):
    SPACESHIP = 0
    MAFIA = 1
    BIRDS = 2
    SUBCON = 3
    ALPINE = 4
    FINALE = 5
    CRUISE = 6
    METRO = 7
