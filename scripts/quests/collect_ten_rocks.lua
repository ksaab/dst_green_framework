local questName = "collect_ten_rocks"
local requiredNumber = 10

local function InvItemCheck(item)
    return item.prefab == "rocks"
    --return string.find(item.prefab, "required_string") ~= nil
    --return item:HasTag("required_tag")
end

local function Serialize(quest, doer, qData)
    return tostring(math.min(qData.count, requiredNumber))
end

local function Deserialize(quest, doer, qData, string)
    qData.count = string ~= nil and tonumber(string) or 0
end

local function InfoData(quest, doer, qData)
    local current = qData.count or 0
    return {qData.count or 0, requiredNumber}
end

local function QuestTrack(doer, data)
    if data == nil or data.item == nil or InvItemCheck(data.item) then
        local qDoerComp = doer.components.gfquestdoer
        local quests = qDoerComp:GetQuestsDataByName(questName)
        local has = #(doer.components.inventory:FindItems(InvItemCheck))
        for qGiver, qData in pairs(quests) do
            if has >= requiredNumber then
                if qData.status == 0 then
                    qData.count = math.max(has, requiredNumber)
                    qDoerComp:UpdateQuestInfo(questName, qGiver)
                    qDoerComp:SetQuestDone(questName, qGiver, true)
                end
            else
                qData.count = has
                qDoerComp:UpdateQuestInfo(questName, qGiver)
                if qData.status == 1 then
                    qDoerComp:SetQuestDone(questName, qGiver, false)
                end
            end
        end
    end
end

local function Register(self, doer)
    doer:ListenForEvent("gfinvchanged", QuestTrack)
end

local function Unregister(self, doer)
    doer:RemoveEventCallback("gfinvchanged", QuestTrack)
end

local function CheckOnComplete(self, doer, qData)
    return doer.components.inventory ~= nil and #(doer.components.inventory:FindItems(InvItemCheck)) >= requiredNumber
end

local function Accept(quest, doer, qData)
    qData.count = 0
    if GFGetIsMasterSim() and doer.components.inventory ~= nil then
        doer:PushEvent("gfinvchanged")
    end
end

local function Complete(quest, doer, qData)
    doer.components.inventory:ConsumeByFn(InvItemCheck, requiredNumber)
end

local function Reward(quest, doer)
    if doer.components.inventory ~= nil then
        doer.components.inventory:GiveItem(SpawnPrefab("meat"))
    end
end

local function fn()
    local quest = GF.CreateQuest()
    --strings
    quest.StatusDataFn = InfoData
    --serialization
    quest.SerializeFn = Serialize
    quest.DeserializeFn = Deserialize
    --register 
    quest.RegisterFn = Register
    quest.UnregisterFn = Unregister
    --status
    quest.AcceptFn = Accept
    --quest.CompleteFn = Complete
    --checks
    quest.CheckOnCompleteFn = CheckOnComplete
    --reward
    quest.RewardFn = Reward
    --hide
    quest.hideOnPick = false
    quest.cooldown = 0

    return quest
end

return GF.Quest(questName, fn)