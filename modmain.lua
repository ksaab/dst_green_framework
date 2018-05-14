local require = GLOBAL.require
local rawget = GLOBAL.rawget
local rawset = GLOBAL.rawset

rawset(GLOBAL, "GFDev", true)

PrefabFiles = 
{
    "gf_lightningfx",
    "gf_cracklefx",
    "gf_dummies",
    --"gf_lightningfx_2",
    "gf_magic_echo_amulet",
}

Assets = 
{
    Asset("IMAGE", "images/gfdefaulticons.tex"),
    Asset("ATLAS", "images/gfdefaulticons.xml"),
}

local gfFunctions = require "gf_global_functions"
if type(gfFunctions) == "table" then
    for k, v in pairs(gfFunctions) do
        if not rawget(GLOBAL, k) then
            rawset(GLOBAL, k, v)
        end
    end
end

modimport "scripts/gf_spell_list.lua"
modimport "scripts/gf_effect_list.lua"
modimport "scripts/gf_actions.lua"
modimport "scripts/gf_player_states_server.lua"
modimport "scripts/gf_player_states_client.lua"
modimport "scripts/gf_creatures_states.lua"
modimport "scripts/gf_creatures_brains.lua"
modimport "scripts/gf_widgets.lua"

AddReplicableComponent("gfspellcaster")
AddReplicableComponent("gfspellitem")
AddReplicableComponent("gfeffectable")

AddPrefabPostInit("world", function(world)
    world:ListenForEvent("playerentered", function(world, player)
        if player == nil or player ~= GLOBAL.ThePlayer then return end
        print("adding gfrechargewatcher")
        player:AddComponent("gfrechargewatcher")
    end)
end)

AddPlayerPostInit(function(player)
    gfFunctions.GFMakePlayerCaster(player)
    if gfFunctions.GFGetIsMasterSim() then
        player:AddComponent("gfeffectable")
        player:AddComponent("gfeventreactor")

        --[[ player._readySpellDouble = 0
        player:ListenForEvent("gfspellcastsuccess", function(player, data)
            if data.spell:HasSpellTag("replicateable") then
                player:DoTaskInTime(2, function(player, data)
                    if player._readySpellDouble < GLOBAL.GetTime() then
                        player.components.gfspellcaster:CastSpell(data.spell.name, data.target, data.pos, nil, true)
                        player._readySpellDouble = GLOBAL.GetTime() + 4
                    end
                end, data)
            end
        end) ]]
        --[[ player.components.gfeventreactor:AddReaction("attacked", 
        {
            event = "attacked", 
            target = "attacker", 
            reactParams = {infoString = "he-he"}, 
            --reactfn = function(self, reactor, initiator) print(("%s attacked by %s"):format(tostring(reactor), tostring(initiator))) end, 
            reactfn = function(self, reactor, initiator) print(("%s attacked by %s, %s"):format(tostring(reactor), tostring(initiator), self.reactParams.infoString)) end, 
        })

        player.components.gfeventreactor:AddReaction("attacks", 
        {
            event = "onhitother", 
            target = "target", 
            reactParams = {infoString = "ho-ho"}, 
            reactfn = function(self, reactor, initiator) print(("%s attacks %s, %s"):format(tostring(reactor), tostring(initiator), self.reactParams.infoString)) end,
        }) ]]
        --[[ if player.prefab == "prefab" then
            local gscs = player.components.gfspellcaster
            gscs.baseRecharge = 0.8
            gscs.baseSpellPower = 2

            gscs.rechargeExternal:SetModifier(player, 0.5, "test") 
            gscs.spellPowerExternal:SetModifier(player, 2, "test") 
        end ]]
    end 
    
    --player.components.gfeffectable:ChangeResist("damage", 1)
end)

AddPrefabPostInit("spear", function(inst)
    --[[ if GLOBAL.TheWorld.ismastersim then
        inst:AddTag("_gfspellcaster")
        inst:AddComponent("gfspellcaster")
        inst.components.gfspellcaster:SetItemSpell("flower")
    end ]]

    gfFunctions.GFMakeInventoryCastingItem(inst, {"equip_chainlightning", "equip_crushlightning"}, "equip_chainlightning" )
    --inst:AddComponent("gfrechargableitem")
end)

AddPrefabPostInit("hammer", function(inst)
    --[[ if GLOBAL.TheWorld.ismastersim then
        inst:AddTag("_gfspellcaster")
        inst:AddComponent("gfspellcaster")
        inst.components.gfspellcaster:SetItemSpell("flower")
    end ]]

    gfFunctions.GFMakeInventoryCastingItem(inst, "equip_groundslam", "equip_groundslam")
    --inst:AddComponent("gfrechargableitem")
end)

AddPrefabPostInit("pigman", function(inst)
    if gfFunctions.GFGetIsMasterSim() then
        inst:AddComponent("gfeffectable")
        inst.components.gfeffectable:ApplyEffect("affix_test")
        --gfFunctions.GFMakeCaster(inst, {"equip_chainlightning"})
    end

    --
    --inst:AddComponent("gfrechargableitem")
end)
