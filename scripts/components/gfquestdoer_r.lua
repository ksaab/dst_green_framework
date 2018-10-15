local ALL_QUESTS = GFQuestList
local QID_TO_NAME = GFQuestIDToName

local function QRStatusChanged(doer, qName, qEvent, giverHash)
    if not GFGetIsDedicatedNet() then
        local self = doer.components.gfquestdoer
        --update quest replica on the client side
        if not GFGetIsMasterSim() and self.currentQuests[qName] ~= nil then
            self.currentQuests[qName].status = qEvent
        end

        --push event
        doer:PushEvent("gfQSInformerPush", {qName = qName, qEvent = qEvent})
    end

    GFDebugPrint(("QDoerReplica: Quest %s has new status %i on %s"):format(qName, qEvent, tostring(doer)))
end

local function QRCreate(doer, qName, qEvent, giverHash)
    if not GFGetIsMasterSim() then
        local self = doer.components.gfquestdoer
        --create a local quest for clients
        if self.currentQuests[qName] == nil then
            self.currentQuests[qName] = {status = 0, giverHash = giverHash}
            ALL_QUESTS[qName]:Accept(doer)
        end
    end

    --push event
    if not GFGetIsDedicatedNet() then
        doer:PushEvent("gfQSInformerPush", {qName = qName, qEvent = qEvent})
    end

    GFDebugPrint(("QDoerReplica: Strating quest %s on %s"):format(qName, tostring(doer)))
end

local function QRRemove(doer, qName, qEvent, giverHash)
    local self = doer.components.gfquestdoer
    --remove a local quest for clients
    if not GFGetIsMasterSim() then
        self.currentQuests[qName] = nil
    end

    --push event
    if not GFGetIsDedicatedNet() and qEvent == 4 then
        doer:PushEvent("gfQSInformerPush", {qName = qName, qEvent = qEvent})
    end

    GFDebugPrint(("QDoerReplica: Removing quest %s from %s"):format(qName, tostring(doer)))
end

local function QRCooldown(doer, qName, qEvent)
    
    --remove a local quest for clients
    if not GFGetIsMasterSim() then
        local self = doer.components.gfquestdoer
        self.completedQuests[qName] = qEvent == 8 and 1 or nil
    end

    GFDebugPrint(("QDoerReplica: %s cooldown changed for %s"):format(qName, tostring(doer)))
end

local function DeserealizeEventStream(classified)
    if classified._parent == nil then return end

    ------------------------------------------------------------------
    --what's going on:
    ------------------------------------------------------------------
    --string format:    ID;GIVER_HASH;EVENT^ID;GIVER_HASH;EVENT^etc...
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

    local dataArr = classified._gfQSEventStream:value():split('^')
    local self = classified._parent.components.gfquestdoer

    for _, qData in pairs(dataArr) do
        local qArr = qData:split(';')
        if #qArr == 3 then --don't want to process if the string is wrong
            local qName = QID_TO_NAME[tonumber(qArr[1])]
            if qName ~= nil then
                local qEvent = tonumber(qArr[3])
                if qEvent <= 2 then
                    QRStatusChanged(classified._parent, qName, qEvent, qArr[2])
                elseif qEvent == 3 then
                    QRCreate(classified._parent, qName, qEvent, qArr[2])
                elseif qEvent == 4 or qEvent == 5 then
                    QRRemove(classified._parent, qName, qEvent, qArr[2])
                elseif qEvent == 8 or qEvent == 9 then
                    QRCooldown(classified._parent, qName, qEvent)
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

    local dataArr = classified._gfQSInfoStream:value():split('^')
    local self = classified._parent.components.gfquestdoer

    for _, qData in pairs(dataArr) do
        local qArr = qData:split(';')
        if #qArr == 3 or #qArr == 4 then --don't want to process if the string is wrong
            local qName = QID_TO_NAME[tonumber(qArr[1])]
            if qName ~= nil and self.currentQuests[qName] ~= nil then
                local qInst = ALL_QUESTS[qName]
                if not GFGetIsMasterSim() then
                    qInst:Deserialize(classified._parent, qArr[3])
                end

                if qArr[4] == nil then
                    if not GFGetIsDedicatedNet() then
                        classified._parent:PushEvent("gfQSInformerPush", {qName = qName})
                    end
                end
            end
        end
    end
end

local function DeserealizeInformerStream(classified)
    if classified._parent == nil then return end
    -- need to delay execution to keep in sync with DeserealizeEventStream result
    classified:DoTaskInTime(0, DoDeserealizeInformerStream)
end

local function DeserealizeOfferString(classified)
    if classified._parent == nil then return end

    --what's going on:
    --------------------------------------------------------------------------------------------------------
    --string format:    QUEST1ID;QUEST2ID;etc^QUEST1ID;QUEST2ID;etc^STRINGID
    --                  new quests           |completed            |string for a dialog
    --------------------------------------------------------------------------------------------------------

    local dataArr = classified._gfQSOfferString:value():split('^')
    local self = classified._parent.components.gfquestdoer

    local giveArr, compArr = {}, {}
    if dataArr[1] ~= '0' then
        --giveArr = {}
        local tmp = dataArr[1]:split(';')
        for i = 1, #tmp do
            local qName = QID_TO_NAME[tonumber(tmp[i])]
            if qName ~= nil then
                table.insert(giveArr, qName)
            else
                GFDebugPrint("Invalid quest ID", tmp[i])
            end
        end
    end

    if dataArr[2] ~= '0' then
        --compArr = {}
        local tmp = dataArr[2]:split(';')
        for i = 1, #tmp do
            local qName = QID_TO_NAME[tonumber(tmp[i])]
            if qName ~= nil then
                table.insert(compArr, qName)
            else
                GFDebugPrint("Invalid quest ID", tmp[i])
            end
        end
    end

    --if (giveArr == nil or #giveArr == 0) and (compArr == nil or #compArr == 0) then
    if #giveArr == 0 and #compArr == 0 then
        GFDebugPrint("QDoerR: got line but don't have any quests!")
        return
    end

    classified._parent:PushEvent("gfQSChoiseDialogPush", 
        {
            dString = dataArr[3], 
            gQuests = giveArr,
            cQuests = compArr,
        })
end

local function DeserealizeCompleteString(classified)
    if classified._parent == nil then return end

    local qName = classified._gfQSCompleteString:value()
    if ALL_QUESTS[qName] ~= nil then
        classified._parent:PushEvent("gfQSCompleteDialogPush", {qName = qName})
    end
end

local function PushCloseDialog(classified)
    if classified._parent == nil then return end
    classified._parent:PushEvent("gfQSCloseDialogPush")
end

------------------------
--methods---------------
------------------------
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
        self.inst:ListenForEvent("gfQSOfferDirty", DeserealizeOfferString, classified)
        self.inst:ListenForEvent("gfQSEventCDialogDirty", PushCloseDialog, classified)
        self.inst:ListenForEvent("gfQSCompleteDirty", DeserealizeCompleteString, classified)
    end
end

local function DetachClassified(self)
    --default things, like in the others replicatable components
    self.classified = nil
    self.ondetachclassified = nil
end

local function UpdateQuestList(self, qName, status)
    if self.inst ~= ThePlayer or not GFGetIsDedicatedNet() then
        self.classified._gfQSEventStream:push_string(string.format("%i;%s;%i", 
            ALL_QUESTS[qName].id, self.currentQuests[qName].giverHash, status or self.currentQuests[qName].status))
    end

    --if status == 5 then
    ---    self.classified._gfQSCompleteString:set_local(qName)
    --    self.classified._gfQSCompleteString:set(qName)
    --end
end

local function UpdateQuestInfo(self, qName, nopush)
    local qInst = ALL_QUESTS[qName]
    local qData = self.currentQuests[qName]

    if self.inst ~= ThePlayer or not GFGetIsDedicatedNet() then
        if nopush then
            self.classified._gfQSInfoStream:push_string(string.format("%i;%s;%s;0", 
                qInst.id, qData.giverHash, qInst:Serialize(self.inst)))
        else
            self.classified._gfQSInfoStream:push_string(string.format("%i;%s;%s", 
                qInst.id, qData.giverHash, qInst:Serialize(self.inst)))
        end
    end
end

local function CreateQuestDialog(self, quests, strid)
    if not GFGetIsMasterSim() or quests == nil then return false end

    local qGive = {} 
    local qPass = {}
    if quests ~= nil then
        for i = 1, #quests do
            local qName = quests[i]
            if ALL_QUESTS[qName] ~= nil then 
                if self.currentQuests[qName] ~= nil then 
                    --players has a quest, need to check is the quest done or not
                    if self.currentQuests[qName].status == 1 then
                        --player can complete the quest
                        table.insert(qPass, tostring(ALL_QUESTS[qName].id))
                    end
                else
                    --player doesn't have the quest, need to check cooldown for it
                    if self.completedQuests[qName] == nil and ALL_QUESTS[qName]:CheckBeforeGive(self.inst) then
                        --player can take the quest
                        table.insert(qGive, tostring(ALL_QUESTS[qName].id))
                    end
                end
            else
                GFDebugPrint("Offering invalid quest (give)", quests[i])
            end
        end
    end

    if #qGive < 1 and #qPass < 1 then return false end --there are no quests to push to the player

    local str = {}

    table.insert(str, #qGive ~= 0 and table.concat(qGive, ';') or '0')
    table.insert(str, #qPass ~= 0 and table.concat(qPass, ';') or '0')
    if strid ~= nil then
        table.insert(str, strid)
    end

    str = table.concat(str, '^')
    self.classified._gfQSOfferString:set_local(str)
    self.classified._gfQSOfferString:set(str)

    return true
end

local function PushCooldown(self, qName, state)
    if qName == nil or ALL_QUESTS[qName] == nil then return end

    state = state == true and 8 or 9
    local val = string.format("%i;_;%i", ALL_QUESTS[qName].id, state)

    self.classified._gfQSEventStream:push_string(val)
end

local function HandleButtonClick(self, qName, event)
    if GFGetIsMasterSim() then
        if event == 0 then
            self:AcceptQuest(qName)
        elseif event == 1 then
            self:StopTrackGiver()
        elseif event == 2 then
            self:AbandonQuest(qName)
        elseif event == 3 then
            self:CompleteQuest(qName)
        end
    else
        SendModRPCToServer(MOD_RPC["GreenFramework"]["GFQUESTRPC"], event, qName or "_")
    end
end

return 
{
    AttachClassified = AttachClassified,
    DetachClassified = DetachClassified,
    UpdateQuestList = UpdateQuestList,
    UpdateQuestInfo = UpdateQuestInfo,
    HandleButtonClick = HandleButtonClick,
    CreateQuestDialog = CreateQuestDialog,
    PushCooldown = PushCooldown,
}