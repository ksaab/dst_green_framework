local INVALID_TITLE = STRINGS.GF.HUD.INVALID_LINES.INVALID_TITLE
local INVALID_TEXT = STRINGS.GF.HUD.INVALID_LINES.INVALID_TEXT

local Quest = Class(function(self, qName)
    self.name = qName

    --strings
    self.title = nil
    self.description = nil
    self.completion = nil

    self.StatusStringFn = nil

    --flags
    self.norepeat = false
    self.cooldown = 60
    self.savable = false

    --serialization
    self.SerializeFn = nil
    self.DeserializeFn = nil

    --status
    self.AcceptFn = nil
    self.CompleteFn = nil
    self.AbandonFn = nil

    --checks
    self.CheckOnGiveFn = nil
    self.CheckOnCompleteFn = nil

    --reward
    self.RewardFn = nil
    self.rewardList = nil
end)

function Quest:Serialize(doer)
    return self.SerializeFn ~= nil and self:SerializeFn(doer) or "0"
end

function Quest:Deserialize(doer, data)
    if self.DeserializeFn then
        self:DeserializeFn(doer, data)
    end
end

function Quest:CheckBeforeGive(doer)
    return self.CheckOnGiveFn ~= nil and self:CheckOnGiveFn(doer) or true
end

function Quest:CheckBeforeComplete(doer)
    return self.CheckOnCompleteFn ~= nil and self:CheckOnCompleteFn(doer) or true
end

function Quest:Accept(doer)
    if self.AcceptFn then self:AcceptFn(doer) end
    --GFDebugPrint(("%s has accepted the quest — %s!"):format(tostring(doer), self.name))
end

function Quest:Complete(doer, giver)
    if self.CompleteFn then self:CompleteFn(doer, giver) end
    if self.RewardFn then self:RewardFn(doer, giver) end
    --GFDebugPrint(("%s has completed the quest — %s!"):format(tostring(doer), self.name))
end

function Quest:Abandon(doer)
    if self.AbandonFn then self:AbandonFn(doer) end
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

function Quest:GetStatusData(doer)
    return self.StatusDataFn ~= nil and self:StatusDataFn(doer) or {}
end

function Quest:GetName()
    return self.name
end

function Quest:OnSave(doer, data)
    return (self.savable and self.SerializeFn and self.DeserializeFn) and self:SerializeFn(doer, data) or false
end

function Quest:OnLoad(doer, data)
    if self.DeserializeFn then self:DeserializeFn(doer, data) end
end

return Quest