local allQuests = GFQuestList

local QSQuestGiver = Class(function(self, inst)
    self.inst = inst
    self.questCount = 0
    self.questOfferList = {}
    self.questCompleteList = {}
    self.getAttentionFn = nil
end)

function QSQuestGiver:AddQuest(questName)
    if questName and allQuests[questName] ~= nil then
        self.questOfferList[questName] = true
        self.questCompleteList[questName] = true

        self.questCount = self.questCount + 1 --set local counter
        self.inst.replica.gfquestgiver:AddQuest() --and tell client about quest giver

        GFDebugPrint(("Quest %s added to %s"):format(questName, tostring(self.inst)))
    end
end

--giver can't offer the quest, but can complete it
function QSQuestGiver:HideQuest(questName)
    if questName and self.questOfferList[questName] then
        self.questOfferList[questName] = nil
        --GFDebugPrint(("Quest %s hided on %s"):format(questName, tostring(self.inst)))
    end
end

function QSQuestGiver:RemoveQuest(questName)
    if questName and self.questOfferList[questName] then
        self.questOfferList[questName] = nil
        self.questCompleteList[questName] = nil

        self.questCount = self.questCount - 1
        self.inst.replica.gfquestgiver:RemoveQuest()
        --GFDebugPrint(("Quest %s removed from %s"):format(questName, tostring(self.inst)))
    end
end

function QSQuestGiver:HasQuests()
    return self.questCount > 0
end

function QSQuestGiver:PickQuest(doer)
    if self:HasQuests() then
        for qName, _ in pairs(self.questOfferList) do
            local quest = allQuests[qName]
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

function QSQuestGiver:QuestAccepted(qName, doer)
    local quest = allQuests[qName]
    if quest ~= nil then
        if quest.unique then
            self:HideQuest(qName)
        end

        self.inst:PushEvent("gfqgiveraccept", {qName = qName, doer = doer})
        quest:OnAcceptGiver(self.inst, doer)
    end
end

function QSQuestGiver:QuestCompleted(qName, doer)
    local quest = allQuests[qName]
    if quest ~= nil then
        if quest.unique then
            self:RemoveQuest(qName)
        end

        self.inst:PushEvent("gfqgivercompleted", {qName = qName, doer = doer})
        quest:OnCompleteGiver(self.inst, doer)
    end
end

function QSQuestGiver:GetAttention(doer)
    if self.getAttentionFn ~= nil then
        self.getAttentionFn(self.inst, doer)
    end
end

function QSQuestGiver:GetDebugString()
    local give = {}
    local pass = {}

    for k, v in pairs(self.questOfferList or {}) do
        table.insert(give, k)
    end

    for k, v in pairs(self.questCompleteList or {}) do
        table.insert(pass, k)
    end

    return #give > 0 and #pass > 0
        and string.format("give:[%s]; pass:[%s]", table.concat(give, ", "), table.concat(pass, ", ")) 
        or "none"
end

return QSQuestGiver
