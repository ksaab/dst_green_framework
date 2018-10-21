local ALL_QUESTS = GFQuestList
local QID_TO_NAME = GFQuestIDToName

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
        local qName = QID_TO_NAME[tonumber(tmp[1])]
        if qName ~= nil then
            self.quests[qName] = tonumber(tmp[2])
        end
    end

    if ThePlayer ~= nil and ThePlayer.components.gfquestdoer ~= nil then
        if self:HasQuests() then
            self:StartTrackingPlayer()
        elseif self._listening then
            self:StopTrackingPlayer()
        end
    end
end

local QSQuestGiver = Class(function(self, inst)
    self.inst = inst

    self.quests = {}

    self._questLine = net_string(inst.GUID, "QSQuestGiver._questLine", "gfQGUpdateQuests")
    self._listening = false

    self._follower = nil
    self._followerOffest = GFQuestGivers[inst.prefab].markOffset or 0

    self._oncameraupdate = function(dt) self:OnCameraUpdate(dt) end
    self._onplayerupdate = function(player) self:CheckQuestsOnPlayer(player) end

    self._task = nil

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
        local self = inst.replica.gfquestgiver
        self._task = nil

        local str = {}
        for qName, qData in pairs(self.quests) do
            table.insert(str, string.format("%i;%i", ALL_QUESTS[qName].id, qData))
        end
        
        local str = table.concat(str, '^')
        
        self._questLine:set_local(str)
        self._questLine:set(str)
    end

    --need to do it with a small delay to prevent multiply calls at one tick
    --because entity may have a lot of quests
    if self._task == nil then
        self._task = self.inst:DoTaskInTime(0, UpdateFn)
    end

    self:StartTrackingPlayer()
end

function QSQuestGiver:CheckQuestsOnPlayer(player)
    --TODO: replace component with replica when it's possible
    local pcomp = player.components.gfquestdoer

    for qName, qData in pairs(self.quests) do
        if qData ~= 1 and pcomp:IsQuestDone(qName) then
            print(("QSQuestGiver: %s I can complete a quest %s for %s"):format(tostring(self.inst), qName, tostring(player)))
            if self._follower ~= nil then
                self._follower.AnimState:PlayAnimation("question" .. self._followerOffest, true)
            end
            return
        end
    end

    for qName, qData in pairs(self.quests) do
        if qData ~= 2 and pcomp:CheckQuest(qName) then
            print(("QSQuestGiver: %s I can give a quest %s to %s"):format(tostring(self.inst), qName, tostring(player)))
            if self._follower ~= nil then
                self._follower.AnimState:PlayAnimation("exclamation" .. self._followerOffest, true)
            end
            return
        end
    end

    if self._follower ~= nil then
        self._follower.AnimState:PlayAnimation("none", true)
    end
    print(("QSQuestGiver: %s I don't have any interesting for %s"):format(tostring(self.inst), tostring(player)))
end

function QSQuestGiver:StartTrackingPlayer()
    if GFGetIsDedicatedNet()    --dedicated don't need to track
        or not self:HasQuests() --don't need to track the player id we don't have any quests
        --or self._listening      --we are already tracking the player
        or ThePlayer == nil                         --no valid player,
        or ThePlayer.components.gfquestdoer == nil  --no track
        or self.inst:IsAsleep()
    then
        --GFDebugPrint("QSQuestGiverR: don't need to track the player!")
        return 
    end

    if self._listening then
        self:CheckQuestsOnPlayer(ThePlayer)
        return
    end

    if self._follower == nil then
         self._follower = SpawnPrefab("gf_quest_mark")
    end
    if self._follower == nil then
        --GFDebugPrint("QSQuestGiverR: Panic! Can't create a follower!")
        return
    end

    --self._follower:ListenForEvent("onremove", function() self._follower:Remove() end, self.inst)
    self._listening = true
    TheCamera:AddListener(self, self._oncameraupdate)
    self:CheckQuestsOnPlayer(ThePlayer)
    self.inst:ListenForEvent("gfQSOnQuestUpdate", self._onplayerupdate, ThePlayer)

    --print(("QSQuestGiverR: Now %s watching for %s"):format(tostring(self.inst), tostring(ThePlayer)))
end

function QSQuestGiver:StopTrackingPlayer()
    if self._listening then 
        if self._follower ~= nil and self._follower:IsValid() then
            self._follower:Remove()
            self._follower = nil
        end

        self._listening = false
        TheCamera:RemoveListener(self, self._oncameraupdate)
        self.inst:RemoveEventCallback("gfQSOnQuestUpdate", self._onplayerupdate, ThePlayer)

        --print(("QSQuestGiverR: %s stops watching for %s"):format(tostring(self.inst), tostring(ThePlayer)))
    end
end

function QSQuestGiver:OnCameraUpdate(dt)
    if self._follower ~= nil and self.inst ~= nil and self.inst:IsValid() then
        local x, y, z = self.inst.Transform:GetWorldPosition()
        self._follower.Transform:SetPosition(x, y, z)
    end
end

return QSQuestGiver
