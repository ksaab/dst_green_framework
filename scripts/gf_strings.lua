--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

local STRINGS = GLOBAL.STRINGS

--Strings for original game things
STRINGS.ACTIONS.GFTALKFORQUEST = "Quest"
STRINGS.ACTIONS.GFCASTSPELL = "Cast"
STRINGS.ACTIONS.GFSTARTSPELLTARGETING = "Target"
STRINGS.ACTIONS.GFSTOPSPELLTARGETING = "Cancel"
STRINGS.ACTIONS.GFCHANGEITEMSPELL = "Change Spell"
STRINGS.ACTIONS.GFDRINKIT = "Drink"
STRINGS.ACTIONS.GFENHANCEITEM = "Enhance Item"
STRINGS.ACTIONS._GFCASTSPELL =
{
    GENERIC = "Cast",
    JUMP = "Jump",
    THROW = "Throw",
    LUNGE = "Lunge",
    SHOOT = "Shoot",
}

STRINGS.CHARACTERS.GENERIC.ACTIONFAIL.GFTALKFORQUEST = 
{
    NOQUESTS = "There is nothing intresting for me here.",
    TARGETBUSY = "It's not the best time.",
    TOMANYQUESTS = "My quest jouranl is full!",
}

STRINGS.CHARACTERS.GENERIC.ACTIONFAIL.GFCASTSPELL =
{
    GENERIC = "Nothing will come of it.",
    NOAMMO = "I need more ammo!",
    NOITEM = "I need more required items!",
    NOWEAPON = "I need a weapon!",
    HEALTH_FAIL = "I  need more resources",
    SANITY_FAIL = "I  need more resources",
    HUNGER_FAIL = "I  need more resources",
}

--Green! specified strings
STRINGS.GF = {}

STRINGS.GF.HUD = 
{
    QUEST_BUTTONS = 
    {
        ACCEPT = "Accept",
        DECLINE = "Decline",
        COMPLETE = "Complete",
    },
    JOURNAL =
    {
        BUTTONS = 
        {
            CLOSE = "Close",
            CANCEL = "Cancel",
            OPEN_JOURNAL = "Open Journal",
        },
        TITLE = "Journal",
        NOQUESTS = "Journal is empty",
    },
    CONTROLLER_DEFAULTS = 
    {
        LMB = "Cast",
        RMB = "Cancel",
    },
    INVALID_LINES = 
    {
        INVALID_TITLE = "<NO TITLE>",
        INVALID_TEXT = "<NO TEXT>",
    },
    MINUTES_LETTER = "m",
}

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