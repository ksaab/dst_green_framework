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

rawset(_G, "GFDev", true)

PrefabFiles = 
{
    "gf_lightningfx",
    "gf_cracklefx",
    "gf_dummies",
    "gf_reticules",
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

if not rawget(_G, "GFEntitiesBaseSpells") then
    rawset(_G, "GFEntitiesBaseSpells", {})
end

if not rawget(GLOBAL, "GFEntitiesBaseAffixes") then
    rawset(_G, "GFEntitiesBaseAffixes", {})
end

if not rawget(_G, "GFCasterCreatures") then
    rawset(_G, "GFCasterCreatures", {})
end

if not rawget(_G, "GFQuestGivers") then
    rawset(_G, "GFQuestGivers", {})
end

require "gf_global_functions"

modimport "scripts/gf_tuning.lua"
modimport "scripts/gf_strings.lua"
modimport "scripts/gf_net_stream.lua"
modimport "scripts/gf_spell_list.lua"
modimport "scripts/gf_effect_list.lua"
modimport "scripts/gf_affix_list.lua"
modimport "scripts/gf_quests_list.lua"
modimport "scripts/gf_actions.lua"
modimport "scripts/gf_player_states_server.lua"
modimport "scripts/gf_player_states_client.lua"
modimport "scripts/gf_creatures_states.lua"
modimport "scripts/gf_creatures_brains.lua"
modimport "scripts/gf_widgets.lua"
modimport "scripts/gf_init_controls.lua"
modimport "scripts/gf_init_components.lua"
modimport "scripts/gf_init_prefabs.lua"

local GFAddCasterCreature = _G.GFAddCasterCreature

local function PigmanFrindlyFireCheck(self, target)
    return self.inst.components.combat.target ~= target
        and ((target:HasTag("pig") and not target:HasTag("werepig")) 
            or (self.inst.components.follower and self.inst.components.follower.leader == target))
end

local function BunnymanFrindlyFireCheck(self, target)
    return self.inst.components.combat.target ~= target
        and (target:HasTag("manrabbit")
            or (self.inst.components.follower and self.inst.components.follower.leader == target))
end

local function ChessFrindlyFireCheck(self, target)
    return self.inst.components.combat.target ~= target
        and (target:HasTag("chess")
            or (self.inst.components.follower and self.inst.components.follower.leader == target))
end

GFAddCasterCreature("pigman", PigmanFrindlyFireCheck)
GFAddCasterCreature("bunnyman", PigmanFrindlyFireCheck)
GFAddCasterCreature("knight", ChessFrindlyFireCheck)

AddModRPCHandler("GreenFramework", "GFPLAYEISRREADY", function(inst)
    inst:PushEvent("gfplayerisready")
end)

AddModRPCHandler("GreenFramework", "GFDISABLEPOINTER", function(inst)
    if inst.components.gfspellpointer then
        inst.components.gfspellpointer:Disable()
    end
end)

AddModRPCHandler("GreenFramework", "GFCLICKSPELLBUTTON", function(inst, spellName)
    if inst.components.gfspellcaster and spellName and type(spellName) == "string"then
        inst.components.gfspellcaster:HandleIconClick(spellName)
    end
end)

AddModRPCHandler("GreenFramework", "GFOFFERQUESTRESULT", function(inst, check, qName)
    if check and qName and type(qName) == "string" then
        --print("SERVER: Quest accepted", qName, "by", inst)
        inst.components.gfquestdoer:AcceptQuest(qName)
    else
        --print("SERVER: Quest declined", qName, "by", inst)
        inst.components.gfquestdoer:StopTrackGiver()
    end
end)

AddModRPCHandler("GreenFramework", "GFCANCELQUEST", function(inst, qName)
    if qName ~= nil and type(qName) == "string" then
        inst.components.gfquestdoer:CancelQuest(qName)
    end
end)