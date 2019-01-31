local questName = "kill_one_tentacle"
local requiredNumber = 1

local function CreatureCheck(creature)
    return creature.prefab == "tentacle"
    --return string.find(creature.prefab, "required_string") ~= nil
    --return creature:HasTag("required_tag")
end

local function Serialize(quest, doer, qData)
    return tostring(math.min(qData.count, requiredNumber))
end

local function Deserialize(quest, doer, qData, string)
    local count = string ~= nil and tonumber(string) or 0
    qData.count = count
end

local function InfoData(quest, doer, qData)
    local current = qData.count or 0
    return {qData.count or 0, requiredNumber}
end

local function QuestTrack(doer, data)
    if data == nil or data.victim == nil or not CreatureCheck(data.victim) then return end

    local qDoerComp = doer.components.gfquestdoer
    local quests = qDoerComp:GetQuestsDataByName(questName)
    for qGiver, qData in pairs(quests) do
        if qData.status == 0 then
            qData.count = qData.count + 1
            if qData.count >= requiredNumber then
                qDoerComp:SetQuestDone(questName, qGiver, true)
            else
                qDoerComp:UpdateQuestInfo(questName, qGiver)
            end
        end
    end
end

local function Accept(quest, doer, qData)
    qData.count = 0
end

local function Register(self, doer)
    doer:ListenForEvent("killed", QuestTrack)
end

local function Unregister(self, doer)
    doer:RemoveEventCallback("killed", QuestTrack)
end

local function Reward(quest, doer)
    if doer.components.inventory ~= nil then
        doer.components.inventory:GiveItem(SpawnPrefab("meat"))
    end
end

local function OnSave(quest, doer, qData)
    return tostring(qData.count)
end

local function OnLoad(quest, doer, qData, string)
    local count = string ~= nil and tonumber(string) or 0
    qData.count = math.min(count, requiredNumber)
    return count >= requiredNumber
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
    quest.SaveFn = OnSave
    quest.LoadFn = OnLoad
    --reward
    quest.RewardFn = Reward
    quest.rewardList = nil
    --hide
    quest.hideOnPick = true
    quest.cooldown = 0

    return quest
end

return GF.Quest(questName, fn)