local ALL_QUESTS = GF.GetQuests()
local QUESTS_IDS = GF.GetQuestsIDs()
local OFFSETS = GF.InterlocutorOffsets

--client only
local function DeserializeQuests(inst)
    -----------------------------------------------
    --QUEST1ID;MODE^QUEST2ID;MODE^QUEST3ID;MODE;etc
    -----------------------------------------------

    local self = inst.replica.gfquestgiver
    local qArr = self._questLine:value():split('^')

    self.quests = {}

    for _, qData in pairs(qArr) do
        local tmp = qData:split(';')
        local qName = QUESTS_IDS[tonumber(tmp[1])]
        if qName ~= nil then
            self.quests[qName] = tonumber(tmp[2]) or 0
        end
    end

    if ThePlayer ~= nil and ThePlayer.replica.gfquestdoer ~= nil then
        if self:HasQuests() then
            self:StartTrackingPlayer()
        elseif self._listening then
            self:StopTrackingPlayer()
        end
    end
end

local function SpawnMark(self)
    if self._follower ~= nil then return false end
    local mark = SpawnPrefab("gf_quest_mark")
    if mark ~= nil then
        --self.inst:AddChild(mark)
        self._follower = mark
    end

    return mark ~= nil
end

local QSQuestGiver = Class(function(self, inst)
    self.inst = inst

    self.quests = {}

    self._questLine = net_string(inst.GUID, "QSQuestGiver._questLine", "gfQGUpdateQuests")
    self._listening = false

    self._follower = nil
    self._followerOffest = OFFSETS[inst.prefab] or 0
    self._oncameraupdate = function(dt) self:OnCameraUpdate(dt) end
    self._onplayerupdate = function(player) self:CheckQuestsOnPlayer(player) end

    self._task = nil
    self._hash = net_string(inst.GUID, "QSQuestGiver._hash")

    if not GFGetIsMasterSim() then
        inst:ListenForEvent("gfQGUpdateQuests", DeserializeQuests)
    end

    if not GFGetIsDedicatedNet() then
        inst:ListenForEvent("onremove", function() self:StopTrackingPlayer() end)
        inst:DoTaskInTime(0, function() self:StartTrackingPlayer() end)
    end

    if self.inst.components.gfquestgiver ~= nil then 
        self.quests = self.inst.components.gfquestgiver.quests
    end
end)

function QSQuestGiver:HasQuests()
    return next(self.quests) ~= nil
end

function QSQuestGiver:UpdateQuests()
    local function UpdateFn(inst)
        --for the server-side self.quests is the same to inst.component.gfquestgiver.quests
        local self = inst.replica.gfquestgiver
        self._task = nil

        local str = {}
        for qName, qMode in pairs(self.quests) do
            table.insert(str, string.format("%i;%i", ALL_QUESTS[qName].id, qMode))
        end
        
        local str = table.concat(str, '^')
        
        self._questLine:set_local(str)
        self._questLine:set(str)

        if not GFGetIsDedicatedNet() then
            if GFGetPlayer() ~= nil and GFGetPlayer().replica.gfquestdoer ~= nil then
                if self:HasQuests() then
                    self:StartTrackingPlayer()
                elseif self._listening then
                    self:StopTrackingPlayer()
                end
            end
        end
    end

    --need to do it with a small delay to prevent multiply calls at one tick
    --because the entity may have a lot of quests
    if self._task == nil then
        self._task = self.inst:DoTaskInTime(0, UpdateFn)
    end
end

function QSQuestGiver:CheckQuestsOnPlayer(player)
    local pcomp = player.replica.gfquestdoer

    local hash = self._hash:value()
    for qName, qMode in pairs(self.quests) do
        if qMode ~= 1 and pcomp:IsQuestDone(qName, hash) then
            --GFDebugPrint(("QSQuestGiver: %s I can complete a quest %s#%s for %s"):format(tostring(self.inst), qName, hash, tostring(player)))
            if self._follower ~= nil or SpawnMark(self) then
                self._follower.AnimState:PlayAnimation("question" .. self._followerOffest, true)
            end
            return
        end
    end

    for qName, qMode in pairs(self.quests) do
        if qMode ~= 2 and pcomp:CanPickQuest(qName, hash) then
            --GFDebugPrint(("QSQuestGiver: %s I can give a quest %s#%s to %s"):format(tostring(self.inst), qName, hash, tostring(player)))
            if self._follower ~= nil or SpawnMark(self) then
                self._follower.AnimState:PlayAnimation("exclamation" .. self._followerOffest, true)
            end
            return
        end
    end

    if self._follower ~= nil then
        self._follower:Remove()
        self._follower = nil
        --self._follower.AnimState:PlayAnimation("none", true)
    end

    --GFDebugPrint(("QSQuestGiver: %s #%s I don't have any interesting for %s"):format(tostring(self.inst), hash, tostring(player)))
end

function QSQuestGiver:StartTrackingPlayer()
    if GFGetIsDedicatedNet()    --dedicated don't need to track
        or not self:HasQuests() --don't need to track the player id we don't have any quests
        or GFGetPlayer() == nil                         --no valid player,
        or GFGetPlayer().replica.gfquestdoer == nil  --no valid component
        or self.inst:IsAsleep()
    then
        --GFDebugPrint("QSQuestGiverR: don't need to track the player!")
        --self:StopTrackingPlayer()
        return 
    end

    if self._listening then
        self:CheckQuestsOnPlayer(ThePlayer)
        return
    end

    SpawnMark(self)

    self._listening = true
    TheCamera:AddListener(self, self._oncameraupdate)
    self:CheckQuestsOnPlayer(ThePlayer)
    self.inst:ListenForEvent("gfQSOnQuestUpdate", self._onplayerupdate, ThePlayer)

    --GFDebugPrint(("QSQuestGiverR: Now %s watching for %s"):format(tostring(self.inst), tostring(ThePlayer)))
end

function QSQuestGiver:StopTrackingPlayer()
    if not self._listening then return end

    if self._follower ~= nil and self._follower:IsValid() then
        self._follower:Remove()
        self._follower = nil
    end

    self._listening = false
    TheCamera:RemoveListener(self, self._oncameraupdate)
    self.inst:RemoveEventCallback("gfQSOnQuestUpdate", self._onplayerupdate, ThePlayer)

    --GFDebugPrint(("QSQuestGiverR: %s stops watching for %s"):format(tostring(self.inst), tostring(ThePlayer)))
end

function QSQuestGiver:OnCameraUpdate(dt)
    if self._follower ~= nil and self.inst ~= nil and self.inst:IsValid() then
        local x, y, z = self.inst.Transform:GetWorldPosition()
        self._follower.Transform:SetPosition(x, y, z)
    end
end

return QSQuestGiver
