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
    "gf_lightning_spear",
    "gf_effects_fx",
    "gf_potion_metabolism",
    "gf_reticules",
    "gf_tentacle_staff",
}

Assets = 
{
    Asset("ANIM", "anim/gf_lightning_spear.zip"),
    Asset("ANIM", "anim/swap_gf_lightning_spear.zip"),
    Asset("IMAGE", "images/gfdefaulticons.tex"),
    Asset("ATLAS", "images/gfdefaulticons.xml"),
    Asset("IMAGE", "images/gfinventory.tex"),
    Asset("ATLAS", "images/gfinventory.xml"),
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
modimport "scripts/gf_affix_list.lua"
modimport "scripts/gf_actions.lua"
modimport "scripts/gf_player_states_server.lua"
modimport "scripts/gf_player_states_client.lua"
modimport "scripts/gf_creatures_states.lua"
modimport "scripts/gf_creatures_brains.lua"
modimport "scripts/gf_widgets.lua"

AddModRPCHandler("Green Framework", "GFDISABLEPOINTER", function(inst)
    if inst.components.gfspellpointer then
        inst.components.gfspellpointer:Disable()
    end
end)

AddReplicableComponent("gfspellcaster")
AddReplicableComponent("gfspellitem")
AddReplicableComponent("gfeffectable")

AddComponentPostInit("eater", function(self)
    self.canDrink = false
    self.onDrink = nil

	function self:Drink(brew, feeder) 
        if brew.components.gfdrinkable ~= nil then
            brew.components.gfdrinkable:OnDrunk(self.inst)

            if self.onDrink ~= nil then
                self:onDrink(brew)
            end

            self.inst:PushEvent("ondrink", { brew = brew, feeder = feeder })
        else
            return false
        end

		return true
	end
end)

AddComponentPostInit("playeractionpicker", function(self)
    local _oldGetLeftClickActions = self.GetLeftClickActions
    function self:GetLeftClickActions(position, target)
        if self.inst.components.playercontroller.gfSpellPointerEnabled then
            local lmb = self.inst.components.gfspellpointer:CollectLeftActions(position, target)
            return lmb or {}
        end

        return _oldGetLeftClickActions(self, position, target)
    end

    local _oldGetRightClickActions = self.GetRightClickActions
    function self:GetRightClickActions(position, target)
        if self.inst.components.playercontroller.gfSpellPointerEnabled then
            local rmb = self.inst.components.gfspellpointer:CollectRightActions(position, target)
            return rmb or {}
        end

        return _oldGetRightClickActions(self, position, target)
    end
end)

AddComponentPostInit("playercontroller", function(self)
    --variables
    local TheInput = GLOBAL.TheInput
    local ACTIONS = GLOBAL.ACTIONS
    local RPC = GLOBAL.RPC
    local BufferedAction = GLOBAL.BufferedAction
    local SendRPCToServer = GLOBAL.SendRPCToServer
    local CanEntitySeePoint = GLOBAL.CanEntitySeePoint
    self.gfSpellPointerEnabled = false

    --[[both side changes]]
    local _oldGetGroundUseAction = self.GetGroundUseAction
    function self:GetGroundUseAction(position)
        if self.gfSpellPointerEnabled 
            and self:IsEnabled()
            and position ~= nil
            and CanEntitySeePoint(self.inst, position:Get())
        then
            return self.inst.components.gfspellpointer:GetControllerPointActions(position)
        end

        return _oldGetGroundUseAction(self, position)
    end

    --"B" button on xbox controller
    local _oldDoControllerAltActionButton = self.DoControllerAltActionButton
    function self:DoControllerAltActionButton()
        if self.gfSpellPointerEnabled 
            and self:IsEnabled()
            and not self:UsingMouse()
        then
            local position = self.inst.components.gfspellpointer.pointer.targetPosition or Vector3(0, 0, 0)
            local act = self.inst.components.playeractionpicker:SortActionList({ ACTIONS.GFSTOPSPELLTARGETING }, position, nil)[1]
            --local act 
            --for _, action in pairs(self.inst.components.playeractionpicker:SortActionList({ ACTIONS.GFSTOPSPELLTARGETING }, position, nil)) do
                --if act.action == ACTIONS.GFSTOPSPELLTARGETING then
                    --act = action
                    --break
                --end
            --end
            print(position, act)
            if act ~= nil then
                act.preview_cb = function()
                    self.remote_controls[GLOBAL.CONTROL_CONTROLLER_ALTACTION] = 0
                    local isreleased = not TheInput:IsControlPressed(GLOBAL.CONTROL_CONTROLLER_ALTACTION)
                    SendRPCToServer(RPC.ControllerAltActionButton, act.action.code, self.inst, isreleased, nil, act.action.mod_name)
                end

                self:DoAction(act)
                return
            end
        end
        
        _oldDoControllerAltActionButton(self)
    end

    --"A" button on xbox controller
    local _oldDoControllerActionButton = self.DoControllerActionButton
    function self:DoControllerActionButton()
        if self.gfSpellPointerEnabled 
            and self:IsEnabled()
            and not self:UsingMouse()
        then
            local pointer = self.inst.components.gfspellpointer.pointer
            local position = pointer.targetPosition or Vector3(0, 0, 0)
            local target = pointer.targetEntity

            local act = self.inst.components.playeractionpicker:SortActionList({ ACTIONS.GFCASTSPELL }, target or position, nil)[1]
            --local act 
            --for _, action in pairs(self.inst.components.playeractionpicker:SortActionList({ ACTIONS.GFCASTSPELL }, position, nil)) do
                --if act.action == ACTIONS.GFCASTSPELL then
                    --act = action
                    --break
                --end
            --end 
            print("tpa", target, position, act)
            if act then
                if not self.ismastersim then
                    act.preview_cb = function()
                        self.remote_controls[GLOBAL.CONTROL_CONTROLLER_ACTION] = 0
                        local isreleased = not TheInput:IsControlPressed(GLOBAL.CONTROL_CONTROLLER_ACTION)
                        if target then
                            SendRPCToServer(RPC.ControllerActionButton, act.action.code, target, isreleased, nil, act.action.mod_name)
                        else
                            SendRPCToServer(RPC.ControllerActionButtonPoint, act.action.code, position.x, position.z, isreleased, nil, act.action.mod_name)
                        end
                    end
                end

                self:DoAction(act)
                return
            end
        end
        
        _oldDoControllerActionButton(self)
    end

    if gfFunctions.GFGetIsMasterSim then return end
    --[[client only changes for the player controller]]
    --need to hook OnLeftClick, if we want to push the calculated position and target
    --host will work correctly without this
    local _oldOnLeftClick = self.OnLeftClick
    function self:OnLeftClick(down)
        if self.gfSpellPointerEnabled 
            and down
            and self:IsEnabled()
            and self:UsingMouse()
        then
            local act = self:GetLeftMouseAction()
            if  act and act.action == ACTIONS.GFCASTSPELL then
                local controlmods = self:EncodeControlMods()
                local pointer = self.inst.components.gfspellpointer.pointer
                local position = pointer.targetPosition
                local target = pointer.targetEntity

                act.preview_cb = function()
                    self.remote_controls[GLOBAL.CONTROL_PRIMARY] = 0
                    local isreleased = not TheInput:IsControlPressed(GLOBAL.CONTROL_PRIMARY)
                    SendRPCToServer(RPC.LeftClick, act.action.code, position.x, position.z, target, isreleased, controlmods, nil, act.action.mod_name)
                end

                self:DoAction(act)

                return
            end
        end

        _oldOnLeftClick(self, down)
    end
end)

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
        if gfFunctions.GFGetIsMasterSim() then
            print(string.format("Add Spell Pointer (server) to %s", tostring(player)))
            player:AddComponent("gfspellpointer")
            if not gfFunctions.GFGetDedicatedNet() then --dedicated server doesn't need the recharge watcher component
                print(string.format("Add Recharge Watcher to %s", tostring(player)))
                player:AddComponent("gfrechargewatcher")
            end
        else
            print(string.format("Add Spell Pointer (client) to %s", tostring(player)))
            player:AddComponent("gfspellpointer")
            print(string.format("Add Recharge Watcher to %s", tostring(player)))
            player:AddComponent("gfrechargewatcher")
        end
        --[[ if gfFunctions.GFGetDedicatedNet() and player == nil or player ~= GLOBAL.GFGetPlayer() then return end
        print(string.format("Add Recharge Watcher to %s"), tostring(player))
        player:AddComponent("gfrechargewatcher")
        print(string.format("Add Spell Pointer to %s"), tostring(player))
        player:AddComponent("gfspellpointer") ]]
    end)
end)


local function PlayerFFCheck(self, target)
    return (target:HasTag("player") and not isPVPEnabled)
        or (self.inst.components.leader and self.inst.components.leader:IsFollower(target))
end

AddPlayerPostInit(function(player)
    player:AddTag("gfcandrink")
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

AddPrefabPostInit("gf_lightning_spear", function(inst)
    gfFunctions.GFMakeInventoryCastingItem(inst, {"equip_chainlightning", "equip_crushlightning"})
end)

AddPrefabPostInit("gf_tentacle_staff", function(inst)
    gfFunctions.GFMakeInventoryCastingItem(inst, {"apply_lesser_rejuvenation", "apply_slow"})
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
        --inst.components.gfeffectable:ApplyEffect("affix_shaman")
    end

    --
    --inst:AddComponent("gfrechargableitem")
end)

AddPrefabPostInit("spider", function(inst)
    if gfFunctions.GFGetIsMasterSim() then
        inst:AddComponent("gfeffectable")
    end
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