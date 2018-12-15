local ALL_QUESTS = GF.GetQuests()
local QUESTS_IDS = GF.GetQuestsIDs()

local function _GetQuestKey(qName, hash)
    if qName ~= nil and ALL_QUESTS[qName] ~= nil then
        return ALL_QUESTS[qName].unique
            and qName
            or (hash ~= nil and qName .. hash or nil)
    end

    return nil
end

local function QRStatusChanged(doer, event, qKey, qName)
    if not GFGetIsDedicatedNet() then
        local self = doer.components.gfquestdoer
        if not GFGetIsMasterSim() and qKey ~= nil and self.currentQuests[qKey] ~= nil then
            --update quest replica on the client side
            self.currentQuests[qKey].status = event
        end

        --push event
        doer:PushEvent("gfQSInformerPush", {qKey = qKey, qName = qName, qEvent = event})
    end

    GFDebugPrint(("QDoerReplica: Quest %s has new status %i on %s"):format(qKey, event, tostring(doer)))
end

local function QRCreate(doer, event, qKey, qName, hash)
    if not GFGetIsMasterSim() then
        local self = doer.components.gfquestdoer
        --create a local quest for clients
        if self.currentQuests[qKey] == nil then
            local t = {status = 0, name = qName, hash = hash}
            self.currentQuests[qKey] = t
            ALL_QUESTS[qName]:Accept(doer, t)
        end
    end

    --push event
    if not GFGetIsDedicatedNet() then
        doer:PushEvent("gfQSInformerPush", {qKey = qKey, qName = qName, qEvent = event})
    end

    GFDebugPrint(("QDoerReplica: Strating quest %s on %s"):format(qKey, tostring(doer)))
end

local function QRRemove(doer, event, qKey, qName)
    --remove a local quest for clients
    if not GFGetIsMasterSim() then
        doer.components.gfquestdoer.currentQuests[qKey] = nil
    end

    --push event
    if not GFGetIsDedicatedNet() and event == 4 then
        doer:PushEvent("gfQSInformerPush", {qKey = qKey, qName = qName, qEvent = event})
    end

    GFDebugPrint(("QDoerReplica: Removing quest %s from %s"):format(qKey, tostring(doer)))
end

local function QRCooldown(doer, qName, qEvent)
    
    --remove a local quest for clients
    if not GFGetIsMasterSim() then
        local qKey = GetQuestKey(qName, hash)
        local self = doer.components.gfquestdoer
        self.completedQuests[qKey] = qEvent == 8 and true or nil
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
    print(classified._gfQSEventStream:value())
    local dataArr = classified._gfQSEventStream:value():split('^')
    local self = classified._parent.components.gfquestdoer

    for _, qData in pairs(dataArr) do
        local qArr = qData:split(';')
        if #qArr == 3 then --don't want to process if the string is wrong
            local qName = QUESTS_IDS[tonumber(qArr[2])]
            if qName ~= nil then
                local qEvent = tonumber(qArr[1])
                local hash = qArr[3]
                local qKey = GetQuestKey(qName, hash)

                if qEvent <= 2 then
                    QRStatusChanged(classified._parent, qEvent, qKey, qName)
                elseif qEvent == 3 then
                    QRCreate(classified._parent, qEvent, qKey, qName, hash)
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
    print(classified._gfQSInfoStream:value())
    local dataArr = classified._gfQSInfoStream:value():split('^')
    local self = classified._parent.components.gfquestdoer

    for _, qData in pairs(dataArr) do
        local qArr = qData:split(';')
        if #qArr == 3 or #qArr == 4 then --don't want to process if the string is wrong
            local qName = QUESTS_IDS[tonumber(qArr[1])]
            if qName ~= nil then
                local qKey = GetQuestKey(qName, qArr[2])
                if self.currentQuests[qKey] ~= nil then
                    if not GFGetIsMasterSim() then
                        ALL_QUESTS[qName]:Deserialize(classified._parent, self.currentQuests[qKey], qArr[3])
                    end

                    if qArr[4] == nil then
                        if not GFGetIsDedicatedNet() then
                            classified._parent:PushEvent("gfQSInformerPush", {qKey = qKey, qName = qName})
                        end
                    end
                end
            end
        end
    end
end

local function DeserealizeInformerStream(classified)
    classified:DoTaskInTime(0, DoDeserealizeInformerStream)
end

-----------------------------------
--classified methods---------------
-----------------------------------
local function AttachClassified(self, classified)
    if self.classified ~= nil then return end

    self.classified = classified
    --default things, like in the others replicatable components
    self.ondetachclassified = function() self:DetachClassified() end
    self.inst:ListenForEvent("onremove", self.ondetachclassified, classified)

    --collecting events directly from the classified prefab
    if not GFGetIsMasterSim() then 
        
    end

    if not GFGetIsDedicatedNet() then
        self.inst:ListenForEvent("gfQSEventDirty", DeserealizeEventStream, classified)
        self.inst:ListenForEvent("gfQSInfoDirty", DeserealizeInformerStream, classified)
        --[[ self.inst:ListenForEvent("gfQSOfferDirty", DeserealizeOfferString, classified)
        self.inst:ListenForEvent("gfQSEventCDialogDirty", PushCloseDialog, classified)
        self.inst:ListenForEvent("gfQSCompleteDirty", DeserealizeCompleteString, classified) ]]
    end
end

-----------------------------------
--safe methods---------------------
-----------------------------------

local function DetachClassified(self)
    --default things, like in the others replicatable components
    self.classified = nil
    self.ondetachclassified = nil
end

local function UpdateQuestList(self, qName, qHash, status)
    local qKey = GetQuestKey(qName, qHash)
    if qKey == nil then return end

    --if self.inst ~= ThePlayer or not GFGetIsDedicatedNet() then
    self.classified._gfQSEventStream:push_string(string.format("%i;%i;%s", 
        status, ALL_QUESTS[qName].id, qHash or '_'))
    --end
end

local function UpdateQuestInfo(self, qName, qHash, nopush)
    local qKey = GetQuestKey(qName, qHash)
    if qKey == nil then return end

    local qInst = ALL_QUESTS[qName]
    local qData = self.currentQuests[qKey]

    --if self.inst ~= ThePlayer or not GFGetIsDedicatedNet() then
    if nopush then
        self.classified._gfQSInfoStream:push_string(string.format("%i;%s;%s;0", 
            qInst.id, qHash or '_', qInst:Serialize(self.inst, qData)))
    else
        self.classified._gfQSInfoStream:push_string(string.format("%i;%s;%s", 
            qInst.id, qHash or '_', qInst:Serialize(self.inst, qData)))
    end
    --end
end

-----------------------------------
--unsafe methods-------------------
-----------------------------------

return
{
    AttachClassified = AttachClassified,
    DetachClassified = DetachClassified,
    UpdateQuestList = UpdateQuestList,
    UpdateQuestInfo = UpdateQuestInfo,
}