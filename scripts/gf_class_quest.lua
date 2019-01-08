local INVALID_TITLE = STRINGS.GF.HUD.INVALID_LINES.INVALID_TITLE
local INVALID_TEXT = STRINGS.GF.HUD.INVALID_LINES.INVALID_TEXT

local Quest = Class(function(self, qName)
    self.name = qName

    self.StatusDataFn = nil

    --flags
    self.unsavable = false          --can progress be saved or not
    self.unique = false             --doer can have only one quest of this type
    self.soulbound = true           --fail if giver is removed
    self.hideOnPick = false         --only one player can pick the quest
    self.removeOnComplete = false   --remove quest from giver when it's completed

    --serialization
    self.SerializeFn = nil
    self.DeserializeFn = nil

    --registring
    self.RegisterFn = nil
    self.UnregisterFn = nil

    --status
    self.AcceptFn = nil
    self.CompleteFn = nil
    self.AbandonFn = nil

    --checks
    self.CheckOnGiveFn = nil
    self.CheckOnCompleteFn = nil

    --reward
    self.RewardFn = nil
end)

function Quest:Serialize(doer, qData)
    return self.SerializeFn ~= nil and self:SerializeFn(doer, qData) or "0"
end

function Quest:Deserialize(doer, qData, string)
    if self.DeserializeFn then
        self:DeserializeFn(doer, qData, string)
    end
end

function Quest:CheckBeforeGive(doer)
    return self.CheckOnGiveFn ~= nil and self:CheckOnGiveFn(doer) or true
end

function Quest:CheckBeforeComplete(doer)
    return self.CheckOnCompleteFn ~= nil and self:CheckOnCompleteFn(doer) or true
end

function Quest:Register(doer)
    if self.RegisterFn then self:RegisterFn(doer) end
    --GFDebugPrint(("%s has registred events on %s!"):format(self.name, tostring(doer)))
end

function Quest:Unregister(doer, qData)
    if self.UnregisterFn then self:UnregisterFn(doer, qData) end
    --GFDebugPrint(("%s has unregistred events on %s!"):format(self.name, tostring(doer)))
end

function Quest:Accept(doer, qData)
    if self.AcceptFn then self:AcceptFn(doer, qData) end
    --GFDebugPrint(("%s has accepted the quest — %s!"):format(tostring(doer), self.name))
end

function Quest:Complete(doer, qData)
    if self.CompleteFn then self:CompleteFn(doer, qData) end
    if self.RewardFn then self:RewardFn(doer, qData) end
    --GFDebugPrint(("%s has completed the quest — %s!"):format(tostring(doer), self.name))
end

function Quest:Abandon(doer, qData)
    if self.AbandonFn then self:AbandonFn(doer, qData) end
    --GFDebugPrint(("%s has abandoned the quest — %s!"):format(tostring(doer), self.name))
end

function Quest:GiverComplete(giver, doer)
    if self.GiverCompleteFn then self:GiverCompleteFn(giver, doer) end
    --GFDebugPrint(("%s has completed the quest — %s!"):format(tostring(doer), self.name))
end

function Quest:GiverAccept(giver, doer)
    if self.GiverAcceptFn then self:GiverAcceptFn(giver, doer) end
    --GFDebugPrint(("%s has completed the quest — %s!"):format(tostring(doer), self.name))
end

function Quest:GetStatusData(doer, qData)
    return self.StatusDataFn ~= nil and self:StatusDataFn(doer, qData) or {}
end

function Quest:GetName()
    return self.name
end

function Quest:OnSave(qData)
    return self.SaveFn and self:SaveFn(qData) or nil
    --return (self.savable and self.SerializeFn and self.DeserializeFn) and self:SerializeFn(doer, data) or false
end

function Quest:OnLoad(qData, string)
    if self.LoadFn ~= nil then self:LoadFn(qData, string) end
    --if self.DeserializeFn then self:DeserializeFn(doer, data) end
end

return Quest