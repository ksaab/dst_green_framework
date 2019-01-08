local ALL_QUESTS = GF.GetQuests()
local QUESTS_IDS = GF.GetQuestsIDs()
local ALL_DIALOGUE_NODES = GF.GetDialogueNodes()
local DIALOGUE_NODES_IDS = GF.GetDialogueNodesIDs()

local function DeserealizeDialogStrings(classified)
    if classified._parent == nil then return end

    --print("Deserelizing", classified._gfPDPushDialog:value())
    local strArr = classified._gfPDPushDialog:value():split('^')

    --strArr[1] - dialog string
    --strArr[2] - offered quests
    --strArr[3] - completable quests
    --strArr[4] - events (handled by click)
    --strArr[5] - string (no handle, just info)

    local offer, complete, events, strings = {}, {}, {}, {}

    if strArr[2] ~= '_' then
        for k, qID in pairs(strArr[2]:split(';')) do
            local qName = QUESTS_IDS[tonumber(qID)]
            if qName ~= nil then table.insert(offer, qName) end
        end
    end

    if strArr[3] ~= '_' then
        for k, qID in pairs(strArr[3]:split(';')) do
            local qName = QUESTS_IDS[tonumber(qID)]
            if qName ~= nil then table.insert(complete, qName) end
        end
    end

    if strArr[4] ~= '_' then
        for k, deid in pairs(strArr[4]:split(';')) do
            local deName = DIALOGUE_NODES_IDS[tonumber(deid)]
            if deName ~= nil then table.insert(events, deName) end
        end
    end

    classified._parent:PushEvent("gfPDChoiseDialog", 
        {
            dString = strArr[1], 
            gQuests = offer,
            cQuests = complete,
            events = events,
        })
end

local function  CloseDialogDirty(classified)
    if classified._parent ~= nil then classified._parent:PushEvent("gfPDCloseDialog") end
end

local function TrackInterlocutor(inst, interlocutor)
    if not inst:IsValid() or not interlocutor:IsValid() or not inst:IsNear(interlocutor, 15) then
        inst.components.gfplayerdialog.TrackFail()
    end
end

local GFPlayerDialog = Class(function(self, inst)
    self.inst = inst

    --attaching classified on the server-side
    if self.classified == nil and inst.player_classified ~= nil then
        self:AttachClassified(inst.player_classified)
    end
    
    self._trackTask = nil
    self._trackInterlocutor = nil
    self._trackQuests = {} --quests
    self._trackEvents = {} --on click events
    self._trackDialog = {} --info strings

    self.TrackFail = function()
        inst.components.gfplayerdialog:StopTrack()
    
        if inst.player_classified ~= nil then
            if inst == GFGetPlayer() and not GFGetIsDedicatedNet() then
                inst:PushEvent("gfPDCloseDialog")
            else
                inst.player_classified._gfPDCloseDialog:push()
            end
        end
    end
end)

-----------------------------------
--classified methods---------------
-----------------------------------
function GFPlayerDialog:AttachClassified(classified)
    if self.classified ~= nil then return end

    self.classified = classified
    --default things, like in the others replicatable components
    self.ondetachclassified = function() self:DetachClassified() end
    self.inst:ListenForEvent("onremove", self.ondetachclassified, classified)

    --collecting events directly from the classified prefab
    if not GFGetIsMasterSim() then 
        
    end

    if not GFGetIsDedicatedNet() then
        self.inst:ListenForEvent("gfPDPushDialogDirty", DeserealizeDialogStrings, classified)
        self.inst:ListenForEvent("gfPDCloseDialogDirty", CloseDialogDirty, classified)
    end
end

function GFPlayerDialog:DetachClassified()
    --default things, like in the others replicatable components
    self.classified = nil
    self.ondetachclassified = nil
end

-----------------------------------
--safe methods---------------------
-----------------------------------
function GFPlayerDialog:StartConversationWith(interlocutor, data)
    if not GFGetIsMasterSim() then return false end
    if interlocutor == nil or data == nil or interlocutor.components.gfinterlocutor == nil then return false end

    self:StartTrack(interlocutor, true)
    self:PushDialog(data[1], data[2], data[3], data[4])--(unpack(data))
end

function GFPlayerDialog:PushDialog(strid, events, offer, complete)--, strings)
    if not GFGetIsMasterSim() then return false end

    self._trackQuests = {}
    self._trackEvents = {}
    self._trackDialog = {}
    local str = {strid ~= nil and string.upper(strid) or "DEFAULT"}

    if offer ~= nil and #offer > 0 then
        for i = 1, #offer do
            self._trackQuests[offer[i]] = true
            offer[i] = ALL_QUESTS[offer[i]].id
        end
        str[2] = table.concat(offer, ';')
    else
        str[2] = '_'
    end

    if complete ~= nil and #complete > 0 then
        for i = 1, #complete do
            self._trackQuests[complete[i]] = true
            complete[i] = ALL_QUESTS[complete[i]].id
        end
        str[3] = table.concat(complete, ';')
    else
        str[3] = '_'
    end

    if events ~= nil and #events > 0 then
        for i = 1, #events do
            if ALL_DIALOGUE_NODES[events[i]] ~= nil then
                self._trackEvents[events[i]] = true
                events[i] = ALL_DIALOGUE_NODES[events[i]].id
            end
        end
        str[4] = table.concat(events, ';')
    else
        str[4] = '_'
    end

    --str[5] = (strings ~= nil and #strings > 0)      and table.concat(strings, ';')     or '_'

    str = table.concat(str, '^')
    self.classified._gfPDPushDialog:set_local(str)
    self.classified._gfPDPushDialog:set(str)

    return true
end

function GFPlayerDialog:TrackFail()
    inst.components.gfplayerdialog:StopTrack()

    if inst.player_classified ~= nil then
        if inst == GFGetPlayer() and not GFGetIsDedicatedNet() then
            inst:PushEvent("gfPDCloseDialog")
        else
            inst.player_classified._gfPDCloseDialog:push()
        end
    end
end

function GFPlayerDialog:CloseDialog()
    self._trackQuests = {} --quests
    self._trackEvents = {} --on click events
    self._trackDialog = {} --info strings
    self:StopTrack()
end

function GFPlayerDialog:GetTrackingHash()
    return (self._trackInterlocutor ~= nil) 
        and self._trackInterlocutor.components.gfquestgiver:GetHash()
        or nil
end

function GFPlayerDialog:GetTrackingEntity()
    return self._trackInterlocutor
end

-----------------------------------------
--unsafe methods-------------------------
-----------------------------------------
function GFPlayerDialog:HandleEventButton(event)
    if GFGetIsMasterSim() then
        local deInst = ALL_DIALOGUE_NODES[event]
        local initiator = self:GetTrackingEntity()
        if self._trackEvents[event] ~= nil and deInst ~= nil then
            self:CloseDialog()
            if deInst:Check(self.inst, initiator) then
                if deInst.global then
                    GFGetWorld():PushEvent("gfrunevent", {event = event, actor = self.inst, initiator = giver})
                elseif initiator ~= nil then
                    deInst:RunNode(self.inst, initiator)
                end
            else
                GFDebugPrint(string.format("Warning %s failed check for %s",
                    tostring(self.inst), event))
            end
        else
            self:CloseDialog()
            GFDebugPrint(string.format("Warning %s tries to run invalid or impermissible event %s",
                tostring(self.inst), event))
        end
    else
        SendModRPCToServer(MOD_RPC["GreenFramework"]["GFEVENTRPC"], event)
    end
end

function GFPlayerDialog:HandleQuestButton(event, qName, hash)
    if GFGetIsMasterSim() then
        self:HandleQuestRPC(event, qName, hash)
    else
        SendModRPCToServer(MOD_RPC["GreenFramework"]["GFQUESTRPC"], event, qName, hash)
    end
end

function GFPlayerDialog:HandleQuestRPC(event, qName, hash)
    --print("handling rpc", event, qName, hash, self:GetTrackingHash())
     ------------------------
    --events:
    --0 - accept a quest
    --1 - close dialog
    --2 - abandon a quest
    --3 - complete 
    ------------------------
    if event == 1 then
        self:CloseDialog()
    elseif qName ~= nil then
        if event == 0 then
            if self._trackQuests[qName] then
                local giver = GFPlayerDialog:GetTrackingEntity()
                if giver == nil 
                    or giver.components.gfquestgiver == nil 
                    or giver.components.gfquestgiver:IsGiverFor(qName)
                then
                    self.inst.components.gfquestdoer:AcceptQuest(qName, self:GetTrackingHash())
                end
                self:CloseDialog()
            end
        elseif event == 3 then
            if self._trackQuests[qName] then
                local giver = GFPlayerDialog:GetTrackingEntity()
                if giver == nil 
                    or giver.components.gfquestgiver == nil 
                    or giver.components.gfquestgiver:IsCompleterFor(qName)
                then
                    self.inst.components.gfquestdoer:CompleteQuest(qName, self:GetTrackingHash())
                end
                self:CloseDialog()
            end
        elseif event == 2 then
            self.inst.components.gfquestdoer:AbandonQuest(qName, hash)
        end
    end
end

function GFPlayerDialog:StartTrack(interlocutor, checkDistance)
    self:StopTrack()
    if interlocutor == nil or interlocutor.components.gfinterlocutor == nil then return false end

    self._trackInterlocutor = interlocutor
    interlocutor.components.gfinterlocutor:SetListeners(self.inst)

    if checkDistance then
        self._trackTask = self.inst:DoPeriodicTask(0.5, TrackInterlocutor, nil, interlocutor)
    end

    --GFDebugPrint(("%s has started tracking %s"):format(tostring(self.inst), tostring(self._trackInterlocutor)))
    return true
end

function GFPlayerDialog:StopTrack()
    if self._trackInterlocutor == nil then return end

    self._trackInterlocutor.components.gfinterlocutor:RemoveListeners()

    if self._trackTask ~= nil then
        self._trackTask:Cancel()
        self._trackTask = nil
    end

    --GFDebugPrint(("%s has stopped tracking %s"):format(tostring(self.inst), tostring(self._trackInterlocutor)))
    self._trackInterlocutor = nil
end

return GFPlayerDialog