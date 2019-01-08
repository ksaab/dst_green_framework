local ALL_QUESTS = GF.GetQuests()

local function UpdateCooldowns(inst)
    local self = inst.components.gfquestdoer
    local currTime = GetTime()
    for qKey, qData in pairs(self.completedQuests) do
        if qData and currTime > qData.readyTime then 
            self.completedQuests[qKey] = nil 
            self:UpdateQuestList(qData.qName, qData.hash, 9)
        end
    end
end

--this function is used to update status for collecting-items quest
--don't want to add two inventory event listeners for every quest
local function OnInvChanged(inst, data)
    local self = inst.components.gfquestdoer
    if self._itemTask == nil then
        self._itemTask = inst:DoTaskInTime(0, function(inst, data) 
            inst:PushEvent("gfinvchanged", data) 
            inst.components.gfquestdoer._itemTask = nil
        end, data)
    end
end

local GFQuestDoer = Class(function(self, inst)
    self.inst = inst

    self.currentQuests = {}
    self.completedQuests = {}
    self.registredQuests = {}

    if GFGetIsMasterSim() then
        --not the best decision, shoud to do something with this
        --TODO - write an another handller for the inventory events
        inst:ListenForEvent("itemlose", OnInvChanged)
        inst:ListenForEvent("gotnewitem", OnInvChanged)
        --update cooldowns for quests on every day segment
        inst:ListenForEvent("phase", function() UpdateCooldowns(inst) end, GFGetWorld())
    end

    if inst.replica.gfquestdoer then 
        inst.replica.gfquestdoer.currentQuests = self.currentQuests
        inst.replica.gfquestdoer.completedQuests = self.completedQuests 
    end
end)

-----------------------------------------
--safe methods---------------------------
-----------------------------------------

function GFQuestDoer:AcceptQuest(qName, hash)
    local qKey = GetQuestKey(qName, hash)
    --component stores quests by qName .. '#' .. hash, so we can pick more then one quest of same type
    --but quests without the soulbound flag are stored without a hash suffix - so player can take only one instace of the quest
    if qKey == nil or not self:CanPickQuest(qName, hash, qKey) then return end

    --GFDebugPrint(string.format("%s accepts quest %s", tostring(self.inst), qKey))

    local qInst = ALL_QUESTS[qName]
    local qData = 
    {
        name = qName, --quest name
        hash = hash, --unique id for quest giver
        world = GFGetWorld().components.gfquesttracker:GetWorldHash(), --uniques id for a world where the quest was picked
        status = 0, --current status, 0 means <in progrees>
    }

    --registring events for quest, 
    --don't need to to this if we already have the same quest with another hash
    if self.registredQuests[qName] == nil then 
        self.registredQuests[qName] = {} 
        qInst:Register(self.inst)
    end
    self.registredQuests[qName][qKey] = qData

    qInst:Accept(self.inst, qData) --loading required data from quest
    self.currentQuests[qKey] = qData --saving the quest data to the components
    self:UpdateQuestList(qName, hash, 3) --sending info about new quest to replica

    return self.currentQuests[qKey]
end

function GFQuestDoer:CompleteQuest(qName, hash, ignore)
    local qKey = GetQuestKey(qName, hash)
    if qKey == nil 
        or self.currentQuests[qKey] == nil 
        or self.currentQuests[qKey].status ~= 1
        or not ALL_QUESTS[qName]:CheckBeforeComplete(self.inst, self.currentQuests[qKey])
    then 
        GFDebugPrint(string.format("%s can't complete the quest %s", tostring(self.inst), qKey))
        return false
    end

    local qInst = ALL_QUESTS[qName]

    --unregistring the quest
    self.registredQuests[qName][qKey] = nil
    if next(self.registredQuests[qName]) == nil then
        --if inst doesn't have same quest with another hash, then unregistring all events
        qInst:Unregister(self.inst)
        self.registredQuests[qName] = nil
    end

    qInst:Complete(self.inst, self.currentQuests[qKey])

    --puushing cooldown for the quest
    if qInst.cooldown ~= nil and qInst.cooldown > 0 then
        self.completedQuests[qKey] = 
        {
            qName = qName,
            hash = hash,
            readyTime = qInst.cooldown + GetTime(),
        }
 
        self:UpdateQuestList(qName, hash, 8) --tell the replica about new cooldown
    end

    self:UpdateQuestList(qName, hash, 5) --tell the replica about successful quest completion
    self.currentQuests[qKey] = nil --removing the quest data from the component

    return true
end

function GFQuestDoer:AbandonQuest(qName, hash)
    local qKey = GetQuestKey(qName, hash)
    if qKey == nil or self.currentQuests[qKey] == nil then return false end

    local qInst = ALL_QUESTS[qName]

    --unregistring the quest
    self.registredQuests[qName][qKey] = nil
    if next(self.registredQuests[qName]) == nil then
        --if inst doesn't have same quest with another hash, then unregistring all events
        qInst:Unregister(self.inst)
        self.registredQuests[qName] = nil
    end

    qInst:Abandon(self.inst, self.currentQuests[qKey])
    GFGetWorld().components.gfquesttracker:QuestAbandoned(self.inst, qName, hash)

    self:UpdateQuestList(qName, hash, 4) --tell the replica
    self.currentQuests[qKey] = nil --removing the quest data from the component

    return true
end

function GFQuestDoer:SetQuestDone(qName, hash, done)
    local qKey = GetQuestKey(qName, hash)
    if qKey == nil or self.currentQuests[qKey] == nil then return false end

    local status = (done == nil or done == false) and 0 or 1

    if self.currentQuests[qKey].status ~= status then
        self.currentQuests[qKey].status = status
        --update the replica
        self:UpdateQuestList(qName, hash, status)
        self:UpdateQuestInfo(qName, hash, done)
    end
end

function GFQuestDoer:SetQuestFailed(qName, hash)
    local qKey = GetQuestKey(qName, hash)
    if qKey == nil or self.currentQuests[qKey] == nil then return false end

    if self.currentQuests[qKey].status ~= 2 then
        --unregistring the quest
        self.registredQuests[qName][qKey] = nil
        if next(self.registredQuests[qName]) == nil then
            --if inst doesn't have same quest with another hash, then unregistring all events
            ALL_QUESTS[qName]:Unregister(self.inst)
            self.registredQuests[qName] = nil
        end

        self.currentQuests[qKey].status = 2
        self:UpdateQuestInfo(qName, hash, true)
        self:UpdateQuestList(qName, hash, 2)
    end
end

function GFQuestDoer:GetQuestData(qName, hash)
    local qKey = GetQuestKey(qName, hash)
    return qKey ~= nil and self.currentQuests[qKey] or nil
end

function GFQuestDoer:GetQuestsDataByName(qName)
    local t = {}
    for _, qData in pairs(self.currentQuests) do
        if qData.qName == qName then
            table.insert(t, qData)
        end
    end

    return t
end

--get info by quest name + giver hash
-------------------------------------------
function GFQuestDoer:CanPickQuest(qName, hash)
    local qKey = GetQuestKey(qName, hash)
    return qKey ~= nil 
        and self.currentQuests[qKey] == nil 
        and self.completedQuests[qKey] == nil
        and ALL_QUESTS[qName]:CheckBeforeGive(self.inst)
end

function GFQuestDoer:HasQuest(qName, hash)
    local qKey = GetQuestKey(qName, hash)
    return qKey ~= nil and self.currentQuests[qKey] ~= nil
end

function GFQuestDoer:IsQuestDone(qName, hash)
    local qKey = GetQuestKey(qName, hash)
    return qKey ~= nil 
        and self.currentQuests[qKey] ~= nil 
        and self.currentQuests[qKey].status == 1
end

--get info by key
-------------------------------------------
function GFQuestDoer:CanPickHashedQuest(qKey, qName)
    return qKey ~= nil 
        and self.currentQuests[qKey] == nil 
        and self.completedQuests[qKey] == nil
        and ALL_QUESTS[qName]:CheckBeforeGive(self.inst)
end

function GFQuestDoer:IsHashedQuestDone(qKey)
    return qKey ~= nil 
        and self.currentQuests[qKey] ~= nil 
        and self.currentQuests[qKey].status == 1
end

function GFQuestDoer:HasHashedQuest(qKey)
    return qKey ~= nil and self.currentQuests[qKey] ~= nil
end

--other
function GFQuestDoer:GetRegistredQuests(qName)
    return self.registredQuests[qName]
end

function GFQuestDoer:GetQuestsNumber()
    return GetTableSize(self.currentQuests)
end

--update replica
function GFQuestDoer:UpdateQuestList(...)
    self.inst.replica.gfquestdoer:UpdateQuestList(...)
end

function GFQuestDoer:UpdateQuestInfo(...)
    self.inst.replica.gfquestdoer:UpdateQuestInfo(...)
end

-----------------------------------------
--unsafe methods-------------------------
-----------------------------------------
function GFQuestDoer:FailQuestsWithHash(hash)
    for qKey, qData in pairs(self.currentQuests) do
        if qData.hash == hash then
            self:SetQuestFailed(qData.name, qData.hash)
        end
    end
end

function GFQuestDoer:ProcessQuests(quests, hash)
    if quests == nil then return end

    local canbepicked, completed, inprogress = {}, {}, {}

    for k, qName in pairs(quests) do
        local qKey = GetQuestKey(qName, hash)
        if self:HasHashedQuest(qKey) then
            local qData = self.currentQuests[qKey]
            if qData.status == 1 then
                table.insert(completed, qData.name)
            else
                table.insert(inprogress, qData.name)
            end
        elseif self:CanPickHashedQuest(qKey, qName) then
            table.insert(canbepicked, qName)
        end
    end

    return canbepicked, completed, inprogress
end

-----------------------------------------
--ingame methods-------------------------
-----------------------------------------
function GFQuestDoer:OnSave()
    local savedata = {}
    savedata.current = {}
    savedata.completedQuests = {}
    for qKey, qData in pairs(self.currentQuests) do
        savedata.current[qKey] = 
        {
            status = qData.status,
            name = qData.name,
            hash = qData.hash,
            world = qData.world,
            string = ALL_QUESTS[qData.name]:OnSave(qData)
        }
    end

    local currTime = GetTime()
    for qKey, qData in pairs(self.completedQuests) do
        if qData and qData.readyTime > currTime then
            savedata.completedQuests[qKey] = 
            {
                remainTime = qData.readyTime - currTime,
                qName = qData.qName,
                hash = qData.hash
            }
        end
    end

    return savedata
end

function GFQuestDoer:OnLoad(data)
    self.inst:DoTaskInTime(FRAMES * 2, function()
        if data ~= nil then
            if data.current ~= nil then
                for qKey, qData in pairs(data.current) do
                    local q = self:AcceptQuest(qData.name, qData.hash)
                    q.status = qData.status
                    q.world = qData.world
                    ALL_QUESTS[qData.name]:OnLoad(q, qData.string)
                end
            end

            local currTime = GetTime()
            if data.completedQuests ~= nil then
                for qKey, qData in pairs(data.completedQuests) do
                    self.completedQuests[qKey] = {}
                    self.completedQuests[qKey].readyTime = currTime + qData.remainTime
                    self.completedQuests[qKey].qName = qData.qName
                    self.completedQuests[qKey].hash = qData.hash
                    self:UpdateQuestList(qData.qName, qData.hash, 8)
                end
            end
        end
    end)
end

function GFQuestDoer:GetDebugString()
    local curr, done = {}, {}
    local dstr = "pdf"
    for k, qData in pairs(self.currentQuests) do
        table.insert(curr, string.format("[%s - %s]", k or "NONE", dstr[qData.status] or "u"))
    end

    return #curr > 0 and table.concat(curr, ",") or "None"
end

return GFQuestDoer