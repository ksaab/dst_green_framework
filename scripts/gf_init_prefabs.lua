--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.
local _G = GLOBAL

--[[Init specified prefabs]]--------
------------------------------------
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

local function PigmanWantToTalk(talker, inst)
    return not inst:HasTag("werepig") and not inst:HasTag("sfhostile")
end

local prefabs_post_init = 
{
    pigman = function(inst) 
        if _G.GFGetIsMasterSim() then
            inst:AddComponent("gfspellcaster")
            inst.components.gfspellcaster:SetIsTargetFriendlyFn(PigmanFrindlyFireCheck)

            inst:AddComponent("gfinterlocutor")
            inst.components.gfinterlocutor.phrase = "PIGMAN_DEFAULT"
            inst.components.gfinterlocutor.wantsToTalkFn = PigmanWantToTalk
            inst.components.gfinterlocutor.defaultNode = true

            inst:AddComponent("gfquestgiver")
        end
    end,
    pigking = function(inst) 
        if _G.GFGetIsMasterSim() then
            inst:AddComponent("gfinterlocutor")
            inst.components.gfinterlocutor.phrase = "PIGKING_DEFAULT"

            inst:AddComponent("gfquestgiver")
        end
    end,
    bunnyman = function(inst) 
        if _G.GFGetIsMasterSim() then
            inst:AddComponent("gfspellcaster")
            inst.components.gfspellcaster:SetIsTargetFriendlyFn(BunnymanFrindlyFireCheck)

            inst:AddComponent("gfinterlocutor")
            inst:AddComponent("gfquestgiver")
        end
    end,
    knight = function(inst) 
        if _G.GFGetIsMasterSim() then
            inst:AddComponent("gfspellcaster")
            inst.components.gfspellcaster:SetIsTargetFriendlyFn(ChessFrindlyFireCheck)
        end
    end,
}

for prefab, fn in pairs(prefabs_post_init) do
    AddPrefabPostInit(prefab, fn)
end

--init interlocutors
--want to talk functions


--add prefabs to the communicative entities list
--GFAddCommunicative("pigman", "PIGMAN_DEFAULT", PigWantToTalk, PigTalkReact, true, 3)
--GFAddCommunicative("bunnyman", "BUNNYMAN_DEFAULT", PigWantToTalk, PigTalkReact, true, 4)
--GFAddCommunicative("pigking", "PIGKING_DEFAULT", nil, nil, true, 4)
--GFAddCommunicative("livingtree", "LIVINGTREE_DEFAULT", nil, nil, true, 4)
--GFAddCommunicative("livingtree_halloween", "LIVINGTREE_DEFAULT", nil, nil, true, 4)

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

    --pointer
    inst._gfCurrentSpell = _G.net_int(inst.GUID, "GFSpellPointer._gfCurrentSpell", "gfSPDirty")

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
                if inst._parent.components.gfspellpointer ~= nil then
                    inst._parent.components.gfspellpointer:AttachClassified(inst)
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

local function EnableTagFix()
    return GetModConfigData("tag_overflow_fix") == 1
        or (GetModConfigData("tag_overflow_fix") == 0 
            and not (_G.KnownModIndex:IsModEnabled("workshop-1378549454")       -- GEM API has the same fix
                or _G.KnownModIndex:IsModTempEnabled("workshop-1378549454")))   -- But it doesn't fix issues with replicas
end

_G.GF.EnableTagFix = EnableTagFix()
if _G.GF.EnableTagFix then print("Green! Player tag fix is enabled.") end

local function InitPlayer(player)
    if _G.GFGetIsMasterSim() and _G.GF.EnableTagFix then
        --honestly - I didn't want to make this, 
        --but - I suppose - there is no way to avoid tag-overlow crashes
        local nonImportantTags = 
        {
            freezable = true,
            scarytoprey = true,
            debuffable = true,
            lightningtarget = true,
            polite = true,
        }
        player._tagCounter = 0
        --print(player:GetDebugString())
        local tags = string.sub(string.match(player:GetDebugString(), "Tags:.-\n"), 7)
        if tags == nil then
            print("can not calculate counter for existing tags!")
        else
            player._overflowedTags = {}
            --print("tags:", tags)

            local tmptags = {}

            for id in tags:gmatch("%S+") do 
                if nonImportantTags[id] then --string.sub(id, 1, 1) ~= '_' then
                    table.insert(tmptags, id)
                    player:RemoveTag(id)
                    --print("tag", id, "is a server-only tag, removing")
                else
                    player._tagCounter = player._tagCounter + 1 
                    player._overflowedTags[id] = true
                    --print("tag", id, "is a client required tag")
                end
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
                --print("adding tag via new function, total tags ", player._tagCounter + 1)
                if player._overflowedTags[tag] == nil then
                    player._overflowedTags[tag] = true
                    player._tagCounter = player._tagCounter + 1 
                    if player._tagCounter <= 30 then
                        player:_AddTag(tag)
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

            for _, tag in pairs(tmptags) do
                player:AddTag(tag)
            end
        end
    end

    player:AddComponent("gfspellpointer")
    player:AddComponent("gfplayerdialog")
    
    if _G.GFGetIsMasterSim() then
        player:AddComponent("gfquestdoer")
        player:AddComponent("gfeffectable")
        player:AddComponent("gfeventreactor")
        player:AddComponent("gfspellcaster")
        player.components.gfspellcaster:SetIsTargetFriendlyFn(PlayerFFCheck)
        if _G.GF.EntitiesBaseSpells[prefab] ~= nil then 
            player.components.gfspellcaster:AddSpells(_G.GF.EntitiesBaseSpells[prefab]) 
        end

        for _, fn in pairs (_G.GF.PostGreenInit["player"]) do
            fn(inst)
        end

        player:ListenForEvent("gfRefuseDrink", function(player, data) 
            if player.components.talker ~= nil then
                local reason = data ~= nil and data.reason or "GENERIC"
                player.components.talker:Say(_G.GetActionFailString(player, "GFDRINKIT", reason or "GENERIC"), 2.5)
            end
        end)
    end

    player:PushEvent("gfQGUpdateQuests")
end

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

    if inst:HasTag("FX") or inst:HasTag("NOCLICK") or invalidPrefabs[prefab] then return end --fx and non-interactive prefabs

    if inst:HasTag("player") then
        InitPlayer(inst)
        return
    end

    if _G.GFGetIsMasterSim() then
        inst:AddComponent("gfeffectable")
        inst:AddComponent("gfeventreactor")
        if inst.components.equippable 
            and inst.components.equippable.equipslot == _G.EQUIPSLOTS.HANDS 
            and inst.components.gfspellitem == nil
        then
            inst:AddComponent("gfspellitem")
            if _G.GF.EntitiesBaseSpells[prefab] ~= nil then 
                inst.components.gfspellitem:AddSpells(_G.GF.EntitiesBaseSpells[prefab]) 
            end
        end
    end

    if _G.GF.PostGreenInit[prefab] ~= nil then
        for _, fn in pairs (_G.GF.PostGreenInit[prefab]) do
            fn(inst)
        end
    end
end)