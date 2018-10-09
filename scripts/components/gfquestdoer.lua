local allQuests = GFQuestList

--client methods
local function QuestPushedDirty(classified)
    if classified._parent == nil then return end

    local qName = classified._pushQuest:value()
    classified._parent:PushEvent("gfquestpush", {qName = qName})
end

local function QuestCompletedDirty(classified)
    if classified._parent == nil then return end

    local qName = classified._completeQuest:value()
    classified._parent:PushEvent("gfquestcomplete", {qName = qName})
end

local function ForceCloseDialog(classified)
    if classified._parent == nil then return end
    classified._parent:PushEvent("gfquestclosedialog")
end

local function QuestShowInfo(classified)
    if classified._parent == nil then return end
    local strings = classified._infoLine:value():split(';')
    classified._parent:PushEvent("gfquestshowinfo", {qName = strings[1], qString = strings[2]})
end

local function UpdateCurrQuestsList(classified)
    if classified._parent == nil then return end
    local strings = classified._currQuestsList:value():split(';')
    local self = classified._parent.components.gfquestdoer

    self.currentQuests = {}
    for k, v in pairs(strings) do
        local q = v:split("^")
        print(q[1], q[2])
        self.currentQuests[q[1]] = 
        {
            done = (q[2] ~= nil and tonumber(q[2]) == 1)
        }
    end
end

local function DeserealizeNoticeStream(classified)
    if classified._parent == nil then return end

    local strings = classified._questNoticeStream:value():split('^')
    local self = classified._parent.components.gfquestdoer

    for k, v in pairs(strings) do
        print(k .. ": " .. v)
    end
end

--server methods
local function TrackGiverFail(inst)
    inst.components.gfquestdoer:StopTrackGiver()

    if inst.player_classified ~= nil then
        if inst == GFGetPlayer() and not GFGetIsDedicatedNet() then
            inst:PushEvent("gfquestclosedialog")
        else
            inst.player_classified._forceCloseDialog:push()
        end
    end
end

local function TrackGiver(inst, giver)
    if not inst:IsValid() or not giver:IsValid() or not inst:IsNear(giver, 15) then
        TrackGiverFail(inst)
    end
end

local function ResetQuests(self)
    for qName, rTime in pairs(self.completedQuests) do
        if rTime ~= math.huge and rTime - GetTime() <= 0 then
            self.completedQuests[qName] = nil
        end
    end
end

local GFQuestDoer = Class(function(self, inst)
    self.inst = inst

    self.currentQuests = {}
    self.completedQuests = {}

    self.currQuestsList = ""

    --attaching classified on the server-side
    if GFGetIsMasterSim() and inst.player_classified ~= nil then
        self.classified = inst.player_classified
    end

    self._questGiver = nil
    self._trackTask = nil

    self:WatchWorldState("cycles", ResetQuests)
    inst:ListenForEvent("death", TrackGiverFail)
end)

--attaching classified on the client-side
function GFQuestDoer:AttachClassified(classified)
    if self.classified ~= nil then return end

    self.classified = classified
    --default things, like in the others replicatable components
    self.ondetachclassified = function() self:DetachClassified() end
    self.inst:ListenForEvent("onremove", self.ondetachclassified, classified)

    if not GFGetIsMasterSim() then 
        --collecting events directly from the classified prefab
        self.inst:ListenForEvent("gfquestpushdirty", QuestPushedDirty, classified)
        self.inst:ListenForEvent("gfquestcompletedirty", QuestCompletedDirty, classified)
        self.inst:ListenForEvent("gfquestclosedialogdirty", ForceCloseDialog, classified)
        self.inst:ListenForEvent("gfquestinfodirty", QuestShowInfo, classified)
        self.inst:ListenForEvent("gfquestlistdirty", UpdateCurrQuestsList, classified)

        self.inst:ListenForEvent("gfqueststreamdirty", DeserealizeNoticeStream, classified)
    end
end

function GFQuestDoer:DetachClassified()
    --default things, like in the others replicatable components
    self.classified = nil
    self.ondetachclassified = nil
end

--server-client interface
function GFQuestDoer:OfferQuest(qName)
    if not GFGetIsMasterSim() then return end

    if self.classified ~= nil then
        if self.inst == GFGetPlayer() and not GFGetIsDedicatedNet() then
            --refresh recharge-watcher on the host-side
            self.inst:PushEvent("gfquestpush", {qName = qName})
        else
            --sending information about current spells to the client
            --sending string which contains all spells enumerated with a separator
            self.classified._pushQuest:set_local(qName)
            self.classified._pushQuest:set(qName)
        end
    else
        GFDebugPrint(string.format("GFQuestDoer: something wrong %s doesn't have classified field", tostring(self.inst)))
    end
end

--server-client interface
function GFQuestDoer:AcceptQuest(qName)
    if not GFGetIsMasterSim() then return end

    local quest = allQuests[qName]
    if quest then
        self.currentQuests[qName] = {}
        self.currentQuests[qName].done = false
        quest:OnAccept(self.inst, self._questGiver)

        if self._questGiver ~= nil then
            self._questGiver.components.gfquestgiver:QuestAccepted(qName, self.inst)
        end

        self:UpdateCurrentQuestsList()
        self:StopTrackGiver()
    end
end

--server-client interface
function GFQuestDoer:CompleteQuest(qName, giver)
    if not GFGetIsMasterSim() then return end

    local quest = allQuests[qName]
    if quest then
        quest:OnComplete(self.inst, giver)
        self.currentQuests[qName] = nil

        if not quest.repeatable then
            self.completedQuests[qName] = quest.cooldown ~= 0 and GetTime() + quest.cooldown or math.huge
        end

        if giver ~= nil then
            giver.components.gfquestgiver:QuestCompleted(qName, self.inst)
        end

        if self.classified ~= nil then
            if self.inst == GFGetPlayer() and not GFGetIsDedicatedNet() then
                --refresh recharge-watcher on the host-side
                self.inst:PushEvent("gfquestcomplete", {qName = qName})
            else
                --sending information about current spells to the client
                --sending string which contains all spells enumerated with a separator
                self.classified._completeQuest:set_local(qName)
                self.classified._completeQuest:set(qName)
                self:UpdateCurrentQuestsList()
            end
        else
            GFDebugPrint(string.format("GFQuestDoer: something wrong %s doesn't have classified field", tostring(self.inst)))
        end
    end
end

function GFQuestDoer:CancelQuest(qName)
    if GFGetIsMasterSim() then 
        if allQuests[qName] ~= nil then
            allQuests[qName]:OnCancel(self.inst)
        end
        self.currentQuests[qName] = nil
        if self.inst ~= GFGetPlayer() or GFGetIsDedicatedNet() then
            self:UpdateCurrentQuestsList()
        end
    elseif qName ~= nil then
        SendModRPCToServer(MOD_RPC["GreenFramework"]["GFCANCELQUEST"], qName)
    end
end

--server-client interface
function GFQuestDoer:SetQuestStatus(qName, qString)
    qName = qName or "NO DATA" 
    qString = tostring(qString or "NO DATA")

    if self.classified ~= nil then
        if self.inst == GFGetPlayer() and not GFGetIsDedicatedNet() then
            --push data to informer for game's host
            GFDebugPrint(qName .. qString)
            self.inst:PushEvent("gfquestshowinfo", {qName = qName, qString = qString})
        else
            --push data to informer for clients
            local str = string.format("%s;%s", qName, qString)
            self.classified._infoLine:set_local(str)
            self.classified._infoLine:set(str)

            self.classified._questNoticeStream:push_string(str)
        end
    else
        GFDebugPrint(string.format("GFQuestDoer: something wrong %s doesn't have classified field", tostring(self.inst)))
    end
end

--server-client interface
function GFQuestDoer:UpdateCurrentQuestsList()
    if not GFGetIsMasterSim() then return end

    if self.classified ~= nil then
        
        if self.inst ~= GFGetPlayer() or GFGetIsDedicatedNet() then
            --refresh recharge-watcher on the host-side
            local str = {}
            for qName, qData in pairs(self.currentQuests) do
                table.insert(str, qName .. (qData.done == true and "^1" or "^0"))
            end
            
            print("UpdateCurrentQuestsList")
            self.classified._currQuestsList:set(table.concat(str, ";"))
        end
    else
        GFDebugPrint(string.format("GFQuestDoer: something wrong %s doesn't have classified field", tostring(self.inst)))
    end
end

function GFQuestDoer:QuestDone(qName, val, qString)
    self.currentQuests[qName].done = val
    if self.classified ~= nil then
        if qString == nil then
            qString = val and "quest done!" or "conditions are no longer met."
        end
        if self.inst == GFGetPlayer() and not GFGetIsDedicatedNet() then
            --push data to informer for game's host
            GFDebugPrint(qName .. tostring(qString))
            self.inst:PushEvent("gfquestshowinfo", {qName = qName, qString = qString})
        else
            --push data to informer for clients
            local str = string.format("%s;%s", qName, qString)
            self.classified._infoLine:set_local(str)
            self.classified._infoLine:set(str)
            self:UpdateCurrentQuestsList()
        end
    else
        GFDebugPrint(string.format("GFQuestDoer: something wrong %s doesn't have classified field", tostring(self.inst)))
    end
end

function GFQuestDoer:ResetAllQuests(qName)
    self.completedQuests[qName] = {}
end

function GFQuestDoer:CleanUpQuest(qName)
    if self.completedQuests[qName] ~= nil 
        and self.completedQuests[qName] ~= math.huge
        and self.completedQuests[qName] - GetTime() <= 0
    then
        self.completedQuests[qName] = nil
    end
end

function GFQuestDoer:CheckQuest(qName)
    if not GFGetIsMasterSim() then return end
    self:CleanUpQuest(qName)

    return self.currentQuests[qName] == nil and self.completedQuests[qName] == nil
end

function GFQuestDoer:TrackGiver(giver)
    self:StopTrackGiver()
    self._questGiver = giver

    --checking distance
    self._trackTask = self.inst:DoPeriodicTask(0.5, TrackGiver, nil, giver)
    --and listening for combat events
    self.inst:ListenForEvent("attacked", TrackGiverFail, self._questGiver)
    self.inst:ListenForEvent("death", TrackGiverFail, self._questGiver)
    self.inst:ListenForEvent("newtarget", TrackGiverFail, self._questGiver)

    GFDebugPrint(("%s has started tracking %s"):format(tostring(self.inst), tostring(self._questGiver)))
end

function GFQuestDoer:StopTrackGiver()
    if self._questGiver == nil then return end

    self.inst:RemoveEventCallback("attacked", TrackGiverFail, self._questGiver)
    self.inst:RemoveEventCallback("death", TrackGiverFail, self._questGiver)
    self.inst:RemoveEventCallback("newtarget", TrackGiverFail, self._questGiver)

    if self._trackTask ~= nil then
        self._trackTask:Cancel()
        self._trackTask = nil
    end

    GFDebugPrint(("%s has stopped tracking %s"):format(tostring(self.inst), tostring(self._questGiver)))
    self._questGiver = nil
end

function GFQuestDoer:GetQuestsNumber()
    return GetTableSize(self.currentQuests)
end

function GFQuestDoer:OnSave()
    if not GFGetIsMasterSim() then return end

    local savedata = 
    {
        completedQuests = {},
        questsInProgress = {},
    }

    local currTime = GetTime()

    for qName, qTime in pairs(self.completedQuests) do
        savedata.completedQuests[qName] = qTime ~= math.huge and qTime - currTime or qTime
    end

    for qName, qData in pairs(self.currentQuests) do
        if qData ~= nil then
            local tmp = allQuests[qName]:OnSave(self.inst, qData)
            if tmp then
                savedata.questsInProgress[qName] = tmp
            end
        end
    end

    return {savedata = savedata}
end

function GFQuestDoer:OnLoad(data)
    if not GFGetIsMasterSim() or not data or not data.savedata then return end

    if data.savedata.completedQuests then
        local cQuests = data.savedata.completedQuests
        local currTime = GetTime()
        for qName, qTime in pairs(cQuests) do
            self.completedQuests[qName] = currTime - qTime
        end
    end

    if data.savedata.questsInProgress then
        local cQuests = data.savedata.questsInProgress
        for qName, qData in pairs(cQuests) do
            self:AcceptQuest(qName)
            allQuests[qName]:OnLoad(self.inst, qData)
        end
    end
end

function GFQuestDoer:GetDebugString()
    local give = {}
    local pass = {}

    for k, v in pairs(self.currentQuests or {}) do
        table.insert(give, k)
    end

    for k, v in pairs(self.completedQuests or {}) do
        table.insert(pass, string.format("%s:%i", k, v ~= math.huge and v - GetTime() or 0))
    end

    return (#give > 0 or #pass > 0)
        and string.format("current:[%s]; passed:[%s]", table.concat(give, ", "), table.concat(pass, ", ")) 
        or "none"
end


return GFQuestDoer