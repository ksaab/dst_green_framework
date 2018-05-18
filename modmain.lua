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
    "gf_effects_fx"
}

Assets = 
{
    Asset("ANIM", "anim/gf_lightning_spear.zip"),
    Asset("ANIM", "anim/swap_gf_lightning_spear.zip"),
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

local isPVPEnabled = gfFunctions.GFGetPVPEnabled()

modimport "scripts/gf_strings.lua"
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

AddComponentPostInit("combat", function(self)
    local _oldGetAttacked = self.GetAttacked
    function self:GetAttacked(attacker, damage, weapon, stimuli)
        local notBloked = _oldGetAttacked(self, attacker, damage, weapon, stimuli)
        if notBloked and weapon ~= nil then
            weapon:PushEvent("gfonweaponhit", {attacker = attacker, target = self.inst, damage = damage, stimuli = stimuli})
        end

        return isBloked
    end

    function self:GetAttackedWithMods(target, damage, weapon, damageType)
		if not (target and target.components.combat and damage) then return end

		--local playermultiplier = target ~= nil and target:HasTag("player")
    	--local pvpmultiplier = playermultiplier and self.inst:HasTag("player") and self.pvp_damagemod or 1

		local damage = damage * self:GetDamageMods()

		target.components.combat:GetAttacked(self.inst, damage, weapon, damageType)
	end

	function self:GetDamageMods()
		return self.externaldamagemultipliers:Get()	* (self.damagemultiplier or 1)
	end
end)

AddPrefabPostInit("world", function(world)
    world:ListenForEvent("playerentered", function(world, player)
        if player == nil or player ~= GLOBAL.ThePlayer then return end
        print("adding gfrechargewatcher")
        player:AddComponent("gfrechargewatcher")
        --player:PushEvent("gfsc_updaterechargesdirty")
    end)
end)


local function PlayerFFCheck(self, target)
    return (target:HasTag("player") and not isPVPEnabled)
        or (self.inst.components.leader and self.inst.components.leader:IsFollower(target))
end

AddPlayerPostInit(function(player)
    gfFunctions.GFMakePlayerCaster(player)
    if gfFunctions.GFGetIsMasterSim() then
        player.components.gfspellcaster:SetIsTargetFriendlyFn(PlayerFFCheck)
        player:AddComponent("gfeffectable")
        player:AddComponent("gfeventreactor")

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
        if player.prefab == "winona" then
            local gscs = player.components.gfspellcaster
            gscs.baseRecharge = 0.8
            gscs.baseSpellPower = 2

            gscs.rechargeExternal:SetModifier(player, 0.5, "test") 
            gscs.spellPowerExternal:SetModifier(player, 2, "test") 
        end
    end 
    
    --player.components.gfeffectable:ChangeResist("damage", 1)
end)

AddPrefabPostInit("spear", function(inst)
    if GLOBAL.TheWorld.ismastersim then
        inst:ListenForEvent("gfonweaponhit", function(inst) print(inst, "attacks") end)
    end 

    gfFunctions.GFMakeInventoryCastingItem(inst, {"equip_chainlightning", "equip_crushlightning"})
end)

AddPrefabPostInit("boomerang", function(inst)
    if GLOBAL.TheWorld.ismastersim then
        inst:ListenForEvent("gfonweaponhit", function(inst) print(inst, "attacks") end)
    end 
end)

AddPrefabPostInit("pickaxe", function(inst)
    gfFunctions.GFMakeInventoryCastingItem(inst, {"equip_chainlightning", "equip_crushlightning"})
end)

AddPrefabPostInit("hammer", function(inst)
    gfFunctions.GFMakeInventoryCastingItem(inst, "equip_groundslam")
end)

AddPrefabPostInit("axe", function(inst)
    gfFunctions.GFMakeInventoryCastingItem(inst, {"create_flower", "create_goldnugget"}, "create_flower")
end)

local function PigmanFFCheck(self, target)
    local isFriend = (target:HasTag("pig") and not target:HasTag("werepig"))
        or (target.components.leader and target.components.leader:IsFollower(self.inst))
    
    --print(target, "is a friend", isFriend)
    return isFriend or false
    --[[ return not ((target:HasTag("pig") and not target:HasTag("werepig"))
        or (target.components.leader and target.components.leader:IsFollower(self.inst))) ]]
end

AddPrefabPostInit("pigman", function(inst)
    gfFunctions.GFMakeCaster(inst)
    if gfFunctions.GFGetIsMasterSim() then
        inst:AddComponent("gfeffectable")
        inst.components.gfspellcaster:SetIsTargetFriendlyFn(PigmanFFCheck)
        inst.components.gfeffectable:ApplyEffect("affix_shaman")
    end

    --
    --inst:AddComponent("gfrechargableitem")
end)

--[[ AddPrefabPostInitAny(function(inst) 
	if not (inst:HasTag("FX") 
			or inst:HasTag("DECOR") 
			or inst:HasTag("NOCLICK"))
    then
        if gfFunctions.GFGetIsMasterSim() then
            inst:AddComponent("gfeffectable")
        end
    end
end) ]]