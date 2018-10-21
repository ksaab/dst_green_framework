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

AddPrefabPostInit("player_classified", function(inst)
    --spell casting system
    --inst._spellString = _G.net_string(inst.GUID, "GFSpellCaster._spellString", "gfsetspellsdirty") --all spells for player (these spell appear on the spell panel)
    --inst._spellRecharges = _G.net_string(inst.GUID, "GFSpellCaster._spellRecharges", "gfsetrechargesdirty") --all recharges for player (doesn't include any item recharges)
    --inst._forceUpdateRecharges = _G.net_event(inst.GUID, "gfupdaterechargesdirty") --trigger which forces updating for client interface

    --quest system
    --inst._pushQuest = _G.net_string(inst.GUID, "GFQuestDoer._pushQuest", "gfquestpushdirty") --contains offered quest
    --inst._completeQuest = _G.net_string(inst.GUID, "GFQuestDoer._completeQuest", "gfquestcompletedirty") --contains completed quest, may be should be united with the previous one
    --inst._forceCloseDialog = _G.net_event(inst.GUID, "gfquestclosedialogdirty") --push event to the client, if a quest giver is to far
    --inst._infoLine = _G.net_string(inst.GUID, "GFQuestDoer._infoLine", "gfquestinfodirty") --sending an info about quest stages
    --inst._currQuestsList = _G.net_string(inst.GUID, "GFQuestDoer._currQuestsList", "gfquestlistdirty")

    --events
    inst._gfQSCloseDialogEvent = _G.net_event(inst.GUID, "gfQSEventCDialogDirty") 
    --syncs
    inst._gfQSOfferString = _G.net_string(inst.GUID, "GFQuestDoer._gfQSOfferString", "gfQSOfferDirty")
    inst._gfQSCompleteString = _G.net_string(inst.GUID, "GFQuestDoer._gfQSCompleteString", "gfQSCompleteDirty")
    --inst._gfQSCurrentString = _G.net_string(inst.GUID, "GFQuestDoer._gfQSCurrentString", "gfQSCurrentDirty")
    --streams
    inst._gfQSEventStream = _G.net_strstream(inst, "GFQuestDoer._gfQSEventStream", "gfQSEventDirty")
    inst._gfQSInfoStream = _G.net_strstream(inst, "GFQuestDoer._gfQSInfoStream", "gfQSInfoDirty")

    --effects
    inst._gfEFEventStream = _G.net_strstream(inst, "GFEffectable._gfEFEventStream", "gfEFEventDirty")

    --caster
    inst._gfSCForceRechargesEvent = _G.net_event(inst.GUID, "gfSCForceRechargesEvent") 
    inst._gfSCSpellStream = _G.net_strstream(inst, "GFSpellCaster._gfSCSpellStream", "gfSCEventDirty")

    local _oldOnEntityReplicated = nil
    if inst.OnEntityReplicated ~= nil then
        _oldOnEntityReplicated = inst.OnEntityReplicated
        inst.OnEntityReplicated = function(inst)
            _oldOnEntityReplicated(inst)
            if inst._parent ~= nil then
                if inst._parent.replica.gfeffectable ~= nil then
                    inst._parent.replica.gfeffectable:AttachClassified(inst)
                end
                if inst._parent.replica.gfspellcaster ~= nil then
                    inst._parent.replica.gfspellcaster:AttachClassified(inst)
                end
                if inst._parent.components.gfquestdoer ~= nil then
                    inst._parent.components.gfquestdoer:AttachClassified(inst)
                end
            end
        end
    end
end)

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

        if player:HasTag("woodcutter") then 
            print(("Removing \"polite\" tag from %s"):format(tostring(player)))
            player:RemoveTag("polite") 
        end

        player:ListenForEvent("gfRefuseDrink", function(player, data) 
            if player.components.talker ~= nil then
                local reason = data ~= nil and data.reason or "GENERIC"
                player.components.talker:Say(_G.GetActionFailString(player, "GFDRINKIT", reason or "GENERIC"), 2.5)
            end
        end)
    end

    --player._teststream = _G.net_strstream(player, "player._teststream")
    --player:ListenForEvent("player._teststream", function(player) print(_G.GetTime(), player._teststream:value()) end)

    player:PushEvent("gfQGUpdateQuests")
    --_G.GFCustomComponentReplication(player, "gfeffectable")
    --_G.GFCustomComponentReplication(player, "gfspellcaster")
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
    
    if _G.GFGetIsMasterSim() then
        inst:AddComponent("gfeffectable")
        inst:AddComponent("gfeventreactor")
        if inst.components.equippable and inst.components.equippable.equipslot == _G.EQUIPSLOTS.HANDS then
            _G.GFMakeInventoryCastingItem(inst, _G.GFEntitiesBaseSpells[prefab])
        end
        if _G.GFCasterCreatures[prefab] ~= nil then
            _G.GFMakeCaster(inst, _G.GFEntitiesBaseSpells[prefab], _G.GFCasterCreatures[prefab])
        end
        if _G.GFQuestGivers[prefab] ~= nil then
            _G.GFMakeQuestGiver(inst, _G.GFQuestGivers[prefab], _G.GFEntitiesBaseQuests[prefab])
        end
    end
end)

--[[ AddPrefabPostInitAny(function(inst) 
    local prefab = inst.prefab
    local isMaster = _G.GFGetIsMasterSim()
    if inst:HasTag("FX") or inst:HasTag("NOCLICK") or inst:HasTag("player") or invalidPrefabs[prefab] then return end
    
    if isMaster then
        _G.GFCustomComponentReplication(inst, "gfeffectable")

        --print("post init any " .. tostring(inst.replica._["gfeffectable"]))
        --print(inst.replica.gfeffectable)
        inst:AddComponent("gfeffectable")
        inst:AddComponent("gfeventreactor")
    end

    if inst.replica.equippable and inst.components.replica.equipslot == _G.EQUIPSLOTS.HANDS then
        _G.GFCustomComponentReplication(inst, "gfspellitem")
        if isMaster then
            _G.GFMakeInventoryCastingItem(inst, _G.GFEntitiesBaseSpells[prefab])
        end
    end

    if _G.GFCasterCreatures[prefab] ~= nil then
        if isMaster then
            _G.GFMakeCaster(inst, _G.GFEntitiesBaseSpells[prefab], _G.GFCasterCreatures[prefab])
        end
        --_G.GFCustomComponentReplication(inst, "gfspellcaster")
    end

    if _G.GFQuestGivers[prefab] ~= nil then
        _G.GFCustomComponentReplication(inst, "gfquestgiver")
        if isMaster then
            _G.GFMakeQuestGiver(inst, _G.GFQuestGivers[prefab])
        end
    end
end) ]]