local ALL_QUESTS = GF.GetQuests()

--qName - actual name of a quest
--qStorage - table for quests of the same type
--qKey - who will be counted as a quest giver
--qGiver - real quest giver, if quest has the unique flag, qKey will be different from qGiver (qKey will be TheWorld)
--qData - quest data (status, info for the quest conditions, etc)

--[[---------------------------
how it looks-------------------
all quest givers have unique id, which is usually used as qGiver parameter

self.currentQuests = 
{
    qName_1 =               --quest one
    {
        pigm_1 = qData_1,   --first instance of "quest one"
        pigm_2 = qData_2,   --second instance of "quest one"
    },
    qName_2 =               --quest two
    {   
        pigm_1 = qData_3,   --first instance of "quest two", qKey is the same as first qKey from "quest one", it means that these instances of quests are given by the same giver
        pigm_3 = qData_4,   --second instance of "quest two"
        pigm_4 = qData_5,   --third instance of "quest two"
    },
    qName_3 =               --quest three
    {
        world_ = qData_6,   --this means, that the "quest three" has the unique flag, and qKey was getted from TheWorld
    },
}
-----------------------------]]

--[[events-----------------------
0 - quest conditions were failed (quest was done, but now it's not)
1 - quest conditions were completed (quest is done, doer can complete it)
2 - quest is totally failed, players can only abandon it (doesn't work in the current version)
3 - quest accepted
4 - quest abandoned
5 - quest completed
8 - quest is now on cooldown
9 - quest cooldown is ended
-------------------------------]]

local function UpdateCooldowns(inst)
    local self = inst.components.gfquestdoer
    local currTime = GetTime()
    for qName, qStorage in pairs(self.completedQuests) do
        for qKey, readyTime in pairs(qStorage) do 
            if readyTime and currTime > readyTime then 
                self.completedQuests[qName][qKey] = nil 
                if next(self.completedQuests[qName]) == nil then self.completedQuests[qName] = nil end
                self:UpdateQuestList(qName, qKey, 9)
            end
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
    self.registredEvent = {}
    self.callbacks = {}

    self.count = 0

    self.processEvent = function(self, event, inst, data)
        local _ev = self.callbacks[event]
        if _ev ~= nil then
            for qName, _ in pairs(_ev.quests) do
                local qStorage = self.currentQuests[qName]
                if qStorage ~= nil then
                    for qKey, qData in pairs(qStorage) do
                        ALL_QUESTS[qName]:RunMainFn(inst, qData, event, data)
                    end
                end
            end
        end
    end

    if GFGetIsMasterSim() then
        --not the best decision, shoud to do something with this
        --TODO - write an another handler for the inventory events
        inst:ListenForEvent("itemlose", OnInvChanged)
        inst:ListenForEvent("gotnewitem", OnInvChanged)
        --update cooldowns for quests on every day segment
        inst:ListenForEvent("cycle", function() UpdateCooldowns(inst) end, GFGetWorld())
    end

    if inst.replica.gfquestdoer then 
        inst.replica.gfquestdoer.currentQuests = self.currentQuests
        inst.replica.gfquestdoer.completedQuests = self.completedQuests 
    end
end)

-----------------------------------------
--info methods---------------------------
-----------------------------------------
function GFQuestDoer:CanPickQuest(qName, qGiver)
    local qKey = GetQuestKey(qName, qGiver)
    return qKey ~= nil --q is valid
        and (self.currentQuests[qName] == nil or self.currentQuests[qName][qKey] == nil)    --don't has this quest (same quest and giver)
        and (self.completedQuests[qName] == nil or self.completedQuests[qName][qKey] == nil) --don't has cooldown for this quest
        and ALL_QUESTS[qName]:CheckBeforeGive(self.inst) --player can pick the quest (maybe we don't want to give the quest to a specified character)
end

function GFQuestDoer:CanCompleteQuest(qName, qGiver)
    local qKey = GetQuestKey(qName, qGiver)
    local qData = (self.currentQuests[qName] ~= nil) and self.currentQuests[qName][qKey] or nil
    --print(qKey, qData, qData.status, ALL_QUESTS[qName]:CheckBeforeComplete(self.inst, qData))
    return qKey ~= nil 
        and qData ~= nil 
        and qData.status == 1
        and ALL_QUESTS[qName]:CheckBeforeComplete(self.inst, qData)
end

function GFQuestDoer:HasQuest(qName, qGiver)
    local qKey = GetQuestKey(qName, qGiver)
    return qKey ~= nil 
        and self.currentQuests[qName] ~= nil
        and self.currentQuests[qName][qKey] ~= nil
end

function GFQuestDoer:HasNamedQuest(qName)
    return self.currentQuests[qName] ~= nil
end

function GFQuestDoer:IsQuestDone(qName, qGiver)
    local qKey = GetQuestKey(qName, qGiver)
    local qData = (self.currentQuests[qName] ~= nil) and self.currentQuests[qName][qKey] or nil
    return (qKey ~= nil) and qData ~= nil and qData.status == 1
end

-----------------------------------------
--add/remove quests methods--------------
-----------------------------------------
--register/unregister help functions
local function UnregisterQuest(self, qName, qKey)
    local qStorage = self.currentQuests[qName]
    qStorage[qKey] = nil
    if next(qStorage) == nil then
        --if inst doesn't have same quest with another giverID, then unregistring all events
        ALL_QUESTS[qName]:Unregister(self.inst)
        self.currentQuests[qName] = nil
    end
end

local function _reg(self, qInst)
    local event = qInst.event
    local qName = qInst.name
    local _ev = self.callbacks[event]

    if _ev == nil then
        _ev = 
        {
            fn = function(inst, data)
                self:processEvent(event, inst, data)
            end,
            quests = {},
        }
        _ev.quests[qName] = 1
        self.callbacks[event] = _ev
        self.inst:ListenForEvent(event, _ev.fn)
        --print(("%s has new listener for %s event"):format(tostring(self.inst), event))
        --print(("%s has new instance of quest %s for %s event, total instances: 1"):format(tostring(self.inst), qName, event))
    elseif _ev.quests[qName] == nil then
        _ev.quests[qName] = 1
        --print(("%s has new instance of quest %s for %s event, total instances: 1"):format(tostring(self.inst), qName, event))
    else
        _ev.quests[qName] = _ev.quests[qName] + 1
        --print(("%s has new instance of quest %s for %s event, total instances: %i"):format(tostring(self.inst), qName, event, _ev.quests[qName]))
    end
end

local function RegisterComponentEvent(self, qInst)
    if type(qInst.event) == "string" then
        _reg(self, qInst)
    elseif type(qInst.event) == "table" then
        for _, event in pairs(qInst.event) do
            _reg(self, qInst)
        end
    end
end

local function _unreg(self, qInst)
    local event = qInst.event
    local qName = qInst.name
    local _ev = self.callbacks[event]
    if _ev == nil or _ev.quests[qName] == nil then 
        return
    else
        _ev.quests[qName] = _ev.quests[qName] - 1
        --print(("%s removes instance of quest %s for %s event, total instances: %i"):format(tostring(self.inst), qName, event, _ev.quests[qName]))
        if _ev.quests[qName] <= 0 then
            _ev.quests[qName] = nil
            --print(("%s removes quest %s from event %s"):format(tostring(self.inst), qName, event))
        end
    end
    if next(_ev.quests) == nil then 
        self.inst:RemoveEventCallback(event, self.callbacks[event].fn)
        self.callbacks[event] = nil 
        --print(("%s removes listener for %s event"):format(tostring(self.inst), event))
    end
end

local function UnregisterComponentEvent(self, qInst)
    if type(qInst.event) == "string" then
        _unreg(self, qInst)
    elseif type(qInst.event) == "table" then
        for _, event in pairs(qInst.event) do
            _unreg(self, qInst)
        end
    end
end

--components methods
function GFQuestDoer:AcceptQuest(qName, qGiver)
    if not self:CanPickQuest(qName, qGiver) then 
        GFDebugPrint(string.format("%s can't accept the quest %s", tostring(self.inst), qName))
        return false 
    end

    local qKey = GetQuestKey(qName, qGiver)
    local qInst = ALL_QUESTS[qName]
    local qData = 
    {
        --name = qName,   --quest name
        giver = qGiver, --unique id for quest giver
        key = qKey,
        world = GFGetWorld().components.gfquesttracker:GetWorldHash(), --uniques id for a world where the quest was picked
        status = 0,     --current status, 0 means <in progrees>, 1 - <done>, 2 - <failed>
    }

    if self.currentQuests[qName] == nil then
        --registring quest events
        --don't need to to this if we already have the same quest from an another giver
        self.currentQuests[qName] = {} 
        qInst:Register(self.inst)
    end

    RegisterComponentEvent(self, qInst)

    qInst:Accept(self.inst, qData) --loading required data from quest
    self.currentQuests[qName][qKey] = qData --saving the quest data to the components
    self:UpdateQuestList(qName, qKey, 3) --sending info about new quest to replica

    GFGetWorld().components.gfquesttracker:QuestAccepted(self.inst, qName, qGiver)
    self.count = self.count + 1

    return qData
end

function GFQuestDoer:CompleteQuest(qName, qGiver, ignore)
    if not self:CanCompleteQuest(qName, qGiver) and ignore ~= true then 
        GFDebugPrint(string.format("%s can't complete the quest %s", tostring(self.inst), qName))
        return false
    end

    local qKey = GetQuestKey(qName, qGiver)
    local qInst = ALL_QUESTS[qName]
    local qStorage = self.currentQuests[qName]

    qInst:Complete(self.inst, qStorage[qKey])
    --unregistring the quest
    UnregisterQuest(self, qName, qKey)
    UnregisterComponentEvent(self, qInst)

    --puushing cooldown for the quest
    if qInst.cooldown ~= nil and qInst.cooldown > 0 then
        if self.completedQuests[qName] == nil then self.completedQuests[qName] = {} end
        self.completedQuests[qName][qKey] = qInst.cooldown + GetTime()
        self:UpdateQuestList(qName, qKey, 8) --tell the replica about new cooldown
        GFDebugPrint(string.format("%s now has %i seconds cooldown for quest %s", tostring(self.inst), qInst.cooldown, qName))
    end

    self:UpdateQuestList(qName, qKey, 5) --tell the replica about successful quest completion
    GFGetWorld().components.gfquesttracker:QuestCompleted(self.inst, qName, qGiver)
    self.count = self.count - 1

    return true
end

function GFQuestDoer:AbandonQuest(qName, qKey)
    if not self:HasQuest(qName, qKey) then return end

    local qInst = ALL_QUESTS[qName]
    local qStorage = self.currentQuests[qName]

    qInst:Abandon(self.inst, self.currentQuests[qKey])
    GFGetWorld().components.gfquesttracker:QuestAbandoned(self.inst, qName, qKey)

    --unregistring the quest
    UnregisterQuest(self, qName, qKey)
    UnregisterComponentEvent(self, qInst)

    self:UpdateQuestList(qName, qKey, 4) --tell the replica
    self.count = self.count - 1
end

-----------------------------------------
--quest status methods-------------------
-----------------------------------------
function GFQuestDoer:SetQuestDone(qName, qGiver, done)
    if not self:HasQuest(qName, qGiver) then return end

    local qKey = GetQuestKey(qName, qGiver)
    local status = (done == nil or done == false) and 0 or 1

    if self.currentQuests[qName][qKey].status ~= status then
        self.currentQuests[qName][qKey].status = status
        self:UpdateQuestList(qName, qKey, status) --update the replica
        self:UpdateQuestInfo(qName, qKey, done)   --update the replica
    end
end

function GFQuestDoer:SetQuestFailed(qName, qGiver)
    self:AbandonQuest(qName, qGiver)
end

-----------------------------------------
--quests data methods--------------------
-----------------------------------------
function GFQuestDoer:GetQuestData(qName, qGiver)
    if self.currentQuests[qName] ~= nil then
        local qKey = GetQuestKey(qName, qGiver)
        return qKey ~= nil and self.currentQuests[qName][qKey] or nil
    else
        return nil
    end
end

function GFQuestDoer:GetQuestsDataByName(qName)
    return self.currentQuests[qName]
end

function GFQuestDoer:GetQuestsNumber()
    return self.count
end
-----------------------------------------
--replica methods------------------------
-----------------------------------------
function GFQuestDoer:UpdateQuestList(...)
    self.inst.replica.gfquestdoer:UpdateQuestList(...)
end

function GFQuestDoer:UpdateQuestInfo(...)
    self.inst.replica.gfquestdoer:UpdateQuestInfo(...)
end

-----------------------------------------
--unsafe methods-------------------------
-----------------------------------------
function GFQuestDoer:FailQuestsWithHash(qGiver)
    for qName, qStorage in pairs(self.currentQuests) do
        for id, _ in pairs(qStorage) do
            if id == qGiver then
                self:SetQuestFailed(qName, qGiver)
            end
        end
    end
end

function GFQuestDoer:ProcessQuests(quests, qGiver)
    if quests == nil then return end

    local canbepicked, completed, inprogress = {}, {}, {}

    for _, qName in pairs(quests) do
        if self:HasQuest(qName, qGiver) then
            local qKey = GetQuestKey(qName, qGiver)
            if qKey ~= nil then
                local qData = self.currentQuests[qName][qKey]
                if qData.status == 1 then
                    table.insert(completed, qName)
                else
                    table.insert(inprogress, qName)
                end
            end
        elseif self:CanPickQuest(qName, qGiver) then
            table.insert(canbepicked, qName)
        end
    end

    return canbepicked, completed, inprogress
end

-----------------------------------------
--ingame methods-------------------------
-----------------------------------------
function GFQuestDoer:GetQuestsDetalis()
    local t1, t2 = self.currentQuests, self.completedQuests
    print(PrintTable(t1))
    print(PrintTable(t2))
end

function GFQuestDoer:OnSave()
    local savedata = {}
    savedata.current = {}
    savedata.completed = {}
    for qName, qStorage in pairs(self.currentQuests) do
        for qKey, qData in pairs(qStorage) do
            local data = 
            {
                name = qName,
                key = qKey,
                giver = qData.giver,
                world = qData.world,
                status = qData.status,
                string = ALL_QUESTS[qName]:OnSave(self.inst, qData)
            }

            table.insert(savedata.current, data)
        end
    end

    local currTime = GetTime()
    for qName, qStorage in pairs(self.completedQuests) do
        for qKey, readyTime in pairs(qStorage) do
            if currTime < readyTime then
                local data = 
                {
                    key = qKey,
                    name = qName,
                    remainTime = readyTime - currTime,
                }

                table.insert(savedata.completed, data)
            end
        end
    end

    --print(PrintTable(savedata))
    return savedata
end

function GFQuestDoer:OnLoad(data)
    if data ~= nil then
        --print(PrintTable(data))
        self.inst:DoTaskInTime(FRAMES * 2, function()
            if data.current ~= nil then
                for _, qData in pairs(data.current) do
                    if ALL_QUESTS[qData.name] ~= nil then
                        local q = self:AcceptQuest(qData.name, qData.giver)
                        q.status = qData.status
                        q.world = qData.world
                        local isDone = ALL_QUESTS[qData.name]:OnLoad(self.inst, q, qData.string)
                        if isDone then self:SetQuestDone(qData.name, qData.giver, true) end
                    end
                end
            end

            local currTime = GetTime()
            if data.completed ~= nil then
                for _, qData in pairs(data.completed) do
                    if ALL_QUESTS[qData.name] ~= nil then
                        if self.completedQuests[qData.name] == nil then self.completedQuests[qData.name] = {} end
                        self.completedQuests[qData.name][qData.key] = currTime + qData.remainTime
                        self:UpdateQuestList(qData.qName, qData.key, 8)
                    end
                end
            end
        end)
    end
end

function GFQuestDoer:GetDebugString()
    local curr, done = {}, {}
    local dstr = "pdf"
    for qName, qStorage in pairs(self.currentQuests) do
        local q = {}
        for giver, qData in pairs(qStorage) do
            if type(qData) == "table" then
                table.insert(q, string.format("[%s - %s]", giver or "none", qData.status ~= nil and tostring(qData.status) or "u"))
            end
        end
        table.insert(curr, string.format("%s: %s", qName, table.concat(q)))
    end

    return #curr > 0 and table.concat(curr, ",") or "None"
end

return GFQuestDoer