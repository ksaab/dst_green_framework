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

local function QuestTrack(self, doer, qData, eData, event)
    if qData.status == 0 and self.checkEventFn(doer, qData, eData, event) then
        local qDoerComp = doer.components.gfquestdoer
        qData.count = qData.count + 1
        if qData.count >= self.requiredNumber then
            qDoerComp:SetQuestDone(self.name, qData.key, true)
        else
            qDoerComp:UpdateQuestInfo(self.name, qData.key)
        end
    end
end

local function Accept(self, doer, qData)
    qData.count = 0
end

local function OnSave(self, doer, qData)
    return tostring(qData.count)
end

local function OnLoad(self, doer, qData, string)
    local count = string ~= nil and tonumber(string) or 0
    qData.count = math.min(count, self.requiredNumber)
    return count >= self.requiredNumber
end

local Quest = Class(GFQuest, function(self, name)
    GFQuest._ctor(self, name) --inheritance
    --strings
    self.StatusDataFn = InfoData
    --serialization
    self.SerializeFn = Serialize
    self.DeserializeFn = Deserialize
    --register 
    self.event = "hereisyourevent"
    self.MainFn = QuestTrack
    --status
    self.AcceptFn = Accept
    --save
    self.SaveFn = OnSave
    self.LoadFn = OnLoad
    --unique
    self.checkEventFn = function() return false end
    self.requiredNumber = 5
end)

return Quest