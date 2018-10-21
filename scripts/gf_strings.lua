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

STRINGS.CHARACTERS.GENERIC.ACTIONFAIL.GFDRINKIT = 
{
    GENERIC = "I won't drink this!",
}

STRINGS.CHARACTERS.GENERIC.ACTIONFAIL.GFTALKFORQUEST = 
{
    NOQUESTS = "There is nothing intresting for me here.",
    TARGETBUSY = "It's not the best time.",
    TOMANYQUESTS = "My quest jouranl is full!",
    REMINDQUEST = "I thing I've promise to help here.",
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
    QUEST_INFORMER = 
    {
        QUEST_STARTED = "Quest strated.",
        QUEST_ABANDONED = "Quest abandoned.",
        QUEST_DONE = "done!",
        QUEST_UNDONE = "conditions are no longer met.",
        QUEST_FAILED = "failed!",
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
    ERROR = "<ERROR>",
    MINUTES_LETTER = "m",
}

STRINGS.GF.QUESTS = 
{
    _EX_KILL_FIVE_SPIDERS = 
    {
        TITLE = "Pesky spiders.",
        DESC = "This spiders annoy me. &name, please, take them away from here.",
        COMPLETION = "Thanks, &name. Take this. Don't ask where I stored it.",
        GOAL = "Kill five spiders",
        STATUS = "Spiders killed: %s/%s",
    },
    _EX_BRING_FIVE_LOGS = 
    {
        TITLE = "Pig need home",
        DESC = "Cold nights. I need home. You bring trees.",
        COMPLETION = "Love home. You good.",
        GOAL = "Bring five logs",
        STATUS = "Logs: %s/%s",
    },
}

STRINGS.GF.QUEST_DIALOGS = 
{
    GF_DIALOG_TEST = "It's a test dialog",
    DEFAULT = "Hello, can you help me?",
    PIGMAN_DEFAULT = "Oink. Oink-oink! Oink. Oink-oink! Oink. Oink-oink! Oink. Oink-oink! Oink. Oink-oink! Oink. Oink-oink! Oink. Oink-oink! Oink. Oink-oink! Oink. Oink-oink! Oink. Oink-oink! Oink. Oink-oink! Oink. Oink-oink!",
    SKELETON_DEFAULT = "The skeleton looks at you with empty eyes",
}

STRINGS.CHARACTERS.GENERIC.QUEST_REMINDERS = 
{
    DEFAULT_REMINDER = "I think I've promised to help here.",
    _EX_BRING_FIVE_ROCKS = "I've promised to bring some rocks.",
}

STRINGS.CHARACTERS.WOODIE.QUEST_REMINDERS = 
{
    DEFAULT_REMINDER = "Woodie: I think I've promised to help here.",
    _EX_BRING_FIVE_ROCKS = "Woodie: I've promised to bring some rocks.",
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