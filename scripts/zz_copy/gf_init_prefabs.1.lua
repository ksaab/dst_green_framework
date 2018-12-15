--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.
local _G = GLOBAL

--[[Init specified prefabs]]--------
------------------------------------
local GFAddCasterCreature = _G.GFAddCasterCreature
local GFAddCommunicative = _G.GFAddCommunicative
--init spellcasters
--spellcaster friendly fire functions
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

--add prefabs to the caster entities list
GFAddCasterCreature("pigman", PigmanFrindlyFireCheck)
GFAddCasterCreature("bunnyman", PigmanFrindlyFireCheck)
GFAddCasterCreature("knight", ChessFrindlyFireCheck)

--init interlocutors
--want to talk functions
local function PigWantToTalk(talker, inst)
    return not inst:HasTag("werepig") and not inst:HasTag("sfhostile")
end

--talk react functions
local function PigTalkReact(inst, data)
    print("it's a react fn")
    return true
end

--add prefabs to the communicative entities list
GFAddCommunicative("pigman", "PIGMAN_DEFAULT", PigWantToTalk, PigTalkReact, true, 3)
GFAddCommunicative("bunnyman", "BUNNYMAN_DEFAULT", PigWantToTalk, PigTalkReact, true, 4)
GFAddCommunicative("pigking", "PIGKING_DEFAULT", nil, nil, true, 4)
GFAddCommunicative("livingtree", "LIVINGTREE_DEFAULT", nil, nil, true, 4)
GFAddCommunicative("livingtree_halloween", "LIVINGTREE_DEFAULT", nil, nil, true, 4)

--[[Init the world]]----------------
------------------------------------
AddPrefabPostInit("world", function(world)
    world:ListenForEvent("playerentered", function(world, player)
        if not _G.GFGetIsDedicatedNet() and player == _G.ThePlayer then
            _G.GFDebugPrint(string.format("Add Recharge Watcher to %s", tostring(player)))
            player:AddComponent("gfrechargewatcher")
        end
    end)

    if _G.GFGetIsMasterSim() then
        world:AddComponent("gfquesttracker")
    end
end)

--[[Init player]]-------------------
------------------------------------
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
    --inst._currQuestsList = _G.net_string(inst.GUID, "GFQuestDoer._currQuestsList", "GF.GetQuestsdirty")

    --events
    inst._gfPDPushDialog = _G.net_string(inst.GUID, "GFQuestDoer._gfPDPushDialog", "gfPDPushDialogDirty")
    inst._gfPDCloseDialog = _G.net_event(inst.GUID, "gfPDCloseDialogDirty") 
    --syncs
    --inst._gfQSOfferString = _G.net_string(inst.GUID, "GFQuestDoer._gfQSOfferString", "gfQSOfferDirty")
    --inst._gfQSCompleteString = _G.net_string(inst.GUID, "GFQuestDoer._gfQSCompleteString", "gfQSCompleteDirty")
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
                if inst._parent.replica.gfquestdoer ~= nil then
                    inst._parent.replica.gfquestdoer:AttachClassified(inst)
                end
                if inst._parent.components.gfplayerdialog ~= nil then
                    inst._parent.components.gfplayerdialog:AttachClassified(inst)
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
    if _G.GFGetIsMasterSim() and GetModConfigData("tag_overflow_fix") then
        --honestly - I didn't want to make this, 
        --but - I suppose - there is no way to avoid tag-overlow crashes
        player._tagCounter = -1
        --print(player:GetDebugString())
        local tags = string.sub(string.match(player:GetDebugString(), "Tags:.-\n"), 7)
        if tags == nil then
            print("can not calculate counter for existing tags!")
        else
            player._overflowedTags = {}
            --print("tags:", tags)
            for id in tags:gmatch("%S+") do 
                player._tagCounter = player._tagCounter + 1 
                player._overflowedTags[id] = true
                --print(id)
            end


            tags = nil

            player._HasTag = player.HasTag
            player._AddTag = player.AddTag
            player._RemoveTag = player.RemoveTag

            player._overFlag = false

            function player:HasTag(tag)
                return --[[player:_HasTag(tag) or ]]player._overflowedTags[tag] ~= nil
            end

            function player:AddTag(tag)
                if player._overflowedTags[tag] == nil then
                    player._overflowedTags[tag] = true
                    player._tagCounter = player._tagCounter + 1 
                    if player._tagCounter <= 31 then
                        player:_AddTag(tag)
                    elseif not player._overFlag then
                        player._overFlag = true
                        print("tag overflow is registerd for", player)
                    end
                end
            end

            function player:RemoveTag(tag)
                if player._overflowedTags[tag] then
                    player._overflowedTags[tag] = nil
                    player._tagCounter = player._tagCounter - 1 
                    player:_RemoveTag(tag)
                end
            end
        end
    end

    _G.GFMakePlayerCaster(player, _G.GFEntitiesBaseSpells[player.prefab])
    --_G.GFDebugPrint(string.format("Add Spell Pointer (%s) to %s", _G.GFGetIsMasterSim() and "server" or "client", tostring(player)))
    player:AddComponent("gfspellpointer")
    player:AddComponent("gfplayerdialog")
    
    if _G.GFGetIsMasterSim() then
        player:AddComponent("gfeffectable")
        player:AddComponent("gfeventreactor")
        player:AddComponent("gfquestdoer")

        player:ListenForEvent("gfRefuseDrink", function(player, data) 
            if player.components.talker ~= nil then
                local reason = data ~= nil and data.reason or "GENERIC"
                player.components.talker:Say(_G.GetActionFailString(player, "GFDRINKIT", reason or "GENERIC"), 2.5)
            end
        end)
    end

    player:PushEvent("gfQGUpdateQuests")
end)

--[[Init common]]--------------------------------------------------------------
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
        if _G.GFCommunicative[prefab] ~= nil then
            _G.GFMakeCommunicative(inst, _G.GFCommunicative[prefab])
        end
    end
end)