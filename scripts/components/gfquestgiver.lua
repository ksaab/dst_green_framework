local ALL_QUESTS = GF.GetQuests()
local OFFSETS = GF.QUEST_GIVER_OFFSETS

--this will be called only for new entities, OnLoad function will kill this task
--and will load hash from the persist data
local function SetHash(inst)
    local self = inst.components.gfquestgiver
    if self.hash == nil then
        self.hash = GFGetWorld().components.gfquesttracker:TrackGiver(inst)
        self.inst.replica.gfquestgiver._hash:set(self.hash)

        --if some quests were added before hash is ready
        for k, v in pairs(self._quests) do
            self:AddQuest(k, v)
        end

        self._quests = nil
        self._hashTask = nil
    end
end

local QSQuestGiver = Class(function(self, inst)
    self.inst = inst
    self.hash = nil

    self.quests = {}

    if inst.components.gfinterlocutor == nil then inst:AddComponent("gfinterlocutor") end
    if inst.replica.gfquestgiver then inst.replica.gfquestgiver.quests = self.quests end

    --temp variables
    self._quests = {}
    self._hashTask = inst:DoTaskInTime(0, SetHash)
end)

-----------------------------------------
--safe methods---------------------------
-----------------------------------------

function QSQuestGiver:AddQuest(qName, mode)
    if qName == nil or ALL_QUESTS[qName] == nil then return end

    ----------------------------------
    --MODES---------------------------
    --0 - entity can give and complete
    --1 - only give
    --2 - only complete
    ----------------------------------

    mode = mode or 0
    --if we don't have a hash, we can't push quests to component
    --need to wait a bit until the hash will be ready
    if self.hash == nil then self._quests[qName] = mode return end

    local qKey = GetQuestKey(qName, self.hash)
    --component stores quests by qName .. '#' .. hash, so we can pick more then one quest of same type
    --but quests without the soulbound flag are stored without a hash suffix - so player can take only one instace of the quest

    local t = 
    {
        mode = mode,
        name = qName,
    }

    self.quests[qKey] = t
    self.inst.replica.gfquestgiver:UpdateQuests()

    --debug, do not forget to remove
    if mode == 0 then
        GFDebugPrint(("%s now offers and completes quest %s "):format(tostring(self.inst), qName))
    elseif mode == 1 then
        GFDebugPrint(("%s now offers quest %s "):format(tostring(self.inst), qName))
    elseif mode == 2 then
        GFDebugPrint(("%s now completes quest %s "):format(tostring(self.inst), qName))
    end
end

function QSQuestGiver:SetMode(qName, mode)
    local qKey = GetQuestKey(qName, self.hash)

    if qKey == nil or self.quests[qKey] == nil then return end

    self.quests[qKey].mode = mode or 0
    self.inst.replica.gfquestgiver:UpdateQuests()

    --debug, do not forget to remove
    if mode == 0 then
        GFDebugPrint(("%s now offers and completes quest %s "):format(tostring(self.inst), qName))
    elseif mode == 1 then
        GFDebugPrint(("%s now only offers quest %s "):format(tostring(self.inst), qName))
    elseif mode == 2 then
        GFDebugPrint(("%s now only completes quest %s "):format(tostring(self.inst), qName))
    end
end

function QSQuestGiver:RemoveQuest(qName)
    local qKey = GetQuestKey(qName, self.hash)
    if qKey == nil or self.quests[qKey] == nil then return end
    self.quests[qKey] = nil
    
    self.inst.replica.gfquestgiver:UpdateQuests()
    GFDebugPrint(("%s now doesn't have quest %s "):format(tostring(self.inst), qName))
end

function QSQuestGiver:HasQuests()
    return next(self.quests) ~= nil
end

function QSQuestGiver:GetHash(doer)
    return self.hash
end

function QSQuestGiver:PickQuests(doer)
    local doercomp = doer.components.gfquestdoer
    if doercomp == nil or not self:HasQuests() then return end
    local offer, complete, inprogress = {}, {}, {}

    for qKey, qData in pairs(self.quests) do
        if doercomp:HasHashedQuest(qKey) then
            if qData.mode ~= 1 then
                table.insert(doercomp.currentQuests[qKey].status == 1 and complete or inprogress, qData.name)
            end
        elseif qData.mode ~= 2 and doercomp:CanPickHashedQuest(qKey, qData.name) then
            table.insert(offer, qData.name)
        end
    end

    return 
    {
        offer = offer,
        complete = complete,
        inprogress = inprogress,
    }
end

function QSQuestGiver:HasQuest(qName)
    local qKey = GetQuestKey(qName, self.hash)
    return qKey ~= nil and self.quests[qName] ~= nil
end

function QSQuestGiver:IsGiverFor(qName)
    local qKey = GetQuestKey(qName, self.hash)
    return self.quests[qKey] ~= nil and self.quests[qKey] ~= 2
end

function QSQuestGiver:IsCompleterFor(qName)
    local qKey = GetQuestKey(qName, self.hash)
    return self.quests[qKey] ~= nil and self.quests[qKey] ~= 1
end

-----------------------------------------
--unsafe methods-------------------------
-----------------------------------------

function QSQuestGiver:OnQuestAccepted(qName, doer)
    local qInst = ALL_QUESTS[qName]
    if qInst.hideOnPick then self:SetMode(qName, 2) end
    qInst:GiverAccept(self.inst, doer)
end

function QSQuestGiver:OnQuestCompleted(qName, doer)
    local qInst = ALL_QUESTS[qName]
    if qInst.removeOnComplete then self:RemoveQuest(qName) end
    qInst:GiverComplete(self.inst, doer)
end

function QSQuestGiver:OnQuestAbandoned(qName, doer)
    local qInst = ALL_QUESTS[qName]
    print(self.inst, doer, "has abandoned my quest", qName)
    if qInst.hideOnPick and self:IsCompleterFor(qName) then self:SetMode(qName, 0) end
end

-----------------------------------------
--ingame methods-------------------------
-----------------------------------------

--onsleep|onwake functions are required for hosts without caves
--don't need to update marks or anything else if theentity sleeps
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

function QSQuestGiver:OnSave()
    local savedata = {}
    savedata.hash = self.hash
    savedata.quests = {}
    for k, v in pairs(self.quests) do
        savedata.quests[k] = 
        {
            mode = v.mode,
            name = v.name
        }
    end

    return savedata
end

function QSQuestGiver:OnLoad(data)
    if data then
        if data.hash then
            if self._hashTask ~= nil then
                self._hashTask:Cancel()
                self._hashTask = nil
            end

            self.hash = GFGetWorld().components.gfquesttracker:TrackGiver(self.inst, data.hash)
            self.inst.replica.gfquestgiver._hash:set(self.hash)
        end

        if data.quests then
            for k, v in pairs(data.quests) do
                self:AddQuest(v.name, v.mode)
            end
        end
    end
end

function QSQuestGiver:GetDebugString()
    local give = {}
    local pass = {}

    for qName, qData in pairs(self.quests) do
        if qData.mode ~= 2 then
            table.insert(give, qName)
        end
        if qData.mode ~= 1 then
            table.insert(pass, qName)
        end
    end
    
    return (self.hash or "") .. " " .. ((#give > 0 or #pass > 0)
        and string.format("give:[%s]; pass:[%s]", table.concat(give, ", "), table.concat(pass, ", ")) 
        or "none")
end


return QSQuestGiver
