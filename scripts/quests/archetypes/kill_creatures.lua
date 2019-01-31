local GFQuest = require("gf_class_quest")

local function Serialize(self, doer, qData)
    return tostring(math.min(qData.count, self.requiredNumber))
end

local function Deserialize(self, doer, qData, string)
    local count = string ~= nil and tonumber(string) or 0
    qData.count = count
end

local function InfoData(self, doer, qData)
    local current = qData.count or 0
    return {qData.count or 0, self.requiredNumber}
end

local function QuestTrack(self, doer, qData, eData)
    if eData == nil or eData.victim == nil or not self.checkCreature(eData.victim) then return end

    local qDoerComp = doer.components.gfquestdoer
    if qData.status == 0 then
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
    --
    self.MainFn = QuestTrack
    self.event = "killed"
    --status
    self.AcceptFn = Accept
    --save
    self.SaveFn = OnSave
    self.LoadFn = OnLoad
    --quest unique
    self.requiredNumber = 5
    self.checkCreature = function() return false end
end)

return Quest