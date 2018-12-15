local ALL_QUESTS = GF.GetQuests()
local QUESTS_IDS = GF.GetQuestsIDs()

local _r = require "components/gfquestdoer_r"

local function TrackGiver(inst, giver)
    if not inst:IsValid() or not giver:IsValid() or not inst:IsNear(giver, 15) then
        inst.components.gfquestdoer.TrackGiverFail()
    end
end

local function _GetQuestKey(qName, hash)
    if qName ~= nil and ALL_QUESTS[qName] ~= nil then
        return ALL_QUESTS[qName].unique
            and qName
            or (hash ~= nil and qName .. hash or nil)
    end

    return nil
end

local function OnInvChanged(inst, data)
    local self = inst.components.gfquestdoer
    if self._itemTask == nil then
        self._itemTask = inst:DoTaskInTime(0, function(inst, data) 
            inst:PushEvent("gfinvchanged", data) 
            inst.components.gfquestdoer._itemTask = nil
        end, data)
    end
end

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

local GFQuestDoer = Class(function(self, inst)
    self.inst = inst

    self.currentQuests = {}
    self.completedQuests = {}
    self.registredQuests = {}

    --attaching classified on the server-side
    if self.classified == nil and inst.player_classified ~= nil then
        self:AttachClassified(inst.player_classified)
    end

    if GFGetIsMasterSim() then
        inst:WatchWorldState("phase", UpdateCooldowns)

        inst:ListenForEvent("itemlose", OnInvChanged)
        inst:ListenForEvent("gotnewitem", OnInvChanged)
    end
end)

GFQuestDoer.AttachClassified = _r.AttachClassified
GFQuestDoer.DetachClassified = _r.DetachClassified
GFQuestDoer.UpdateQuestList = _r.UpdateQuestList
GFQuestDoer.UpdateQuestInfo = _r.UpdateQuestInfo

-----------------------------------------
--safe methods---------------------------
-----------------------------------------
function GFQuestDoer:OfferQuests(quests, strid, giver)
    local dComp = self.components.gfplayerdialog
    if dComp == nil then
        print(("Something wrong - %s doesn't have a dialog component"):format(tostring(self.inst)))
        return false
    end

    return true
end

function GFQuestDoer:OfferQuest(qName, strid, giver)
    self:OfferQuests({qName}, strid, giver)
end

function GFQuestDoer:AcceptQuest(qName, hash)
    print("accepting", qName, hash)
    local qKey = GetQuestKey(qName, hash)
    if qKey == nil or not self:CanPickQuest(qName, hash, qKey) then return end

    local qInst = ALL_QUESTS[qName]
    local qData = 
    {
        name = qName,
        hash = hash,
        world = GFGetWorld().components.gfquesttracker:GetWorldHash(),
        status = 0,
    }

    --registring events for quest, 
    --don't need to to this if we already have the same quest with another hash
    if self.registredQuests[qName] == nil then 
        self.registredQuests[qName] = {} 
        qInst:Register(self.inst)
    end
    self.registredQuests[qName][qKey] = qData

    --loading required data from quest
    self.currentQuests[qKey] = qData 
    self:UpdateQuestList(qName, hash, 3)
    --components stores quests by qName .. hash, so we can pick more then one same quest
    --but quests without the soulbound flag are stored without a hash suffix - so player can take only one instace of the quest

    --TODO - Replace on replica when it's possible
    --can't use replicas because of woodie tag overflow crashes
    qInst:Accept(self.inst, qData)

    --closing dialog
    local dComp = self.inst.components.gfplayerdialog
    if dComp ~= nil then
        local giver = dComp:GetTrackingEntity()
        if giver ~= nil and giver.components.gfquestgiver ~= nil then
            giver.components.gfquestgiver:OnQuestAccepted(qName, self.inst)
        end

        dComp:CloseDialog()
    end

    return self.currentQuests[qKey]
end

function GFQuestDoer:CompleteQuest(qName, hash, ignore)
    local qKey = GetQuestKey(qName, hash)
    if qKey == nil 
        or not self:IsHashedQuestDone(qKey)
        or (not ignore and not ALL_QUESTS[qName]:CheckBeforeComplete(self.inst, self.currentQuests[qKey]))
    then 
        GFDebugPrint(string.format("%s can't complete the quest %s", tostring(self.inst), qKey))
        return false
    end

    local qInst = ALL_QUESTS[qName]

    self.registredQuests[qName][qKey] = nil
    if next(self.registredQuests[qName]) == nil then
        qInst:Unregister(self.inst)
        self.registredQuests[qName] = nil
    end
    qInst:Complete(self.inst, self.currentQuests[qKey])

    --TODO - cooldowns
    if qInst.cooldown > 0 then
        if qInst.unique then
            self.completedQuests[qName] = 
            {
                qName = qName,
                hash = hash,
                readyTime = qInst.cooldown + GetTime(),
            }
        else
            self.completedQuests[qKey] = 
            {
                qName = qName,
                hash = hash,
                readyTime = qInst.cooldown + GetTime(),
            }
        end

        self:UpdateQuestList(qName, hash, 8)
    end

    --TODO - Replace on replica when it's possible
    --can't use replicas because of woodie tag overflow crashes
    self:UpdateQuestList(qName, hash, 5)
    self.currentQuests[qKey] = nil

    --closing dialog
    local dComp = self.inst.components.gfplayerdialog
    if dComp ~= nil then
        local giver = dComp:GetTrackingEntity()
        if giver ~= nil and giver.components.gfquestgiver ~= nil then
            giver.components.gfquestgiver:OnQuestCompleted(qName, self.inst)
        end

        dComp:CloseDialog()
    end

    return true
end

function GFQuestDoer:AbandonQuest(qName, hash)
    local qKey = GetQuestKey(qName, hash)
    if qKey == nil or self.currentQuests[qKey] == nil then return false end

    local qInst = ALL_QUESTS[qName]

    if self.registredQuests[qName] then
        self.registredQuests[qName][qKey] = nil
        if next(self.registredQuests[qName]) == nil then
            qInst:Unregister(self.inst)
            self.registredQuests[qName] = nil
        end
    end
    qInst:Abandon(self.inst, self.currentQuests[qKey])
    GFGetWorld().components.gfquesttracker:QuestAbandoned(self.inst, qName, hash)
    --TODO - Replace on replica when it's possible
    --can't use replicas because of woodie tag overflow crashes
    self:UpdateQuestList(qName, hash, 4)
    self.currentQuests[qKey] = nil

    return true
end

function GFQuestDoer:SetQuestDone(qName, hash, done)
    local qKey = GetQuestKey(qName, hash)
    if qKey == nil or self.currentQuests[qKey] == nil then return false end

    local status = (done == nil or done == false) and 0 or 1
    print(qKey .. "now has status " .. tostring(status))
    if self.currentQuests[qKey].status ~= status then
        self.currentQuests[qKey].status = status
        self:UpdateQuestList(qName, hash, status)
        self:UpdateQuestInfo(qName, hash, done)
    end
end

function GFQuestDoer:SetQuestFailed(qName, hash)
    local qKey = GetQuestKey(qName, hash)
    if qKey == nil or self.currentQuests[qKey] == nil then return false end

    if self.currentQuests[qKey].status ~= 2 then
        --unregistering quest's events
        if self.registredQuests[qName] then
            self.registredQuests[qName][qKey] = nil
            if next(self.registredQuests[qName]) == nil then
                ALL_QUESTS[qName]:Unregister(self.inst)
                self.registredQuests[qName] = nil
            end
        end
        print(qName .. "is now failed")
        self.currentQuests[qKey].status = 2
        self:UpdateQuestInfo(qName, hash, true)
        self:UpdateQuestList(qName, hash, 2)
    end
end


--get info by pairs quest name + giver hash
-------------------------------------------
function GFQuestDoer:CanPickQuest(qName, hash)
    local qKey = GetQuestKey(qName, hash)
    return qKey ~= nil 
        and self.currentQuests[qKey] == nil 
        and self.completedQuests[qKey] == nil
        and self.completedQuests[qName] == nil
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

function GFQuestDoer:GetQuestData(qName, hash)
    local qKey = GetQuestKey(qName, hash)
    return qKey ~= nil and self.currentQuests[qKey] or nil
end

--get info by hashed key
-------------------------------------------
function GFQuestDoer:CanPickHashedQuest(qKey, qName)
    return qKey ~= nil 
        and self.currentQuests[qKey] == nil 
        and self.completedQuests[qKey] == nil
        and self.completedQuests[qName] == nil
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

function GFQuestDoer:GetHashedQuestData(qKey)
    return qKey ~= nil and self.currentQuests[qKey] or nil
end

--other
function GFQuestDoer:GetRegistredQuests(qName)
    return self.registredQuests[qName]
end

function GFQuestDoer:GetQuestsNumber()
    return GetTableSize(self.currentQuests)
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
                    --[[ local qtracker = GFGetWorld().components.gfquesttracker
                    if qData.world == qtracker:GetWorldHash()
                        and (qtracker.giverHashes[qData.hash] == nil
                            or not qtracker.giverHashes[qData.hash].components.gfquestgiver:IsCompleterFor(qData.name))
                    then
                        self:SetQuestFailed(qData.name, qData.hash)
                    end ]]
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
    for k, qData in pairs(self.currentQuests) do
        table.insert(curr, string.format("[%s:%s - %i]", qData.name, qData.hash or "NONE", qData.status))
    end

    return #curr > 0 and table.concat(curr, ",") or "None"
end


return GFQuestDoer