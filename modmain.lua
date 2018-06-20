local _G = GLOBAL
local require = _G.require
local rawget = _G.rawget
local rawset = _G.rawset
local ACTIONS = _G.ACTIONS
local BufferedAction = _G.BufferedAction

rawset(_G, "GFDev", true)

PrefabFiles = 
{
    "gf_lightningfx",
    "gf_cracklefx",
    "gf_dummies",
    "gf_reticules",
    "gf_hone",
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

    Asset("ANIM", "anim/gf_player_fast_cast.zip"),
    Asset("ANIM", "anim/gf_player_read_scroll.zip"),
}

if rawget(_G, "GFEntitiesBaseSpells") == nil then
    rawset(_G, "GFEntitiesBaseSpells", {})
end

if rawget(_G, "GFCasterCreatures") == nil then
    rawset(_G, "GFCasterCreatures", {})
end

require "gf_global_functions"

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
modimport "scripts/gf_init_components.lua"
modimport "scripts/gf_init_prefabs.lua"

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

_G.GFAddBaseSpellsToEntity("gf_lightning_spear", "equip_chainlightning", "equip_crushlightning")