local ALL_QUESTS = GFQuestList
local QID_TO_NAME = GFQuestIDToName

local _r = require "components/gfquestdoer_r"

--[[ local function TrackGiverFail(inst)
    inst.components.gfquestdoer:StopTrackGiver()

    if inst.player_classified ~= nil then
        if inst == GFGetPlayer() and not GFGetIsDedicatedNet() then
            inst:PushEvent("gfQSCloseDialogPush")
        else
            inst.player_classified._gfQSCloseDialogEvent:push()
        end
    end
end ]]

local function TrackGiver(inst, giver)
    if not inst:IsValid() or not giver:IsValid() or not inst:IsNear(giver, 15) then
        inst.components.gfquestdoer.TrackGiverFail()
    end
end

local function ResetQuests(self)
    local needToUpdate = false
    for qName, rTime in pairs(self.completedQuests) do
        if rTime ~= -1  then
            self.completedQuests[qName] = self.completedQuests[qName] - 1
            if self.completedQuests[qName] == 0 then
                needToUpdate = true
                self.completedQuests[qName] = nil
                self:PushCooldown(qName, false)
                --GFDebugPrint(("Cooldown on quest %s is ended for %s"):format(qName, tostring(self.inst)))
            end
        end
    end
end

local GFQuestDoer = Class(function(self, inst)
    self.inst = inst

    self.currentQuests = {}
    self.completedQuests = {}

    --attaching classified on the server-side
    if self.classified == nil and inst.player_classified ~= nil then
        self:AttachClassified(inst.player_classified)
    end
    
    self._questGiver = nil
    self._questTracker = {}
    self._trackTask = nil
    self._offeredQuest = nil

    self.TrackGiverFail = function()
        inst.components.gfquestdoer:StopTrackGiver()
    
        if inst.player_classified ~= nil then
            if inst == GFGetPlayer() and not GFGetIsDedicatedNet() then
                inst:PushEvent("gfQSCloseDialogPush")
            else
                inst.player_classified._gfQSCloseDialogEvent:push()
            end
        end
    end

    if GFGetIsMasterSim() then
        self:WatchWorldState("cycles", ResetQuests)
        inst:ListenForEvent("death", self.TrackGiverFail)
    end
end)

function GFQuestDoer:OfferQuests(quests, strid, giver)
    if self:CreateQuestDialog(quests, strid, giver) then
        if giver ~= nil and not self:TrackGiver(giver) then 
            --GFDebugPrint("Can't track giver", tostring(giver))
            return
        end
        for _, v in pairs(quests) do
            self._questTracker[v] = true
        end
    else
        --GFDebugPrint("Nothing to offer")
    end
end

function GFQuestDoer:OfferQuest(qName, strid, giver)
    self:OfferQuests({qName}, strid, giver)
end

function GFQuestDoer:AcceptQuest(qName)
    if not GFGetIsMasterSim() or ALL_QUESTS[qName] == nil or self.currentQuests[qName] ~= nil then return end

    local giverHash
    if self._questGiver ~= nil then
        giverHash = self._questGiver.components.gfquestgiver:GetHash()
    end

    local _q = ALL_QUESTS[qName]
    self.currentQuests[qName] = 
    {
        status = 0,
        giverHash = giverHash or '0',
    }

    --updaing quest list on the cleint-side
    self:UpdateQuestList(qName, 3)
    _q:Accept(self.inst) --register quest's events

    if self._questGiver ~= nil then
        self._questGiver.components.gfquestgiver:OnQuestAccepted(qName, self.inst)
    end

    self:StopTrackGiver() --don't need to track a giver anymore
end

function GFQuestDoer:CompleteQuest(qName)
    if not GFGetIsMasterSim() or ALL_QUESTS[qName] == nil then return end

    if not self:IsQuestDone(qName)
        or not ALL_QUESTS[qName]:CheckBeforeComplete(self.inst) 
    then
        --GFDebugPrint(string.format("%s can't complete the quest %s", tostring(self.inst), qName))
        return false
    end

    local _q = ALL_QUESTS[qName]
    _q:Complete(self.inst, self._questGiver) --unregister quest's events and run a reward fn

    --set a cooldown for the quest if needed
    if _q.norepeat then
        self.completedQuests[qName] = -1
        self:PushCooldown(qName, true)
    elseif _q.cooldown > 0 then
        self.completedQuests[qName] = _q.cooldown
        self:PushCooldown(qName, true)
    end

    --updaing quest list on the cleint-side
    self:UpdateQuestList(qName, 5)
    self.currentQuests[qName] = nil

    if self._questGiver ~= nil then
        self._questGiver.components.gfquestgiver:OnQuestCompleted(qName, self.inst)
    end

    self:StopTrackGiver()

    return true
end

function GFQuestDoer:AbandonQuest(qName)
    if not GFGetIsMasterSim() then return end

    --unregistering quest's events
    if ALL_QUESTS[qName] ~= nil then
        ALL_QUESTS[qName]:Abandon(self.inst)
    end

    --updaing quest list on the cleint-side
    self:UpdateQuestList(qName, 4)
    self.currentQuests[qName] = nil
end

function GFQuestDoer:SetQuestDone(qName, done)
    local status = (done == nil or done == false) and 0 or 1
    --print(qName .. "now has status " .. tostring(status))
    if self.currentQuests[qName].status ~= status then
        self.currentQuests[qName].status = status
        self:UpdateQuestInfo(qName, done)
        self:UpdateQuestList(qName, status)
    end
end

function GFQuestDoer:SetQuestFailed(qName)
    if self.currentQuests[qName].status ~= 2 then
        self.currentQuests[qName].status = 2
        self:UpdateQuestInfo(qName, true)
        self:UpdateQuestList(qName, 2)
    end
end

GFQuestDoer.AttachClassified = _r.AttachClassified
GFQuestDoer.DetachClassified = _r.DetachClassified
GFQuestDoer.UpdateQuestList = _r.UpdateQuestList
GFQuestDoer.UpdateQuestInfo = _r.UpdateQuestInfo
GFQuestDoer.HandleButtonClick = _r.HandleButtonClick
GFQuestDoer.CreateQuestDialog = _r.CreateQuestDialog
GFQuestDoer.HandleButtonClick = _r.HandleButtonClick
GFQuestDoer.PushCooldown = _r.PushCooldown

function GFQuestDoer:GetQuestData(qName)
    return self.currentQuests[qName]
end

function GFQuestDoer:ResetAllQuests(ignoreCurrent)
    --GFDebugPrint("Resetting all quests for" .. tostring(self.inst))
    for qName, v in pairs(self.completedQuests) do
        self:PushCooldown(qName, false)
        self.completedQuests[qName] = nil
    end

    if not ignoreCurrent then
        for qName, _ in pairs(self.currentQuests) do
            --unregistering quest's events
            if ALL_QUESTS[qName] ~= nil then
                ALL_QUESTS[qName]:Abandon()
            end

            self.currentQuests[qName] = nil
        end
    end
end

function GFQuestDoer:CheckClientRequest(qName)
    return self._questTracker[qName] ~= nil
end

function GFQuestDoer:CheckQuest(qName)
    return self.currentQuests[qName] == nil and self.completedQuests[qName] == nil
end

function GFQuestDoer:HasQuest(qName)
    return self.currentQuests[qName] ~= nil
end

function GFQuestDoer:IsQuestDone(qName)
    return self.currentQuests[qName] ~= nil and self.currentQuests[qName].status == 1
end

function GFQuestDoer:TrackGiver(giver)
    self:StopTrackGiver()
    if giver.components.gfquestgiver == nil then return false end

    self._questGiver = giver

    --checking distance
    self._trackTask = self.inst:DoPeriodicTask(0.5, TrackGiver, nil, giver)
    --and listening for combat events
    self.inst:ListenForEvent("attacked", self.TrackGiverFail, self._questGiver)
    self.inst:ListenForEvent("death", self.TrackGiverFail, self._questGiver)
    self.inst:ListenForEvent("newtarget", self.TrackGiverFail, self._questGiver)

    --GFDebugPrint(("%s has started tracking %s"):format(tostring(self.inst), tostring(self._questGiver)))
    return true
end

function GFQuestDoer:StopTrackGiver()
    if self._questGiver == nil then return end
    if next(self._questTracker) ~= nil then
        self._questTracker = {}
    end

    self.inst:RemoveEventCallback("attacked", self.TrackGiverFail, self._questGiver)
    self.inst:RemoveEventCallback("death", self.TrackGiverFail, self._questGiver)
    self.inst:RemoveEventCallback("newtarget", self.TrackGiverFail, self._questGiver)

    if self._trackTask ~= nil then
        self._trackTask:Cancel()
        self._trackTask = nil
    end

    --GFDebugPrint(("%s has stopped tracking %s"):format(tostring(self.inst), tostring(self._questGiver)))
    self._questGiver = nil
end

function GFQuestDoer:GetQuestsNumber()
    return GetTableSize(self.currentQuests)
end

function GFQuestDoer:OnSave()
    if not GFGetIsMasterSim() then return end
end

function GFQuestDoer:OnLoad(data)
    if not GFGetIsMasterSim() or not data or not data.savedata then return end
end

function GFQuestDoer:GetDebugString()
    local give = {}
    local pass = {}

    for k, v in pairs(self.currentQuests or {}) do
        table.insert(give, string.format("%s - %i [%s]", k, v.status or -1, ALL_QUESTS[k]:GetStatusString(self.inst)))
    end

    for k, v in pairs(self.completedQuests or {}) do
        table.insert(pass, string.format("%s:%i", k, v))
    end

    return (#give > 0 or #pass > 0)
        and string.format("current:[%s]; passed:[%s]", table.concat(give, ", "), table.concat(pass, ", ")) 
        or "none"
end


return GFQuestDoer