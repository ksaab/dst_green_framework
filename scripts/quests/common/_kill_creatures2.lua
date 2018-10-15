local GFQuest = require "gf_quest"

local questName = "_ex_kill_two_merms"
local requredCreature = "merm"
local requredNumber = 2

local function Serialize(self, doer)
    return tostring(math.min(doer.components.gfquestdoer.currentQuests[questName].count, requredNumber))
end

local function Deserialize(self, doer, data)
    local count = data ~= nil and tonumber(data) or 0
    local cmp = doer.components.gfquestdoer

    if cmp.currentQuests[questName] ~= nil then
        cmp.currentQuests[questName].count = count
    end
end

local function InfoString(self, doer)
    local qData = doer.components.gfquestdoer:GetQuestData(questName)
    return (qData ~= nil and qData.count ~= nil) and string.format("killed: %i/%i", qData.count, requredNumber) or STRINGS.GF.HUD.ERROR
end

local function QuestTrack(doer, data)
    print(requredCreature)
    if data and data.victim and data.victim.prefab == requredCreature then
        local qData = doer.components.gfquestdoer:GetQuestData(questName)
        qData.count = qData.count + 1
        if qData.count >= requredNumber then
            doer:RemoveEventCallback("killed", QuestTrack)
            doer.components.gfquestdoer:SetQuestDone(questName, true)
        else
            doer.components.gfquestdoer:UpdateQuestInfo(questName)
        end
    end
end

local function Accept(self, doer)
    doer.components.gfquestdoer:GetQuestData(questName).count = 0
    if not GFGetIsMasterSim() then return end
    doer:ListenForEvent("killed", QuestTrack)
end

local function Complete(self, doer)
    doer:RemoveEventCallback("killed", QuestTrack)
end

local function CheckOnComplete(self, doer)
    return doer.components.gfquestdoer:GetQuestData(questName).count >= requredNumber
end

local function Reward(self, doer)
    if doer.components.inventory ~= nil then
        doer.components.inventory:GiveItem(SpawnPrefab("meat"))
        doer.components.inventory:GiveItem(SpawnPrefab("meat"))
        doer.components.inventory:GiveItem(SpawnPrefab("spear"))
    end
end

local Quest = Class(GFQuest, function(self)
    GFQuest._ctor(self, questName) --inheritance

    --strings
    self.title = "Green Pigs"
    self.description = "Strange. Want kill pig. Need help."
    self.completion = "You good. Green pigs not."
    self.goaltext = "Kill 2 merms"

    self.StatusStringFn = InfoString

    --flags
    self.norepeat = false
    self.cooldown = 1
    self.savable = true

    --serialization
    self.SerializeFn = Serialize
    self.DeserializeFn = Deserialize

    --status
    self.AcceptFn = Accept
    self.CompleteFn = Complete
    self.AbandonFn = Complete

    --checks
    self.CheckOnCompleteFn = CheckOnComplete

    --reward
    self.RewardFn = Reward
    self.rewardList = nil
end)


return Quest()