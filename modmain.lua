--Green Framework.
--This mod was designed as platform for expanding "the magic part" of the game
--What does it mean:
--  1) Players need to subcribe to this mod if you want to use features like status effects, spells and other things in your mod;
--  2) You shouldn't copy any parts of this mod, because it can break other mods based on the GF;
--  3) Do not forget to add the information about mod requirements to the desription;
--  4) You can use 'rawget(_G, "GFVersion")' to detect the current GF version (it returns nil if GF isn't enabled)

local _G = GLOBAL
local require = _G.require
local rawget = _G.rawget
local rawset = _G.rawset
local ACTIONS = _G.ACTIONS
local BufferedAction = _G.BufferedAction

PrefabFiles = 
{
    "gf_lightningfx",
    "gf_cracklefx",
    "gf_dummies",
    "gf_reticules",
    "gf_quest_mark",
}

Assets = 
{
    Asset("IMAGE", "images/gfdefaulticons.tex"),
    Asset("ATLAS", "images/gfdefaulticons.xml"),
    Asset("IMAGE", "images/gfspellhud.tex"),
    Asset("ATLAS", "images/gfspellhud.xml"),
    Asset("IMAGE", "images/gfquestjournal.tex"),
    Asset("ATLAS", "images/gfquestjournal.xml"),

    Asset("ANIM", "anim/gf_player_fast_cast.zip"),
    Asset("ANIM", "anim/gf_player_read_scroll.zip"),

    Asset("ANIM", "anim/swap_gf_bottle.zip"),
    Asset("ANIM", "anim/swap_gw_scroll.zip"),
}

local GF = require "gf_init_globals"
require "memspikefix"

modimport "scripts/gf_var_tuning.lua"
modimport "scripts/gf_var_strings.lua"
--network
modimport "scripts/gf_net_stream.lua"
modimport "scripts/gf_net_modrpc.lua"
--init in game parametres
modimport "scripts/gf_init_controls.lua"
modimport "scripts/gf_init_components.lua"
modimport "scripts/gf_init_prefabs.lua"
modimport "scripts/gf_init_actions.lua"
modimport "scripts/gf_init_widgets.lua"
--init player
modimport "scripts/gf_player_states_server.lua"
modimport "scripts/gf_player_states_client.lua"
--init creatures
modimport "scripts/gf_creatures_states.lua"
modimport "scripts/gf_creatures_brains.lua"

GF.InitStatusEffect("damage_boost")
GF.InitStatusEffect("movement_boost")
GF.InitDialogueNode("default_node")
--GF.InitQuest("kill_five_spiders")
--GF.InitQuest("kill_one_tentacle")
--GF.InitQuest("_collect_items")