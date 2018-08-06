--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

--[[Init the world]]
local _G = GLOBAL

AddPrefabPostInit("world", function(world)
    world:ListenForEvent("playerentered", function(world, player)
        _G.GFDebugPrint(string.format("Add Spell Pointer (%s) to %s", _G.GFGetIsMasterSim() and "server" or "client", tostring(player)))
        if player.components.gfspellpointer == nil then
            player:AddComponent("gfspellpointer")
        end
        if not _G.GFGetIsDedicatedNet() then
            _G.GFDebugPrint(string.format("Add Recharge Watcher to %s", tostring(player)))
            player:AddComponent("gfrechargewatcher")
        end
    end)
end)

local function PlayerFFCheck(self, target)
    return (target:HasTag("player") and not isPVPEnabled)
        or (self.inst.components.leader and self.inst.components.leader:IsFollower(target))
end

AddPlayerPostInit(function(player)
    _G.GFMakePlayerCaster(player, _G.GFEntitiesBaseSpells[player.prefab])
    if _G.GFGetIsMasterSim() then
        player:AddComponent("gfeffectable")
        player:AddComponent("gfeventreactor")
    end 
end)

--[[Init other stuff]]


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
            _G.GFMakeCaster(inst, _G.GFEntitiesBaseSpells[inst.prefab], _G.GFCasterCreatures[inst.prefab])
        end
    end
end)