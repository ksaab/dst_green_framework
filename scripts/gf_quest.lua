local Quest = Class(function(self, qName)
    self.name = qName

    self.title = nil
    self.description = nil
    self.completion = nil
    self.goaltext = nil
    self.reminder = nil

    self.autoComplete = false
    self.unique = false
    self.repeatable = false
    self.cooldown = 0

    self.savable = false

    self.giveCheckFn = nil
    self.rewardFn = nil

    self.onCancelFn = nil

    self.onAcceptFn = nil
    self.onCompleteFn = nil

    self.onAcceptGiverFn = nil
    self.onCompleteGiverFn = nil

    self.onSaveFn = nil
    self.onLoadFn = nil
end)

function Quest:CheckBeforeGiving(doer, giver)
    if self.giveCheckFn then 
        return self:giveCheckFn(doer, giver) 
    end

    return true
end

function Quest:OnAccept(doer, giver)
    if self.onAcceptFn then self:onAcceptFn(doer, giver) end
    --if giver ~= nil then giver.components.gfquestgiver:GiveQuest(self.name, doer) end

    --print(("%s has accepted the quest — %s!"):format(tostring(doer), (self.name or "<NO TITLE>")))
end

function Quest:OnComplete(doer, giver)
    if self.onCompleteFn then self:onCompleteFn(doer, giver) end
    if self.rewardFn then self:rewardFn(doer, giver) end

    --print(("%s has passed the quest — %s!"):format(tostring(doer), (self.name or "<NO TITLE>")))
end

function Quest:OnCancel(doer, giver)
    if self.onCancelFn then self:onCancelFn(doer) end
    print(("%s has canceled the quest — %s!"):format(tostring(doer), (self.name or "<NO TITLE>")))
end

function Quest:OnAcceptGiver(giver, doer)
    if self.onAcceptGiverFn then self:onAcceptGiverFn(giver, doer) end
    --if giver ~= nil then giver.components.gfquestgiver:GiveQuest(self.name, doer) end

    --print(("%s has given the quest — %s!"):format(tostring(giver), (self.name or "<NO TITLE>")))
end

function Quest:OnCompleteGiver(giver, doer)
    if self.onCompleteGiverFn then self:onCompleteGiverFn(giver, doer) end

    --print(("%s has completed the quest — %s!"):format(tostring(giver), (self.name or "<NO TITLE>")))
end

function Quest:OnSave(doer, data)
    return (self.savable and self.onSaveFn and self.onLoadFn) and self:onSaveFn(doer, data) or false
end

function Quest:OnLoad(doer, data)
    if self.onLoadFn then self:onLoadFn(doer, data) end
end

return Quest