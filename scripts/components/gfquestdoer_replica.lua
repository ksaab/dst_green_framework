local ALL_QUESTS = GF.GetQuests()
local QUESTS_IDS = GF.GetQuestsIDs()

--TODO - rewrite this mess
local QEVENTS = 
{
    [0] = STRINGS.GF.HUD.QUEST_INFORMER.QUEST_UNDONE,
    [1] = STRINGS.GF.HUD.QUEST_INFORMER.QUEST_DONE,
    [2] = STRINGS.GF.HUD.QUEST_INFORMER.QUEST_FAILED,
    [3] = STRINGS.GF.HUD.QUEST_INFORMER.QUEST_STARTED,
    [4] = STRINGS.GF.HUD.QUEST_INFORMER.QUEST_ABANDONED,
    [5] = STRINGS.GF.HUD.QUEST_INFORMER.QUEST_COMPLETED,
}

local function QRStatusChanged(doer, event, qKey, qName)
    local self = doer.replica.gfquestdoer

    if self.currentQuests[qName] ~= nil and self.currentQuests[qName][qKey] ~= nil then
        self.currentQuests[qName][qKey].status = event
    end

    doer:PushEvent("gfQSInformerPush", {qKey = qKey, qName = qName, qEvent = event})
    --GFDebugPrint(("QDoerReplica: Quest %s has new status %i on %s"):format(qKey, event, tostring(doer)))
end

local function QRCreate(doer, event, qKey, qName)
    local self = doer.replica.gfquestdoer

    if self.currentQuests[qName] == nil then 
        self.currentQuests[qName] = {}
    end
    if self.currentQuests[qName][qKey] == nil then
        local t = {status = 0}
        self.currentQuests[qName][qKey] = t
        ALL_QUESTS[qName]:Accept(doer, t)
    end

    doer:PushEvent("gfQSInformerPush", {qKey = qKey, qName = qName, qEvent = event})
    --GFDebugPrint(("QDoerReplica: Strating quest %s on %s"):format(qKey, tostring(doer)))
end

local function QRRemove(doer, event, qKey, qName)
    local self = doer.replica.gfquestdoer

    if self.currentQuests[qName] ~= nil and self.currentQuests[qName][qKey] ~= nil then
        self.currentQuests[qName][qKey] = nil
        if next(self.currentQuests[qName]) == nil then
            self.currentQuests[qName] = nil
        end
    end

    if event == 4 then doer:PushEvent("gfQSInformerPush", {qKey = qKey, qName = qName, qEvent = event}) end
    --GFDebugPrint(("QDoerReplica: Removing quest %s from %s"):format(qKey, tostring(doer)))
end

local function QRCooldown(doer, event, qKey, qName)
    local self = doer.replica.gfquestdoer

    if event == 8 then
        if self.completedQuests[qName] == nil then 
            self.completedQuests[qName] = {}
        end
        self.completedQuests[qName][qKey] = true
    elseif self.completedQuests[qName] ~= nil and self.completedQuests[qName][qKey] ~= nil then
        self.completedQuests[qName][qKey] = nil
        if next(self.completedQuests[qName]) == nil then
            self.completedQuests[qName] = nil
        end
    end

    --GFDebugPrint(("QDoerReplica: %s cooldown changed for %s"):format(qName, tostring(doer)))
end

local function DeserealizeEventStream(classified)
    if classified._parent == nil then return end

    ------------------------------------------------------------------
    --what's going on:
    ------------------------------------------------------------------
    --string format:    EVENT;ID;GIVER_HASH^EVENT;ID;GIVER_HASH^etc...
    --                  first quest        |second quest       |etc...
    ------------------------------------------------------------------
    --events:
    --0 - quest now in progress - shoots when player loses a required item and can't complete the quest
    --1 - quest is done - all requirements are met and player can complete the quest 
    --2 - failed - quest failed, player need to abandon it
    --3 - new quest - player got a new qeust, need to create a local replica
    --4 - quest abandoned - same as above but also pushes an event for an informer
    --5 - quest completed - player completed the quest, need to remove the replica
    ------------------------------------------------------------------
    --print(classified._gfQSEventStream:value())
    local dataArr = classified._gfQSEventStream:value():split('^')

    for _, qData in pairs(dataArr) do
        local qArr = qData:split(';')
        if #qArr == 3 then --don't want to process if the string is wrong
            local qName = QUESTS_IDS[tonumber(qArr[2])]
            if qName ~= nil then
                local qEvent = tonumber(qArr[1])
                local qKey = qArr[3]

                if qEvent <= 2 then
                    QRStatusChanged(classified._parent, qEvent, qKey, qName)
                elseif qEvent == 3 then
                    QRCreate(classified._parent, qEvent, qKey, qName)
                elseif qEvent == 4 or qEvent == 5 then
                    QRRemove(classified._parent, qEvent, qKey, qName)
                elseif qEvent == 8 or qEvent == 9 then
                    QRCooldown(classified._parent, qEvent, qKey, qName)
                end
            end
        end
    end

    classified._parent:PushEvent("gfQSOnQuestUpdate")
end

local function DoDeserealizeInformerStream(classified)
    if classified._parent == nil then return end

    --what's going on:
    --------------------------------------------------------------------------------------------------------
    --string format:    ID;GIVER_HASH;SERIALIZED_STRING;NOINFO^ID;GIVER_HASH;SERIALIZED_STRING^etc...
    --                  first quest                           |second quest                   |etc...
    --------------------------------------------------------------------------------------------------------
    --if NOINFO ~= nil then a hud event will not be fired
    --print(classified._gfQSInfoStream:value())
    local dataArr = classified._gfQSInfoStream:value():split('^')
    local self = classified._parent.replica.gfquestdoer

    for _, qData in pairs(dataArr) do
        local qArr = qData:split(';')
        if #qArr == 3 or #qArr == 4 then --don't want to process if the string is wrong
            local qName = QUESTS_IDS[tonumber(qArr[1])]
            if qName ~= nil then
                local qKey = qArr[2]
                if self.currentQuests[qName][qKey] ~= nil then
                    ALL_QUESTS[qName]:Deserialize(classified._parent, self.currentQuests[qName][qKey], qArr[3])
                    if qArr[4] == nil then
                        classified._parent:PushEvent("gfQSInformerPush", {qKey = qKey, qName = qName})
                    end
                end
            end
        end
    end
end

local function DeserealizeInformerStream(classified)
    classified:DoTaskInTime(0, DoDeserealizeInformerStream)
end

local GFQuestDoer = Class(function(self, inst)
    self.inst = inst

    self.currentQuests = {}
    self.completedQuests = {}

    --attaching classified on the server-side
    if self.classified == nil and inst.player_classified ~= nil then
        self:AttachClassified(inst.player_classified)
    end

    if self.inst.components.gfquestdoer ~= nil then 
        self.currentQuests = self.inst.components.gfquestdoer.currentQuests
        self.completedQuests = self.inst.components.gfquestdoer.completedQuests
    end
end)

-----------------------------------
--classified methods---------------
-----------------------------------
function GFQuestDoer:AttachClassified(classified)
    if self.classified ~= nil then return end

    self.classified = classified
    --default things, like in the others replicatable components
    self.ondetachclassified = function() self:DetachClassified() end
    self.inst:ListenForEvent("onremove", self.ondetachclassified, classified)

    --collecting events directly from the classified prefab
    if not GFGetIsMasterSim() then 
        self.inst:ListenForEvent("gfQSEventDirty", DeserealizeEventStream, classified)
        self.inst:ListenForEvent("gfQSInfoDirty", DeserealizeInformerStream, classified)
    end
end

function GFQuestDoer:DetachClassified()
    --default things, like in the others replicatable components
    self.classified = nil
    self.ondetachclassified = nil
end

-----------------------------------
--data methods---------------------
-----------------------------------
function GFQuestDoer:GetInfoForJournal()
    local res = {}
    local i = 1
    for qName, qStorage in pairs(self.currentQuests) do
        for qKey, qData in pairs(qStorage) do
            res[i] = 
            {
                GetQuestString(self.inst, qName, "title"),
                string.format(GetQuestString(self.inst, qName, "status"), 
                    unpack(ALL_QUESTS[qName]:GetStatusData(self.inst, qData))),
                qData.status,
                qName,
                qKey,
            }

            i = i + 1
        end
    end

    return (#res > 0) and res or nil
end

function GFQuestDoer:GetInformerLine(qEvent, qName, qKey)
    local qString = ""
    if qName == nil or qKey == nil then return false end
    
    if qEvent ~= nil then
        qString = string.format("%s - %s", 
            GetQuestString(self.inst, qName, "title"), 
            string.format(QEVENTS[qEvent] or STRINGS.GF.HUD.ERROR))
    elseif self:HasQuest(qName, qKey) then 
        qString = string.format("%s - %s", 
            GetQuestString(self.inst, qName, "title"), 
            string.format(GetQuestString(self.inst, qName, "status"), 
                unpack(ALL_QUESTS[qName]:GetStatusData(self.inst, self.currentQuests[qName][qKey]))))
    end

    return qString
end

function GFQuestDoer:UpdateQuestList(qName, qKey, status)
    if GFGetPlayer() == self.inst then
        if not GFGetIsDedicatedNet() then
            self.inst:PushEvent("gfQSOnQuestUpdate")
            if status ~= 8 and status ~= 9 then
                self.inst:PushEvent("gfQSInformerPush", {qKey = qKey, qName = qName, qEvent = status})
            end
        end
    else
        self.classified._gfQSEventStream:push_string(string.format("%i;%i;%s", 
            status, ALL_QUESTS[qName].id, qKey or '_'))
    end
end

function GFQuestDoer:UpdateQuestInfo(qName, qKey, nopush)
    local qInst = ALL_QUESTS[qName]
    local qData = self.currentQuests[qName][qKey]

    if GFGetPlayer() == self.inst then
        if not GFGetIsDedicatedNet() then
            self.inst:PushEvent("gfQSInformerPush", {qKey = qKey, qName = qName})
        end
    else
        self.classified._gfQSInfoStream:push_string(string.format(nopush == true and "%i;%s;%s;0" or "%i;%s;%s", 
            qInst.id, qKey or '_', qInst:Serialize(self.inst, qData)))
    end
end

-----------------------------------------
--info methods---------------------------
-----------------------------------------
function GFQuestDoer:CanPickQuest(qName, qGiver)
    local qKey = GetQuestKey(qName, qGiver)
    return qKey ~= nil --q is valid
        and (self.currentQuests[qName] == nil or self.currentQuests[qName][qKey] == nil)    --don't has this quest (same quest and giver)
        and (self.completedQuests[qKey] == nil or self.completedQuests[qName][qKey] == nil) --don't has cooldown for this quest
        and ALL_QUESTS[qName]:CheckBeforeGive(self.inst) --player can pick the quest (maybe we don't want to give the quest to a specified character)
end

function GFQuestDoer:CanCompleteQuest(qName, qGiver)
    local qKey = GetQuestKey(qName, qGiver)
    local qData = (self.currentQuests[qName] ~= nil) and self.currentQuests[qName][qKey] or nil
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
    return qKey ~= nil 
        and qData ~= nil 
        and qData.status == 1
end

function GFQuestDoer:GetQuestsDetalis()
    print(PrintTable(self.currentQuests))
    print(PrintTable(self.completedQuests))
end


return GFQuestDoer