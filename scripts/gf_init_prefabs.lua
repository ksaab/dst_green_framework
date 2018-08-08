--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

--[[Init the world]]
local _G = GLOBAL

AddPrefabPostInit("world", function(world)
    world:ListenForEvent("playerentered", function(world, player)
        --gfspellpointer and gfrechargewatcher components are hard-bounded to ThePlayer
        --so need to add it here, when ThePlayer alredy exists
        if player.components.gfspellpointer == nil then
            _G.GFDebugPrint(string.format("Add Spell Pointer (%s) to %s", _G.GFGetIsMasterSim() and "server" or "client", tostring(player)))
            player:AddComponent("gfspellpointer")
        end
        if not _G.GFGetIsDedicatedNet() and player == _G.ThePlayer then
            _G.GFDebugPrint(string.format("Add Recharge Watcher to %s", tostring(player)))
            player:AddComponent("gfrechargewatcher")
        end
    end)
end)

--[[Init player]]
--this function checks spell friendlyfire for players
local function PlayerFFCheck(self, target)
    return (target:HasTag("player") and not isPVPEnabled)
        or (self.inst.components.leader and self.inst.components.leader:IsFollower(target))
end

AddPlayerPostInit(function(player)
    _G.GFMakePlayerCaster(player, _G.GFEntitiesBaseSpells[player.prefab])
    if _G.GFGetIsMasterSim() then
        player:AddComponent("gfeffectable")
        player:AddComponent("gfeventreactor")

        local function ListenOnce()
            if player.components.inventory then
                local items = player.components.inventory:ReferenceAllItems()
                for k, item in pairs(items) do
                    if item.replica.gfspellitem then
                        item.replica.gfspellitem:SetSpells()
                        item.replica.gfspellitem:SetSpellRecharges()
                        item.replica.gfspellitem._forceUpdateRecharges:push()
                    end
                end
            end
            player:RemoveEventCallback("gfplayerisready", ListenOnce)

            --I don't know why, but attackrange doesn't update its value on the client-side
            if player.replica.combat then
                tmp = player.replica.combat._attackrange:value()
                player.replica.combat._attackrange:set_local(0)
                player.replica.combat._attackrange:set(tmp)
            end
        end

        player:ListenForEvent("gfplayerisready", ListenOnce)
    end 
end)

--[[Init common]]
--this prefabs doesn't have FX or NOCLICK tags, but they shouldn't be modidifed
local invalidPrefabs = 
{
    forest_network = true,
    shard_network = true,
    inventoryitem_classified = true,
    spawnpoint_master = true,
    spawnpoint_multiplayer = true,
    meteorspawner = true,
    tumbleweedspawner = true,
    antlion_spawner = true,
    multiplayer_portal = true,
    dragonfly_spawner = true
}

AddPrefabPostInitAny(function(inst) 
	if inst:HasTag("FX") or inst:HasTag("NOCLICK") or inst:HasTag("player") or invalidPrefabs[inst.prefab] then return end
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