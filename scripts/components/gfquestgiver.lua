local ALL_QUESTS = GFQuestList

local charSet = {}

for i = 48,  57 do table.insert(charSet, string.char(i)) end
for i = 97, 122 do table.insert(charSet, string.char(i)) end

local function GenerateHash()
    local str = {}
    local num = #charSet
    for i = 1, 4 do
        str[i] = charSet[math.random(1, num)]
    end

    return table.concat(str)
end

local QSQuestGiver = Class(function(self, inst)
    self.inst = inst
    self.hash = GenerateHash()
    self.questCount = 0

    self.offerList = {}
    self.completeList = {}

    self.dialogString = "DEFAULT"

    self.getAttentionFn = nil
end)

function QSQuestGiver:AddQuest(questName)
    if questName == nil or ALL_QUESTS[questName] == nil then return end

    table.insert(self.offerList, questName)
    table.insert(self.completeList, questName)

    self.inst.replica.gfquestgiver:UpdateQuests()
    --GFDebugPrint(("%s now offers and completes quest %s "):format(tostring(self.inst), questName))
end

function QSQuestGiver:AddQuestToOffer(questName)
    if questName == nil or ALL_QUESTS[questName] == nil then return end

    table.insert(self.offerList, questName)
    self.inst.replica.gfquestgiver:UpdateQuests()
    --GFDebugPrint(("%s now offers quest %s "):format(tostring(self.inst), questName))
end

function QSQuestGiver:AddQuestToComplete(questName)
    if questName == nil or ALL_QUESTS[questName] == nil then return end

    table.insert(self.completeList, questName)
    self.inst.replica.gfquestgiver:UpdateQuests()
    --GFDebugPrint(("%s now completes quest %s "):format(tostring(self.inst), questName))
end

function QSQuestGiver:RemoveQuest(questName, offerOnly)
    RemoveByValue(self.offerList, questName)
    RemoveByValue(self.completeList, questName)
    
    self.inst.replica.gfquestgiver:UpdateQuests()
    --GFDebugPrint(("%s now doesn't have quest %s "):format(tostring(self.inst), questName))
end

function QSQuestGiver:HideQuest(questName)
    RemoveByValue(self.offerList, questName)
    self.inst.replica.gfquestgiver:UpdateQuests()
    --GFDebugPrint(("%s now doesn't have quest %s "):format(tostring(self.inst), questName))
end

function QSQuestGiver:HasQuests()
    return #(self.offerList) + #(self.completeList) > 0
end

function QSQuestGiver:PickQuests(doer)
    local doercomp = doer.components.gfquestdoer
    if not self:HasQuests() or doercomp == nil then return end

    local picked = {}
    local canComplete = {}
    
    for i = 1, #(self.offerList) do
        local qName = self.offerList[i]
        if doercomp:CheckQuest(qName) then
            table.insert(picked, qName)
        end
    end

    for i = 1, #(self.completeList) do
        local qName = self.completeList[i]
        if doercomp:HasQuest(qName) then
            if doercomp:IsQuestDone(qName) then
                table.insert(picked, qName)
            else
                table.insert(canComplete, qName)
            end
        end
    end

    return #picked > 0 and picked or nil, canComplete
end

function QSQuestGiver:IsCompleterFor(qName)
    for _, v in pairs(self.completeList) do
        if v == qName then return true end
    end

    return false
end

function QSQuestGiver:PickQuest(doer)
    if self:HasQuests() then
        for qName, _ in pairs(self.offerList) do
            local quest = ALL_QUESTS[qName]
            if quest ~= nil 
                and doer.components.gfquestdoer:CheckQuest(qName)
                and quest:CheckBeforeGiving(doer, self.inst) 
            then
                return qName
            end
        end
    end

    return nil
end

function QSQuestGiver:OnQuestAccepted(qName, doer)
    local qInst = ALL_QUESTS[qName]
    if qInst.uniqe then self:HideQuest(qName) end
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

    for k, v in pairs(self.offerList or {}) do
        table.insert(give, k)
    end

    for k, v in pairs(self.completeList or {}) do
        table.insert(pass, k)
    end

    return (#give > 0 or #pass > 0)
        and string.format("give:[%s]; pass:[%s]", table.concat(give, ", "), table.concat(pass, ", ")) 
        or "none"
end

return QSQuestGiver
