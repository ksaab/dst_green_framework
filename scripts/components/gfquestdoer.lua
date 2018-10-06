local allQuests = GFQuestList

local function QuestPushedDirty(inst)
    if inst ~= ThePlayer then return end

    local self = inst.components.gfquestdoer
    local qName = self._pushQuest:value()
    inst:PushEvent("qsquestoffered", {qName = qName})
end

local function QuestCompletedDirty(inst)
    if inst ~= ThePlayer then return end

    local self = inst.components.gfquestdoer
    local qName = self._completeQuest:value()
    inst:PushEvent("qsquestcompleted", {qName = qName})
end

local function ForceCloseDialog(inst)
    if inst ~= ThePlayer then return end
    inst:PushEvent("qsforceclosedialog")
end

local function TrackGiverFail(inst)
    inst.components.gfquestdoer._forceCloseDialog:push()
    inst.components.gfquestdoer:StopTrackGiver()

    if inst ~= ThePlayer then return end
    inst:PushEvent("qsforceclosedialog")
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

local QSQuestDoer = Class(function(self, inst)
    self.inst = inst

    self.currentQuests = {}
    self.completedQuests = {}

    self._pushQuest = net_string(inst.GUID, "QSQuestDoer._pushQuest", "qs_questpushdirty")
    self._completeQuest = net_string(inst.GUID, "QSQuestDoer._completeQuest", "qs_questcompletedirty")
    self._forceCloseDialog = net_event(inst.GUID, "qs_forceclosedialog")
    self._infoLine = net_string(inst.GUID, "QSQuestDoer._infoLine", "QSQuestDoer._infoLine")

    --hook for net events
    if not TheWorld.ismastersim then
        inst:DoTaskInTime(0, function(inst)
            inst:ListenForEvent("qs_questpushdirty", QuestPushedDirty)
            inst:ListenForEvent("qs_questcompletedirty", QuestCompletedDirty)
            inst:ListenForEvent("qs_forceclosedialog", ForceCloseDialog)
        end)

        return
    end

    self._questGiver = nil
    self._trackTask = nil

    self:WatchWorldState("cycles", ResetQuests)
end)

function QSQuestDoer:OfferQuest(qName)
    if not TheWorld.ismastersim then return end

    self._pushQuest:set_local("")
    self._pushQuest:set(qName)
    --open a dialog on the host
    if self.inst ~= ThePlayer then return end
    self.inst:PushEvent("qsquestoffered", {qName = qName})
end

function QSQuestDoer:ResetAllQuest(qName)
    self.completedQuests[qName] = {}
end

function QSQuestDoer:CleanUpQuest(qName)
    if self.completedQuests[qName] ~= nil 
        and self.completedQuests[qName] ~= math.huge
        and self.completedQuests[qName] - GetTime() <= 0
    then
        self.completedQuests[qName] = nil
    end
end

function QSQuestDoer:CheckQuest(qName)
    if not TheWorld.ismastersim then return end
    self:CleanUpQuest(qName)

    return self.currentQuests[qName] == nil and self.completedQuests[qName] == nil
end

function QSQuestDoer:AcceptQuest(qName)
    if not TheWorld.ismastersim then return end

    local quest = allQuests[qName]
    if quest then
        self.currentQuests[qName] = {}
        self.currentQuests[qName].done = false
        quest:OnAccept(self.inst, self._questGiver)

        if self._questGiver ~= nil then
            self._questGiver.components.gfquestgiver:QuestAccepted(qName, self.inst)
        end

        self:StopTrackGiver()
    end
end

function QSQuestDoer:CompleteQuest(qName, giver)
    if not TheWorld.ismastersim then return end

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

        self._completeQuest:set_local("")
        self._completeQuest:set(qName)
        --open a dialog on the host
        if self.inst ~= ThePlayer then return end
        self.inst:PushEvent("qsquestcompleted", {qName = qName})
    end
end

function QSQuestDoer:QuestDone(qName, val)
    self._completeQuest:set_local("")
    if val then
        print(qName, "conditions are done!")
        self.currentQuests[qName].done = true
        self._infoLine:set(qName .. " conditions are done!")
    else
        print(qName, "conditions are failed!")
        self.currentQuests[qName].done = false
        self._infoLine:set(qName .. " conditions are failed!")
    end
end

function QSQuestDoer:TrackGiver(giver)
    self:StopTrackGiver()
    self._questGiver = giver

    --checking distance
    self._trackTask = self.inst:DoPeriodicTask(0.5, TrackGiver, nil, giver)
    --and listening for combat events
    self.inst:ListenForEvent("attacked", TrackGiverFail, self._questGiver)
    self.inst:ListenForEvent("death", TrackGiverFail, self._questGiver)
    self.inst:ListenForEvent("newtarget", TrackGiverFail, self._questGiver)

    print(("%s has started tracking %s"):format(tostring(self.inst), tostring(self._questGiver)))
end

function QSQuestDoer:StopTrackGiver()
    if self._questGiver == nil then return end

    self.inst:RemoveEventCallback("attacked", TrackGiverFail, self._questGiver)
    self.inst:RemoveEventCallback("death", TrackGiverFail, self._questGiver)
    self.inst:RemoveEventCallback("newtarget", TrackGiverFail, self._questGiver)

    if self._trackTask ~= nil then
        self._trackTask:Cancel()
        self._trackTask = nil
    end

    print(("%s has stopped tracking %s"):format(tostring(self.inst), tostring(self._questGiver)))
    self._questGiver = nil
end

function QSQuestDoer:OnSave()
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
        local tmp = allQuests[qName]:OnSave(self.inst, qData)
        if tmp then
            savedata.questsInProgress[qName] = tmp
            print(("saving data for %s"):format(qName))
            for k, v in pairs(tmp) do
                print(k, v)
            end
            print("-----------------------------")
        end
    end

    return {savedata = savedata}
end

function QSQuestDoer:OnLoad(data)
    if not data or not data.savedata then return end

    if data.savedata.completedQuests then  -- or data.savedata.questsInProgress)
        local cQuests = data.savedata.completedQuests
        local currTime = GetTime()
        for qName, qTime in pairs(cQuests) do
            self.completedQuests[qName] = currTime - qTime
        end
    end

    if data.savedata.questsInProgress then  -- or data.savedata.questsInProgress)
        local cQuests = data.savedata.questsInProgress
        for qName, qData in pairs(cQuests) do
            self:AcceptQuest(qName)
            allQuests[qName]:OnLoad(self.inst, qData)
            print(("loading data for %s"):format(qName))
            for k, v in pairs(qData) do
                print(k, v)
            end
            print("-----------------------------")
        end
    end
end

function QSQuestDoer:GetDebugString()
    local give = {}
    local pass = {}

    for k, v in pairs(self.currentQuests) do
        table.insert(give, k)
    end

    for k, v in pairs(self.completedQuests) do
        table.insert(pass, string.format("%s:%i", k, v ~= math.huge and v - GetTime() or 0))
    end

    return (#give > 0 or #pass > 0)
        and string.format("current:[%s]; passed:[%s]", table.concat(give, ", "), table.concat(pass, ", ")) 
        or "none"
end


return QSQuestDoer