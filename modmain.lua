local require = GLOBAL.require
local rawget = GLOBAL.rawget
local rawset = GLOBAL.rawset
local ACTIONS = GLOBAL.ACTIONS
local BufferedAction = GLOBAL.BufferedAction

rawset(GLOBAL, "GFDev", true)

PrefabFiles = 
{
    "gf_lightningfx",
    "gf_cracklefx",
    "gf_dummies",
    --"gf_lightningfx_2",
    "gf_magic_echo_amulet",
    "gf_lightning_spear",
    "gf_effects_fx",
    "gf_potion_metabolism",
    "gf_reticules",
    "gf_tentacle_staff",
}

Assets = 
{
    Asset("IMAGE", "images/gfdefaulticons.tex"),
    Asset("ATLAS", "images/gfdefaulticons.xml"),
    Asset("IMAGE", "images/gfinventory.tex"),
    Asset("ATLAS", "images/gfinventory.xml"),
    Asset("IMAGE", "images/gfspellhud.tex"),
    Asset("ATLAS", "images/gfspellhud.xml"),
    Asset("IMAGE", "images/gficons.tex"),
    Asset("ATLAS", "images/gficons.xml"),

    Asset("ANIM", "anim/gf_fast_cast.zip")
}

local gfFunctions = require "gf_global_functions"
if type(gfFunctions) == "table" then
    for k, v in pairs(gfFunctions) do
        if not rawget(GLOBAL, k) then
            rawset(GLOBAL, k, v)
        end
    end
end

modimport "scripts/gf_strings.lua"
modimport "scripts/gf_spell_list.lua"
modimport "scripts/gf_effect_list.lua"
modimport "scripts/gf_affix_list.lua"
modimport "scripts/gf_actions.lua"
modimport "scripts/gf_player_states_server.lua"
modimport "scripts/gf_player_states_client.lua"
modimport "scripts/gf_creatures_states.lua"
modimport "scripts/gf_creatures_brains.lua"
modimport "scripts/gf_widgets.lua"
modimport "scripts/gf_init_controls.lua"
modimport "scripts/gf_init_prefabs.lua"
modimport "scripts/gf_init_components.lua"

AddModRPCHandler("Green Framework", "GFDISABLEPOINTER", function(inst)
    if inst.components.gfspellpointer then
        inst.components.gfspellpointer:Disable()
    end
end)

AddModRPCHandler("Green Framework", "GFCLICKSPELLBUTTON", function(inst, spellName)
    if inst.components.gfspellcaster then
        inst.components.gfspellcaster:HandleIconClick(spellName)
    end
end)