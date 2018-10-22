local ALL_QUESTS = GFQuestList

local function SetHash(inst)
    local self = inst.components.gfquestgiver
    if self.hash == nil then
        self.hash = GFGetWorld().components.gfquesttracker:TrackGiver(inst)
        --self.inst.replica.gfquestgiver._hash:set_local(self.hash)
        self.inst.replica.gfquestgiver._hash:set(self.hash)
    end
end

local QSQuestGiver = Class(function(self, inst)
    self.inst = inst
    self.quests = {}
    self.dialogString = "DEFAULT"

    self.getAttentionFn = nil

    if self.inst.replica.gfquestgiver then 
        self.inst.replica.gfquestgiver.quests = self.quests
    end

    inst:DoTaskInTime(0, SetHash)
end)

function QSQuestGiver:AddQuest(questName, mode)
    mode = mode or 0
    self.quests[questName] = mode
    self.inst.replica.gfquestgiver:UpdateQuests()
    if mode == 0 then
        GFDebugPrint(("%s now offers and completes quest %s "):format(tostring(self.inst), questName))
    elseif mode == 1 then
        GFDebugPrint(("%s now offers quest %s "):format(tostring(self.inst), questName))
    elseif mode == 2 then
        GFDebugPrint(("%s now completes quest %s "):format(tostring(self.inst), questName))
    end
end

function QSQuestGiver:SetMode(questName, mode)
    if questName == nil or self.quests[questName] == nil then return end
    mode = mode or 0
    self.quests[questName] = mode
    self.inst.replica.gfquestgiver:UpdateQuests()
    if mode == 0 then
        GFDebugPrint(("%s now offers and completes quest %s "):format(tostring(self.inst), questName))
    elseif mode == 1 then
        GFDebugPrint(("%s now offers quest %s "):format(tostring(self.inst), questName))
    elseif mode == 2 then
        GFDebugPrint(("%s now completes quest %s "):format(tostring(self.inst), questName))
    end
end

function QSQuestGiver:RemoveQuest(questName)
    if self.quests[questName] == nil then return end
    self.quests[questName] = nil
    
    self.inst.replica.gfquestgiver:UpdateQuests()
    GFDebugPrint(("%s now doesn't have quest %s "):format(tostring(self.inst), questName))
end

function QSQuestGiver:HasQuests()
    return next(self.quests) ~= nil
end

function QSQuestGiver:PickQuests(doer)
    local doercomp = doer.components.gfquestdoer
    if not self:HasQuests() or doercomp == nil then return end

    local picked = {}
    local canComplete = {}

    for qName, qData in pairs(self.quests) do
        if doercomp:CheckQuest(qName) then
            table.insert(picked, qName)
        elseif qData ~= 1 
            and doercomp:HasQuest(qName) 
            and (not ALL_QUESTS[qName]:CheckHash() 
                or self.hash == doercomp:GetQuestGiverHash(qName))
        then
            if not doercomp:IsQuestDone(qName) then
                table.insert(canComplete, qName)
            else
                table.insert(picked, qName)
            end
        end
    end

    return #picked > 0 and picked or nil, canComplete
end

function QSQuestGiver:HasQuest(qName)
    return self.quests[qName] ~= nil
end

function QSQuestGiver:IsGiverFor(qName)
    return self.quests[qName] ~= nil and self.quests[qName] ~= 2
end

function QSQuestGiver:IsCompleterFor(qName)
    return self.quests[qName] ~= nil and self.quests[qName] ~= 1
end

function QSQuestGiver:OnQuestAccepted(qName, doer)
    local qInst = ALL_QUESTS[qName]
    if qInst.uniqe then self:SetMode(qName, 2) end
    qInst:GiverAccept(self.inst, doer)
end

function QSQuestGiver:OnQuestCompleted(qName, doer)
    local qInst = ALL_QUESTS[qName]
    if qInst.uniqe then self:RemoveQuest(qName) end
    qInst:GiverComplete(self.inst, doer)
end

function QSQuestGiver:SetReactFn(fn)
    local function _fn(inst, data) 
        self.getAttentionFn(inst, data)
    end

    if fn ~= nil then
        self.getAttentionFn = fn
        self.inst:ListenForEvent("gfQGGetAttention", _fn)
    else
        self.inst:RemoveEventCallback("gfQGGetAttention", _fn)
    end
end

function QSQuestGiver:GetDialogString(doer)
    return self.dialogStringFn ~= nil and self.dialogStringFn(doer) or self.dialogString 
end

function QSQuestGiver:GetHash(doer)
    return self.hash
end

function QSQuestGiver:OnEntitySleep()
    if not GFGetIsDedicatedNet() and self:HasQuests() then
        self.inst.replica.gfquestgiver:StopTrackingPlayer()
    end
end

function QSQuestGiver:OnEntityWake()
    if not GFGetIsDedicatedNet() and self:HasQuests() then
        self.inst.replica.gfquestgiver:StartTrackingPlayer()
    end
end

function QSQuestGiver:GetDebugString()
    local give = {}
    local pass = {}

    for qName, qData in pairs(self.quests) do
        if qData ~= 2 then
            table.insert(give, qName)
        end
        if qData ~= 1 then
            table.insert(pass, qName)
        end
    end
    
    return (#give > 0 or #pass > 0)
        and string.format("give:[%s]; pass:[%s]", table.concat(give, ", "), table.concat(pass, ", ")) 
        or "none"
end


return QSQuestGiver
