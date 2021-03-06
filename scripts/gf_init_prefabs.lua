--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.
local _G = GLOBAL
local tonumber = _G.tonumber
local ALL_QUESTS = _G.GF.GetQuests()
local QUESTS_IDS = _G.GF.GetQuestsIDs()
local ALL_DIALOGUE_NODES = _G.GF.GetDialogueNodes()
local DIALOGUE_NODES_IDS = _G.GF.GetDialogueNodesIDs()

--[[Init specified prefabs]]--------
------------------------------------

--FRIENDLY FIRE CHECKS
local function PigmanFriendlyFireCheck(inst, target)
    return inst.components.combat.target ~= target
        and ((target:HasTag("pig") and not target:HasTag("werepig")) 
            or (inst.components.follower and inst.components.follower.leader == target))
end

local function BunnymanFriendlyFireCheck(inst, target)
    return inst.components.combat.target ~= target
        and (target:HasTag("manrabbit")
            or (inst.components.follower and inst.components.follower.leader == target))
end

local function ChessFriendlyFireCheck(inst, target)
    return inst.components.combat.target ~= target and target:HasTag("chess")
end

local function TallbirdFriendlyFireCheck(inst, target)
    return inst.components.combat.target ~= target and target:HasTag("tallbird")
end

local function SpiderFriendlyFireCheck(inst, target)
    return inst.components.combat.target ~= target and target:HasTag("spider")
end

local function BeefaloFriendlyFireCheck(inst, target)
    return inst.components.combat.target ~= target and target:HasTag("beefalo")
end

local function BatFriendlyFireCheck(inst, target)
    return inst.components.combat.target ~= target and target:HasTag("bat")
end

local function MermFriendlyFireCheck(inst, target)
    return inst.components.combat.target ~= target and target:HasTag("merm")
end

local function HoundFriendlyFireCheck(inst, target)
    return inst.components.combat.target ~= target
        and (target:HasTag("hound")
            or (inst.components.follower and inst.components.follower.leader == target))
end

--CONVERSATION CHECKS
local function PigmanWantToTalk(talker, inst)
    return not inst:HasTag("werepig") and not inst:HasTag("sfhostile")
end

local pigkingShopList = 
{
    {
        name = "spear",
    },
    {
        name = "armorruins",
        currency = "gem",
        price = 5,
    },
}

local prefabs_post_init = 
{
    --creatures
    --intelligent
    pigman = function(inst) 
        if _G.GFGetIsMasterSim() then
            inst:AddComponent("gfspellcaster")
            inst.components.gfspellcaster:SetIsTargetFriendlyFn(PigmanFriendlyFireCheck)

            inst:AddComponent("gfinterlocutor")
            inst.components.gfinterlocutor.phrase = "PIGMAN_DEFAULT"
            inst.components.gfinterlocutor.wantsToTalkFn = PigmanWantToTalk
            inst.components.gfinterlocutor.defaultNode = true

            inst:AddComponent("gfquestgiver")
            --inst.components.gfquestgiver:AddQuest("kill_five_spiders")
            --inst.components.gfquestgiver:AddQuest("kill_one_tentacle")
            --inst.components.gfquestgiver:AddQuest("collect_ten_rocks")
        end
    end,
    bunnyman = function(inst) 
        if _G.GFGetIsMasterSim() then
            inst:AddComponent("gfspellcaster")
            inst.components.gfspellcaster:SetIsTargetFriendlyFn(BunnymanFriendlyFireCheck)

            --inst:AddComponent("gfinterlocutor")
            --inst:AddComponent("gfquestgiver")
        end
    end,
    merm = function(inst) 
        if _G.GFGetIsMasterSim() then
            inst:AddComponent("gfspellcaster")
            inst.components.gfspellcaster:SetIsTargetFriendlyFn(MermFriendlyFireCheck)
        end
    end,

    --hounds
    hound = function(inst) 
        if _G.GFGetIsMasterSim() then
            inst:AddComponent("gfspellcaster")
            inst.components.gfspellcaster:SetIsTargetFriendlyFn(HoundFriendlyFireCheck)
        end
    end,
    firehound = function(inst) 
        if _G.GFGetIsMasterSim() then
            inst:AddComponent("gfspellcaster")
            inst.components.gfspellcaster:SetIsTargetFriendlyFn(HoundFriendlyFireCheck)
        end
    end,
    icehound = function(inst) 
        if _G.GFGetIsMasterSim() then
            inst:AddComponent("gfspellcaster")
            inst.components.gfspellcaster:SetIsTargetFriendlyFn(HoundFriendlyFireCheck)
        end
    end,

    --ghosts
    abigail = function(inst)
        if _G.GFGetIsMasterSim() then
            inst:AddComponent("gfspellcaster")
        end
    end,
    ghost = function(inst)
        if _G.GFGetIsMasterSim() then
            inst:AddComponent("gfspellcaster")
        end
    end,
    
    --chess
    knight = function(inst) 
        if _G.GFGetIsMasterSim() then
            inst:AddComponent("gfspellcaster")
            inst.components.gfspellcaster:SetIsTargetFriendlyFn(ChessFriendlyFireCheck)
        end
    end,

    --spiders
    spider = function(inst) 
        if _G.GFGetIsMasterSim() then
            inst:AddComponent("gfspellcaster")
            inst.components.gfspellcaster:SetIsTargetFriendlyFn(SpiderFriendlyFireCheck)
        end
    end,
    spider_warrior = function(inst) 
        if _G.GFGetIsMasterSim() then
            inst:AddComponent("gfspellcaster")
            inst.components.gfspellcaster:SetIsTargetFriendlyFn(SpiderFriendlyFireCheck)
        end
    end,
    spider_spitter = function(inst) 
        if _G.GFGetIsMasterSim() then
            inst:AddComponent("gfspellcaster")
            inst.components.gfspellcaster:SetIsTargetFriendlyFn(SpiderFriendlyFireCheck)
        end
    end,
    spider_hider = function(inst) 
        if _G.GFGetIsMasterSim() then
            inst:AddComponent("gfspellcaster")
            inst.components.gfspellcaster:SetIsTargetFriendlyFn(SpiderFriendlyFireCheck)
        end
    end,
    spider_dropper = function(inst) 
        if _G.GFGetIsMasterSim() then
            inst:AddComponent("gfspellcaster")
            inst.components.gfspellcaster:SetIsTargetFriendlyFn(SpiderFriendlyFireCheck)
        end
    end,

    --other surface
    tallbird = function(inst) 
        if _G.GFGetIsMasterSim() then
            inst:AddComponent("gfspellcaster")
            inst.components.gfspellcaster:SetIsTargetFriendlyFn(TallbirdFriendlyFireCheck)
        end
    end,

    --other cave
    bat = function(inst) 
        if _G.GFGetIsMasterSim() then
            inst:AddComponent("gfspellcaster")
            inst.components.gfspellcaster:SetIsTargetFriendlyFn(BatFriendlyFireCheck)
        end
    end,
    
    --structures
    pigking = function(inst) 
        if _G.GFGetIsMasterSim() then
        inst:AddComponent("gfinterlocutor")
        inst.components.gfinterlocutor.phrase = "PIGKING_DEFAULT"
        inst.components.gfinterlocutor.defaultNode = true

        inst:AddComponent("gfquestgiver")
        --inst:AddComponent("gfshop")
        --inst.components.gfshop:SetItemList(pigkingShopList)
        end
    end,

    --[[goldnugget = function(inst)
        if _G.GFGetIsMasterSim() then
            inst:AddComponent("gfcurrency")
            inst.components.gfcurrency:SetValue("gold", 1)
        end
    end]]
}

for prefab, fn in pairs(prefabs_post_init) do
    AddPrefabPostInit(prefab, fn)
end

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
local function DeserealizeDialogStrings(classified)
    local _parent = classified._parent
    if _parent == nil --[[or _parent ~= _G.GFGetPlayer()]] then return end
    --print("Deserelizing", classified._gfPDPushDialog:value())
    local strArr = classified._gfPDPushDialog:value():split('^')
    --strArr[1] - dialog string
    --strArr[2] - offered quests
    --strArr[3] - completable quests
    --strArr[4] - events (handled by click)
    --strArr[5] - string (no handle, just info)

    local offer, complete, events, strings = {}, {}, {}, {}

    if strArr[2] ~= '_' then
        for k, qID in pairs(strArr[2]:split(';')) do
            local qName = QUESTS_IDS[tonumber(qID)]
            if qName ~= nil then table.insert(offer, qName) end
        end
    end

    if strArr[3] ~= '_' then
        for k, qID in pairs(strArr[3]:split(';')) do
            local qName = QUESTS_IDS[tonumber(qID)]
            if qName ~= nil then table.insert(complete, qName) end
        end
    end

    if strArr[4] ~= '_' then
        for k, deid in pairs(strArr[4]:split(';')) do
            local deName = DIALOGUE_NODES_IDS[tonumber(deid)]
            if deName ~= nil then table.insert(events, deName) end
        end
    end

    _parent:PushEvent("gfPDChoiseDialog", 
    {
        dString = strArr[1], 
        gQuests = offer,
        cQuests = complete,
        events = events,
    })
end

local function  CloseDialogDirty(classified)
    local _parent = classified._parent
    if _parent ~= nil --[[and _parent == _G.GFGetPlayer()]] then _parent:PushEvent("gfPDCloseDialog") end
end

local function OpenShopDirty(classified)
    local _parent = classified._parent
    if _parent == nil then return end

    local items = {}
    local strArr = classified._gfShopString:value():split('^')
    for _, item in pairs(strArr) do
        local itemData = item:split(';')
        local t = 
        {
            id = tonumber(itemData[1]),
            currency = tonumber(itemData[2]),
            price = itemData[3],
        }
        table.insert(items, t)
    end

    print("owner, list", owner, items)
    _parent:PushEvent("gfShopOpen", items)
    --_G.TheFrontEnd:PushScreen(PopShop(_parent, items))
end

AddPrefabPostInit("player_classified", function(inst)
    --effects
    inst._gfEFEventStream = _G.net_strstream(inst, "GFEffectable._gfEFEventStream", "gfEFEventDirty")
    --caster
    inst._gfSCForceRechargesEvent = _G.net_event(inst.GUID, "gfSCForceRechargesEvent") 
    inst._gfSCSpellStream = _G.net_strstream(inst, "GFSpellCaster._gfSCSpellStream", "gfSCEventDirty")
    --pointer
    inst._gfCurrentSpell = _G.net_int(inst.GUID, "GFSpellPointer._gfCurrentSpell", "gfSPDirty")
    --dialogues sync
    --dialogues
    inst._gfPDPushDialog = _G.net_string(inst.GUID, "GFQuestDoer._gfPDPushDialog", "gfPDPushDialogDirty")
    inst._gfPDCloseDialog = _G.net_event(inst.GUID, "gfPDCloseDialogDirty") 
    --quests
    inst._gfQSEventStream = _G.net_strstream(inst, "GFQuestDoer._gfQSEventStream", "gfQSEventDirty")
    inst._gfQSInfoStream = _G.net_strstream(inst, "GFQuestDoer._gfQSInfoStream", "gfQSInfoDirty")
    --shopping
    inst._gfShopString = _G.net_string(inst.GUID, "GFShopper._gfShopString", "gfShopDirty")
    if not _G.GFGetIsMasterSim() then
        inst:ListenForEvent("gfPDPushDialogDirty", DeserealizeDialogStrings)
        inst:ListenForEvent("gfPDCloseDialogDirty", CloseDialogDirty)
        inst:ListenForEvent("gfShopDirty", OpenShopDirty)
    end
    
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
local function PlayerFFCheck(inst, target)
    local doer = inst --hack for pvp turf mod, need to make it better later
    return inst == target
        or (target:HasTag("player") and not _G.TheNet:GetPVPEnabled())
        or (inst.components.leader and inst.components.leader:IsFollower(target))
end

local function InitPlayer(player)
    player:AddComponent("gfspellpointer")
    
    if _G.GFGetIsMasterSim() then
        player:AddComponent("gfplayerdialog")
        player:AddComponent("gfquestdoer")
        player:AddComponent("gfeffectable")
        player:AddComponent("gfeventreactor")
        player:AddComponent("gfspellcaster")
        player.components.gfspellcaster:SetIsTargetFriendlyFn(PlayerFFCheck)
        if _G.GF.EntitiesBaseSpells[player.prefab] ~= nil then 
            player.components.gfspellcaster:AddSpells(_G.GF.EntitiesBaseSpells[player.prefab]) 
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

    player:ListenForEvent("gfSCCastFailed", function(player, reason) 
        if player.components.talker ~= nil then
            player.components.talker:Say(_G.GetActionFailString(player, "GFCASTSPELL", reason or "GENERIC"), 2.5)
        end
    end)

    player:ListenForEvent("gfDialogButton", function(inst, data)
        if _G.GFGetIsMasterSim() then
            inst.components.gfplayerdialog:HandleButton(data.event, data.name, data.hash)
        else
            SendModRPCToServer(_G.MOD_RPC["GreenFramework"]["GFDIALOGRPC"], data.event, data.name, data.hash)
        end
    end)

    player:ListenForEvent("gfShopButton", function(inst, data)
        if _G.GFGetIsMasterSim() then
            inst.components.gfplayerdialog:HandleShopButton(data.event, data.itemID)
        else
            SendModRPCToServer(_G.MOD_RPC["GreenFramework"]["GFSHOPRPC"], data.event, data.itemID)
        end
    end)

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
    dragonfly_spawner = true,
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
        if inst.components.equippable then
            if inst.components.equippable.equipslot == _G.EQUIPSLOTS.HANDS and inst.components.gfspellitem == nil then
                inst:AddComponent("gfspellitem")
                if _G.GF.EntitiesBaseSpells[prefab] ~= nil then 
                    inst.components.gfspellitem:AddSpells(_G.GF.EntitiesBaseSpells[prefab]) 
                end
            end
        end
    end

    if _G.GF.PostGreenInit[prefab] ~= nil then
        for _, fn in pairs (_G.GF.PostGreenInit[prefab]) do
            fn(inst)
        end
    end
end)