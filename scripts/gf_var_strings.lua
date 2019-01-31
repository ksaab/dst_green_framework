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

STRINGS.CHARACTERS.GENERIC.ACTIONFAIL.GFLETSTALK = 
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
        QUEST_STARTED = "Quest strated!",
        QUEST_ABANDONED = "Quest abandoned.",
        QUEST_COMPLETED = "Quest completed!",
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

STRINGS.GF.CONVERSATIONS = 
{
    --defaults
    DEFAULT = 
    {
        TITLE = "Conversation",
        TEXT = "Hello, do you want to talk with me?",
    },
    PIGMAN_DEFAULT = 
    {
        TITLE = "Pigman",
        TEXT = "Oink! Oink-oink!",
    },
    BUNNYMAN_DEFAULT = 
    {
        TITLE = "Bunny",
        TEXT = "Hey! Avoid any meat!",
    },
    PIGKING_DEFAULT = 
    {
        TITLE = "Pig King",
        TEXT = "Hello, little creature. What do you want?",
    },
    LIVINGTREE_DEFAULT = 
    {
        TITLE = "Living tree",
        TEXT = "*You hear the voice of the tree in your head*",
    },
}

STRINGS.GF.QUESTS = 
{
    DEFAULT_REMINDER = "I think I've promised to help here.",
    KILL_FIVE_SPIDERS = 
    {
        TITLE = "Pesky spiders",
        DESC = "This spiders annoy me. &name, please, take them away from here.",
        COMPLETION = "Thanks, &name. Take this. Don't ask where I stored it.",
        GOAL = "Kill five spiders",
        STATUS = "Spiders killed: %s/%s",
    },
    KILL_ONE_TENTACLE = 
    {
        TITLE = "Horrible Thing",
        DESC = "Tentacles are dangerous. Kill one and make this world a bit safer.",
        COMPLETION = "Thanks, &name. Take this.",
        GOAL = "Kill a purple tentacle",
        STATUS = "Tentacle killed",
    },
    COLLECT_TEN_ROCKS = 
    {
        TITLE = "Stone Home",
        DESC = "I need rocks, don't aks why, just bring them.",
        COMPLETION = "Thanks, &name. Take this.",
        GOAL = "Find 10 rocks",
        STATUS = "Rocks collected %s/%s.",
    },

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