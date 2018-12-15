local GFQuest = require "gf_quest"

local questName = "_ex_bring_five_logs"
local requredItem = "log"
local requredNumber = 5

local function Serialize(self, doer, qData)
    return tostring(math.min(qData.count, requredNumber))
end

local function Deserialize(self, doer, qData, string)
    local count = string ~= nil and tonumber(string) or 0
    if qData ~= nil then
        qData.count = count
    end
end

local function InfoData(self, doer, qData)
    print("infodata", qData)
    local current = (qData ~= nil and qData.count ~= nil) and qData.count or 0
    return {current, requredNumber}
end

local function QuestTrack(doer, data)
    if data ~= nil and data.item ~= nil and data.item.prefab ~= requredItem then return end

    local qDoerComp = doer.components.gfquestdoer
    local _, count = doer.components.inventory:Has(requredItem, requredNumber)
    local quests = qDoerComp:GetRegistredQuests(questName)
    for qKey, qData in pairs(quests) do
        if count ~= qData.count then
            if count < requredNumber then
                qData.count = count
                if qData.status == 1 then
                    qDoerComp:SetQuestDone(questName, qData.hash, false)
                else
                    qDoerComp:UpdateQuestInfo(questName, qData.hash)
                end
            elseif qData.status == 0 then
                qData.count = math.min(count, requredNumber)
                qDoerComp:SetQuestDone(questName, qData.hash, true)
            end
        end
        print(qKey, "now you have", qData.count, "logs")
    end
end

local function Accept(self, doer, qData)
    local qDoerComp = doer.components.gfquestdoer
    qData.count = 0

    if not GFGetIsMasterSim() then return end
    local _, count = doer.components.inventory:Has(requredItem, requredNumber)
    --quest status should be updated on if it was changed
    if count < requredNumber then
        if count > 0 then
            qData.count = count
            qDoerComp:UpdateQuestInfo(questName, qData.hash)
        end
    else
        qData.count = math.min(count, requredNumber)
        qDoerComp:SetQuestDone(questName, qData.hash, true)
    end
end

local function Register(self, doer)
    doer:ListenForEvent("gfinvchanged", QuestTrack)
end

local function Unregister(self, doer)
    doer:RemoveEventCallback("gfinvchanged", QuestTrack)
end

local function Complete(self, doer)
    doer.components.inventory:ConsumeByName(requredItem, requredNumber)
end

local function CheckOnGive(self, doer)
    return doer.components.inventory ~= nil
end

local function CheckOnComplete(self, doer)
    return doer.components.inventory ~= nil
        and doer.components.inventory:Has(requredItem, requredNumber)
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
    self.StatusDataFn = InfoData

    --flags
    self.norepeat = false
    self.cooldown = 1
    self.savable = true

    --serialization
    self.SerializeFn = Serialize
    self.DeserializeFn = Deserialize

    --register 
    self.RegisterFn = Register
    self.UnregisterFn = Unregister

    --status
    self.AcceptFn = Accept
    self.CompleteFn = Complete

    --checks
    self.CheckOnGiveFn = CheckOnGive
    self.CheckOnCompleteFn = CheckOnComplete

    --reward
    self.RewardFn = Reward
    self.rewardList = nil
end)


return Quest()