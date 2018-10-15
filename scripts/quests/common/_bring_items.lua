local GFQuest = require "gf_quest"

local questName = "_ex_bring_five_logs"
local requredItem = "log"
local requredNumber = 5

local function Serialize(self, doer)
    return tostring(math.min(doer.components.gfquestdoer.currentQuests[questName].count, requredNumber))
end

local function Deserialize(self, doer, data)
    local count = data ~= nil and tonumber(data) or 0
    GFDebugPrint("_ex_bring_five_logs, deserealizing data: ", count)
    local cmp = doer.components.gfquestdoer
    if cmp.currentQuests[questName] ~= nil then
        cmp.currentQuests[questName].count = count
    else
        GFDebugPrint("_ex_bring_five_logs, can't deserealize data")
    end
end

local function InfoString(self, doer)
    local qData = doer.components.gfquestdoer:GetQuestData(questName)
    return (qData ~= nil and qData.count ~= nil) and string.format("collected items: %i/%i", qData.count, requredNumber) or STRINGS.GF.HUD.ERROR
end

local function QuestTrack(doer)
    local qData = doer.components.gfquestdoer.currentQuests[questName]
    if qData._track --[[or qData.status ~= 0]] then return end

    doer.components.gfquestdoer.currentQuests[questName]._track = true
    doer:DoTaskInTime(0, function(doer)
        local cmp = doer.components.gfquestdoer
        local _, count = doer.components.inventory:Has(requredItem, requredNumber)
        --local qData = cmp.currentQuests[questName]
        --quest status should be updated on if it was changed
        if count ~= qData.count then
            if count < requredNumber then
                qData.count = count
                if qData.status == 1 then
                    cmp:SetQuestDone(questName, false)
                else
                    cmp:UpdateQuestInfo(questName)
                end
            elseif qData.status == 0 then
                qData.count = math.min(count, requredNumber)
                --cmp:UpdateQuestInfo(questName)
                cmp:SetQuestDone(questName, true)
            end
        end
        cmp.currentQuests[questName]._track = false
    end)
end

local function CheckItem(doer, data)
    if doer.components.gfquestdoer.currentQuests[questName].status == 0
        and data 
        and data.item 
        and data.item.prefab == requredItem 
    then 
        QuestTrack(doer) 
    end
end

local function Accept(self, doer)
    local cmp = doer.components.gfquestdoer

    local qData = cmp.currentQuests[questName]
    qData.count = 0

    if not GFGetIsMasterSim() then return end

    local _, count = doer.components.inventory:Has(requredItem, requredNumber)
    --quest status should be updated on if it was changed
    if count < requredNumber then
        if count > 0 then
            qData.count = count
            cmp:UpdateQuestInfo(questName)
        end
    else
        qData.count = math.min(count, requredNumber)
        cmp:SetQuestDone(questName, true)
    end

    doer:ListenForEvent("itemlose", QuestTrack)
    doer:ListenForEvent("gotnewitem", CheckItem)
end

local function Complete(self, doer)
    doer:RemoveEventCallback("itemlose", QuestTrack)
    doer:RemoveEventCallback("gotnewitem", CheckItem)
    doer.components.inventory:ConsumeByName(requredItem, requredNumber)
end

local function Abandon(self, doer)
    doer:RemoveEventCallback("itemlose", QuestTrack)
    doer:RemoveEventCallback("gotnewitem", CheckItem)
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
    self.title = "Pig need home"
    self.description = "Cold nights. I need home. You bring trees."
    self.completion = "Love home. You good."
    self.goaltext = "Bring 5 logs"

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
    self.AbandonFn = Abandon

    --checks
    self.CheckOnGiveFn = CheckOnGive
    self.CheckOnCompleteFn = CheckOnComplete

    --reward
    self.RewardFn = Reward
    self.rewardList = nil
end)


return Quest()