--[[Init the world]]
local _G = GLOBAL

AddPrefabPostInit("world", function(world)
    world:ListenForEvent("playerentered", function(world, player)
        _G.GFDebugPrint(string.format("Add Spell Pointer (%s) to %s", _G.GFGetIsMasterSim() and "server" or "client", tostring(player)))
        player:AddComponent("gfspellpointer")
        if not _G.GFGetIsDedicatedNet() then
            _G.GFDebugPrint(string.format("Add Recharge Watcher to %s", tostring(player)))
            player:AddComponent("gfrechargewatcher")
        end

        --[[ if _G.GFGetIsMasterSim() then
            if _G.GFDev then
                world:ListenForEvent("playeractivated", function(world, player)
                    local inv = player.components.inventory
        
                    if inv and not inv:Has("gf_magic_echo_amulet", 1) then
                        inv:GiveItem( _G.SpawnPrefab("gf_magic_echo_amulet") )
                        inv:GiveItem( _G.SpawnPrefab("gf_lightning_spear") )
                        inv:GiveItem( _G.SpawnPrefab("hammer") )
                        inv:GiveItem( _G.SpawnPrefab("gf_tentacle_staff") )
                    end
                end)
            end
        end ]]
    end)
end)

local function PlayerFFCheck(self, target)
    return (target:HasTag("player") and not isPVPEnabled)
        or (self.inst.components.leader and self.inst.components.leader:IsFollower(target))
end

AddPlayerPostInit(function(player)
    _G.GFMakePlayerCaster(player)
    if _G.GFGetIsMasterSim() then
        player.components.gfspellcaster:SetIsTargetFriendlyFn(PlayerFFCheck)
        player:AddComponent("gfeffectable")
        player:AddComponent("gfeventreactor")
    end 
end)

--[[Init other stuff]]
--[[ AddPrefabPostInit("gf_lightning_spear", function(inst)
    _G.GFMakeInventoryCastingItem(inst, {"equip_chainlightning", "equip_crushlightning"})
end)

AddPrefabPostInit("gf_tentacle_staff", function(inst)
    _G.GFMakeInventoryCastingItem(inst, {"apply_lesser_rejuvenation", "apply_slow"})
end)

AddPrefabPostInit("hammer", function(inst)
    _G.GFMakeInventoryCastingItem(inst, {"equip_groundslam", "equip_shootsting"})
end)

AddPrefabPostInit("gf_bee_dart", function(inst)
    _G.GFMakeInventoryCastingItem(inst, "equip_shootsting")
end)

--creatures
local function PigmanFFCheck(self, target)
    local isFriend = (target:HasTag("pig") and not target:HasTag("werepig"))
        or (target.components.leader and target.components.leader:IsFollower(self.inst))

    return isFriend or false
end

AddPrefabPostInit("pigman", function(inst)
    _G.GFMakeCaster(inst)
    if _G.GFGetIsMasterSim() then
        inst.components.gfspellcaster:SetIsTargetFriendlyFn(PigmanFFCheck)
    end
end) ]]

--[[Init common]]
AddPrefabPostInitAny(function(inst) 
	if inst:HasTag("FX") or inst:HasTag("NOCLICK") or inst:HasTag("player") then return end
    if _G.GFGetIsMasterSim() then
        inst:AddComponent("gfeffectable")
        inst:AddComponent("gfeventreactor")
        if inst.components.equippable and inst.components.equippable.equipslot == _G.EQUIPSLOTS.HANDS then
            _G.GFMakeInventoryCastingItem(inst, _G.GFEntitiesBaseSpells[inst.prefab])
        end
        if _G.GFCasterCreatures[inst.prefab] ~= nil then
            _G.GFMakeCaster(inst, _G.GFEntitiesBaseSpells[inst.prefab])
        end
    end
end)