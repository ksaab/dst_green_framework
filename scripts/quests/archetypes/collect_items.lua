local GFQuest = require("gf_class_quest")

local function Serialize(self, doer, qData)
    return tostring(math.min(qData.count, self.requiredNumber))
end

local function Deserialize(self, doer, qData, string)
    qData.count = string ~= nil and tonumber(string) or 0
end

local function InfoData(self, doer, qData)
    return {math.min(qData.count or 0, self.requiredNumber), self.requiredNumber}
end

local function CountItems(self, doer)
    local num = 0
    local items = doer.components.inventory:FindItems(self.checkItemFn)
    for _, item in pairs(items) do
        num = (item.components.stackable ~= nil)
            and num + item.components.stackable:StackSize()
            or num + 1
    end

    return num
end

local function QuestTrack(self, doer, qData, eData)
    if data == nil or data.item == nil or self.checkItemFn(data.item) then
        local qDoerComp = doer.components.gfquestdoer
        local has = CountItems(self, doer)
        if has >= self.requiredNumber then
            if qData.status == 0 then
                qData.count = math.min(has, self.requiredNumber)
                qDoerComp:SetQuestDone(self.name, qGiver, true)
            end
        else
            qData.count = has
            if qData.status == 1 then
                qDoerComp:SetQuestDone(self.name, qGiver, false)
            else
                qDoerComp:UpdateQuestInfo(self.name, qGiver)
            end
        end
    end
end

local function CheckOnComplete(self, doer, qData)
    return CountItems(self, doer) >= self.requiredNumber
end

local function Accept(self, doer, qData)
    qData.count = 0
    if GFGetIsMasterSim() and doer.components.inventory ~= nil then
        doer:DoTaskInTime(0, function() doer:PushEvent("gfinvchanged") end)
    end
end

local function Complete(self, doer, qData)
    doer.components.inventory:ConsumeItemsByFn(self.checkItemFn, self.requiredNumber)
    if GFGetIsMasterSim() and doer.components.inventory ~= nil then
        doer:DoTaskInTime(0, function() doer:PushEvent("gfinvchanged") end)
    end
end

local function Reward(self, doer)
    if doer.components.inventory ~= nil then
        doer.components.inventory:GiveItem(SpawnPrefab("meat"))
    end
end

local Quest = Class(GFQuest, function(self, name)
    GFQuest._ctor(self, name) --inheritance
    --strings
    self.StatusDataFn = InfoData
    --serialization
    self.SerializeFn = Serialize
    self.DeserializeFn = Deserialize
    --register 
    self.event = "gfinvchanged"
    self.MainFn = QuestTrack
    --status
    self.AcceptFn = Accept
    self.CompleteFn = Complete
    --checks
    self.CheckOnCompleteFn = CheckOnComplete
    --unique
    self.checkItemFn = function() return false end
    self.requiredNumber = 5
end)

return Quest