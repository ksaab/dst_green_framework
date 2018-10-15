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
    GFDebugPrint(("%s has accepted the quest — %s!"):format(tostring(doer), self.name))
end

function Quest:Complete(doer)
    if self.CompleteFn then self:CompleteFn(doer) end
    if self.RewardFn then self:RewardFn(doer) end
    GFDebugPrint(("%s has completed the quest — %s!"):format(tostring(doer), self.name))
end

function Quest:Abandon(doer)
    if self.AbandonFn then self:AbandonFn(doer) end
    GFDebugPrint(("%s has abandoned the quest — %s!"):format(tostring(doer), self.name))
end

function Quest:GetStatusString(doer)
    return self.StatusStringFn ~= nil and self:StatusStringFn(doer) or STRINGS.GF.HUD.ERROR
end

function Quest:GetTitleString(doer)
    return self.GetTitleFn ~= nil and self:GetTitleFn(doer) or (self.title or INVALID_TITLE)
end

function Quest:GetDescriptionString(doer)
    return self.GetDescriptionFn ~= nil and self:GetDescriptionFn(doer) or (self.description or INVALID_TEXT)
end

function Quest:GetCompletionString(doer)
    return self.GetCompletionFn ~= nil and self:GetCompletionFn(doer) or (self.completion or INVALID_TEXT)
end

function Quest:GetGoalString(doer)
    return self.goaltext
end

function Quest:GetRewardString(doer)
    return self.reardstr
end

function Quest:GetName(doer)
    return self.name
end

function Quest:GetID()
    return self.id
end

function Quest:OnSave(doer, data)
    return (self.savable and self.SerializeFn and self.DeserializeFn) and self:SerializeFn(doer, data) or false
end

function Quest:OnLoad(doer, data)
    if self.DeserializeFn then self:DeserializeFn(doer, data) end
end

return Quest