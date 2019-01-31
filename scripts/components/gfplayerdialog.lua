local ALL_QUESTS = GF.GetQuests()
local QUESTS_IDS = GF.GetQuestsIDs()
local ALL_DIALOGUE_NODES = GF.GetDialogueNodes()
local DIALOGUE_NODES_IDS = GF.GetDialogueNodesIDs()

local function TrackFail(inst)
    inst.components.gfplayerdialog:CloseDialog()
end

local function TrackInterlocutor(inst, interlocutor)
    if not inst:IsValid() or not interlocutor:IsValid() or not inst:IsNear(interlocutor, 15) then
        TrackFail(inst)
    end
end

local GFPlayerDialog = Class(function(self, inst)
    self.inst = inst

    if self.classified == nil and inst.player_classified ~= nil then
        self:AttachClassified(inst.player_classified)
    end

    self.canSpeak = true
    
    self._trackTask = nil
    self._trackInterlocutor = nil
    self._trackQuests = {} --quests
    self._trackNodes = {} --on click events
    --self._trackDialog = {} --info strings

    --self.TrackFail = TrackFail

    inst:ListenForEvent("death", TrackFail)
    inst:ListenForEvent("onremove", TrackFail)
end)

-----------------------------------
--classified methods---------------
-----------------------------------
function GFPlayerDialog:AttachClassified(classified)
    if self.classified ~= nil then return end

    self.classified = classified
    self.ondetachclassified = function() self:DetachClassified() end
    self.inst:ListenForEvent("onremove", self.ondetachclassified, classified)
end

function GFPlayerDialog:DetachClassified()
    self.classified = nil
    self.ondetachclassified = nil
end

-----------------------------------
--conversation methods-------------
-----------------------------------
function GFPlayerDialog:StartConversation(data) --safe
    if data ~= nil then
        self:StopTrack()
        self:PushDialog(data[1], data[2], data[3], data[4])
    end
end

function GFPlayerDialog:StartConversationWith(interlocutor, data, pushQuests) --safe
    if not self.canSpeak or interlocutor == nil or data == nil or interlocutor.components.gfinterlocutor == nil then return false end

    if self._trackInterlocutor ~= interlocutor then
        self:StartTrack(interlocutor, true)
    end

    if pushQuests then
        local quests = (interlocutor.components.gfquestgiver ~= nil)
            and interlocutor.components.gfquestgiver:PickQuests(doer)
            or nil
        if quests ~= nil then
            self:PushDialog(data[1], data[2], quests.offer, quests.complete)
            return
        end
    end

    self:PushDialog(data[1], data[2], data[3], data[4])
end

function GFPlayerDialog:PushDialog(strid, nodes, offer, complete) --UNSAFE, do not use it directly
    self._trackQuests = {}
    self._trackNodes = {}
    --self._trackDialog = {}
    --dialog for a host palyer
    if GFGetPlayer() == self.inst then
        if offer ~= nil and #offer > 0 then
            for i = 1, #offer do
                if ALL_QUESTS[offer[i]] ~= nil then
                    self._trackQuests[offer[i]] = true
                end
            end
        end

        if complete ~= nil and #complete > 0 then
            for i = 1, #complete do
                if ALL_QUESTS[complete[i]] ~= nil then
                    self._trackQuests[complete[i]] = true
                end
            end
        end

        if nodes ~= nil and #nodes > 0 then
            for i = 1, #nodes do
                if ALL_DIALOGUE_NODES[nodes[i]] ~= nil then
                    self._trackNodes[nodes[i]] = true
                end
            end
        end

        self.inst:PushEvent("gfPDChoiseDialog", 
        {
            dString = strid ~= nil and string.upper(strid) or "DEFAULT",
            gQuests = offer or {},
            cQuests = complete or {},
            events = nodes or {},
        })

        --GFDebugPrint("Creating a dialog for host player")
        return true
    end

    if self.classified == nil then return false end

    local str = {strid ~= nil and string.upper(strid) or "DEFAULT"}

    --dialog for clients
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

    if nodes ~= nil and #nodes > 0 then
        for i = 1, #nodes do
            if ALL_DIALOGUE_NODES[nodes[i]] ~= nil then
                self._trackNodes[nodes[i]] = true
                nodes[i] = ALL_DIALOGUE_NODES[nodes[i]].id
            end
        end
        str[4] = table.concat(nodes, ';')
    else
        str[4] = '_'
    end

    str = table.concat(str, '^')
    self.classified._gfPDPushDialog:set_local(str)
    self.classified._gfPDPushDialog:set(str)

    --GFDebugPrint("Creating a dialog for client player")
    return true
end

function GFPlayerDialog:CloseDialog() --safe
    self._trackQuests = {} --quests
    self._trackNodes = {} --on click events
    --self._trackDialog = {} --info strings

    self:StopTrack()

    if self.inst == GFGetPlayer() then
        --GFDebugPrint("Closing a dialog for host player")
        self.inst:PushEvent("gfPDCloseDialog")
    elseif self.classified ~= nil then
        --GFDebugPrint("Closing a dialog for client player")
        self.classified._gfPDCloseDialog:push()
    end
end

function GFPlayerDialog:GetTrackingHash()
    return (self._trackInterlocutor ~= nil) 
        and self._trackInterlocutor.components.gfquestgiver:GetHash()
        or nil
end

function GFPlayerDialog:GetTrackingEntity()
    return self._trackInterlocutor
end

function GFPlayerDialog:CanSpeak()
    return self.canSpeak
end

-----------------------------------------
--track methods--------------------------
-----------------------------------------
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

-----------------------------------------
--network methods------------------------
-----------------------------------------
function GFPlayerDialog:HandleButton(event, name, hash)
    if GFGetIsMasterSim() then
        --event: 0 - close, 1 - dialogue node, 2 - accept a quest, 3 - complete a quest, 4 - abandon a quest
        if event == 0 then
            self:CloseDialog()
        elseif event == 1 then
            local nInst = ALL_DIALOGUE_NODES[name]
            local initiator = self:GetTrackingEntity()

            if self._trackNodes[name]
                and ALL_DIALOGUE_NODES[name] ~= nil
                and nInst:Check(self.inst, initiator)
            then 
                nInst:RunNode(self.inst, initiator)
            else
                GFDebugPrint(string.format("WARNING: %s tries to run impermissible event %s", tostring(self.inst), name)) 
            end
        elseif self.inst.components.gfquestdoer ~= nil then
            if self._trackQuests[name] and ALL_QUESTS[name] ~= nil then
                local giver = self:GetTrackingEntity()
                if event == 2 then
                    --accept quest
                    local giver = self:GetTrackingEntity()
                    if giver ~= nil then
                        if giver.components.gfquestgiver:IsGiverFor(name) then
                            self.inst.components.gfquestdoer:AcceptQuest(name, self:GetTrackingHash())
                            self:CloseDialog()
                        else
                            GFDebugPrint(string.format("WARNING: %s tries to accept quest %s", tostring(self.inst), name)) 
                        end
                    else
                        self.inst.components.gfquestdoer:AcceptQuest(name)
                        self:CloseDialog()
                    end
                elseif event == 3 then
                    --complete quest
                    local giver = self:GetTrackingEntity()
                    if giver ~= nil then
                        if giver.components.gfquestgiver:IsCompleterFor(name) then
                            self.inst.components.gfquestdoer:CompleteQuest(name, self:GetTrackingHash())
                            self:CloseDialog()
                        else
                            GFDebugPrint(string.format("WARNING: %s tries to complete quest %s", tostring(self.inst), name)) 
                        end
                    else
                        self.inst.components.gfquestdoer:CompleteQuest(name)
                        self:CloseDialog()
                    end
                end
            elseif event == 4 then
                --abandon quest
                --actually this is not from this player dialog window, but there is no reason to create a new rpc
                self.inst.components.gfquestdoer:AbandonQuest(name, hash)
            else
                GFDebugPrint(string.format("WARNING: %s tries to run impermissible quest %s", tostring(self.inst), name)) 
            end
        end
    else
        SendModRPCToServer(MOD_RPC["GreenFramework"]["GFDIALOGRPC"], event, name, hash)
    end
end

return GFPlayerDialog