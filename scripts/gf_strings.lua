--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

local STRINGS = GLOBAL.STRINGS

STRINGS.GF = {}

STRINGS.GF.DEFAULTACTIONACTION = "Cast"
STRINGS.GF.DEFAULTALTACTIONACTION = "Cancel"

STRINGS.GF.INVALID_TITLE = "<NONE>"
STRINGS.GF.MINUTES_LETTER = "m"

STRINGS.GF.QSTRINGS = 
{
    INVALID_TITLE = "<NO TITLE>",
    INVALID_TEXT = "<NO TEXT>",
    BUTTON_ACCEPT = "Accept",
    BUTTON_DECLINE = "Decline",
    BUTTON_COMPLETE = "Complete",
}

STRINGS.GFTALKFORQUEST = 
{
    STR = "Quest",
    NOQUESTS = "There is nothing intresting for me here.",
    TARGETBUSY = "It's not the best time.",
}

STRINGS.ACTIONS._GFCASTSPELL =
{
    GENERIC = "Cast",
    JUMP = "Jump",
    THROW = "Throw",
    LUNGE = "Lunge",
    SHOOT = "Shoot",
}
STRINGS.ACTIONS.GFCASTSPELL = "Cast"
STRINGS.ACTIONS.GFSTARTSPELLTARGETING = "Target"
STRINGS.ACTIONS.GFSTOPSPELLTARGETING = "Cancel"
STRINGS.ACTIONS.GFCHANGEITEMSPELL = "Change Spell"
STRINGS.ACTIONS.GFDRINKIT = "Drink"
STRINGS.ACTIONS.GFENHANCEITEM = "Enhance Item"

STRINGS.GF.EFFECTS = {}

STRINGS.GF.SPELLS = {
    CRUSH_LIGHTNING = 
    {
        TITLE = "Crushing Lightning",
    },
    CHAIN_LIGHTNING = 
    {
        TITLE = "Chain Lightning",
    },
    GROUND_SLAM = 
    {
        TITLE = "Ground Slam",
    },
    SHOOT = 
    {
        TITLE = "Shoot"
    },
}

STRINGS.CHARACTERS.GENERIC.CAST_FAILED = 
{
    GENERIC = "Nothing happens.",
}

STRINGS.CHARACTERS.GENERIC.PRECAST_FAILED = 
{
    GENERIC = "Nothing will come of it.",
    NOAMMO = "I need more ammo!",
    NOITEM = "I need more required items!",
    NOWEAPON = "I need a weapon!",
    HEALTH_FAIL = "I  need more resources",
    SANITY_FAIL = "I  need more resources",
    HUNGER_FAIL = "I  need more resources",
}