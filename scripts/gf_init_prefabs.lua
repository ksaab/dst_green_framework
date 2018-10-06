--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

--[[Init the world]]
local _G = GLOBAL

AddPrefabPostInit("world", function(world)
    world:ListenForEvent("playerentered", function(world, player)
        --gfspellpointer and gfrechargewatcher components are hard-bounded to ThePlayer
        --so need to add it here, when ThePlayer alredy exists
        if not _G.GFGetIsDedicatedNet() and player == _G.ThePlayer then
            _G.GFDebugPrint(string.format("Add Recharge Watcher to %s", tostring(player)))
            player:AddComponent("gfrechargewatcher")
        end
    end)
end)

--[[Init player]]
local function GFSetSpellsDirty(inst)
    if inst._parent ~= nil then
        inst._parent:PushEvent("gfsetspellsdirty")
    end
end

local function GFSetRechargesDirty(inst)
    if inst._parent ~= nil then
        inst._parent:PushEvent("gfsetspellsdirty")
    end
end

local function GFUpdateRecharges(inst)
    if inst._parent ~= nil then
        inst._parent:PushEvent("gfsetspellsdirty")
    end
end

--[[AddPrefabPostInit("player_classified", function(inst)
    inst._spellString = _G.net_string(inst.GUID, "GFSpellCaster._spellString", "gfsetspellsdirty")
    inst._spellRecharges = _G.net_string(inst.GUID, "GFSpellCaster._spellRecharges", "gfsetrechargesdirty")
    inst._forceUpdateRecharges = _G.net_event(inst.GUID, "gfupdaterechargesdirty")

    local _oldOnEntityReplicated = nil
    if inst.OnEntityReplicated ~= nil then
        _oldOnEntityReplicated = inst.OnEntityReplicated
        inst.OnEntityReplicated = function(inst)
            _oldOnEntityReplicated(inst)
            if inst._parent ~= nil then
                inst._parent.replica["gfspellcaster"]:AttachClassified(inst)
            end
        end
    end

    if not _G.GFGetIsMasterSim() then
        inst:ListenForEvent("gfsetspellsdirty", GFSetSpellsDirty)
        inst:ListenForEvent("gfsetrechargesdirty", GFSetRechargesDirty)
        inst:ListenForEvent("gfupdaterechargesdirty", GFUpdateRecharges)
    end
end)]]

--this function checks spell friendlyfire for players
local function PlayerFFCheck(self, target)
    return (target:HasTag("player") and not isPVPEnabled)
        or (self.inst.components.leader and self.inst.components.leader:IsFollower(target))
end

AddPlayerPostInit(function(player)
    _G.GFMakePlayerCaster(player, _G.GFEntitiesBaseSpells[player.prefab])
    _G.GFDebugPrint(string.format("Add Spell Pointer (%s) to %s", _G.GFGetIsMasterSim() and "server" or "client", tostring(player)))
    player:AddComponent("gfspellpointer")
    player:AddComponent("gfquestdoer")
    if _G.GFGetIsMasterSim() then
        player:AddComponent("gfeffectable")
        player:AddComponent("gfeventreactor")

        --[[ local function ListenOnce()
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

        player:ListenForEvent("gfplayerisready", ListenOnce) ]]
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
    local prefab = inst.prefab
    if inst:HasTag("FX") or inst:HasTag("NOCLICK") or inst:HasTag("player") or invalidPrefabs[prefab] then return end
    if _G.GFQuestGivers[prefab] ~= nil then
        _G.GFMakeQuestGiver(inst, _G.GFQuestGivers[prefab])
    end
    if _G.GFGetIsMasterSim() then
        inst:AddComponent("gfeffectable")
        inst:AddComponent("gfeventreactor")
        if inst.components.equippable and inst.components.equippable.equipslot == _G.EQUIPSLOTS.HANDS then
            _G.GFMakeInventoryCastingItem(inst, _G.GFEntitiesBaseSpells[prefab])
        end
        if _G.GFCasterCreatures[prefab] ~= nil then
            _G.GFMakeCaster(inst, _G.GFEntitiesBaseSpells[prefab], _G.GFCasterCreatures[prefab])
        end
    end
end)