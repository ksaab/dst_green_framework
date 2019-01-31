--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.
local ALL_QUESTS = GF.GetQuests()

local charSet = {}

for i = 48,  57 do table.insert(charSet, string.char(i)) end
for i = 97, 122 do table.insert(charSet, string.char(i)) end

local function GenerateHash()
    local str = {}
    local num = #charSet
    for i = 1, 4 do
        str[i] = charSet[math.random(1, num)]
    end

    return table.concat(str)
end

local GFQuestTracker = Class(function(self, inst)
    self.inst = inst
    self.questGivers = {}
    self.giverHashes = {}
    self.questDoers = AllPlayers

    self.hash = "_wld"
    self.worldHash = GenerateHash()

    self._giverRemoved = function(giver)
        local hash = self.questGivers[giver]
        self.questGivers[giver] = nil
        self.giverHashes[hash] = nil
        for k, player in pairs(self.questDoers) do
            if player.components.gfquestdoer then
                player.components.gfquestdoer:FailQuestsWithHash(hash)
            end
        end
    end

    self._playerLeave = function(player)
        for qKey, qData in pairs(player.components.gfquestdoer.currentQuests) do
            local qInst = ALL_QUESTS[qData.name]
            if not qInst.unsavable 
                and qInst.soulbound 
                and qData.hash ~= nil 
                and self.giverHashes[qData.hash] ~= nil
            then
                self.giverHashes[qData.hash].components.gfquestgiver:OnQuestAbandoned(qData.name, player)
            end
        end
    end

    --inst:ListenForEvent("ms_playeractivated", function(inst, player) self:HandlePlayerLeaving(player) end)
end)

function GFQuestTracker:QuestAbandoned(doer, qName, hash)
    if hash ~= nil and self.giverHashes[hash] ~= nil then
        self.giverHashes[hash].components.gfquestgiver:OnQuestAbandoned(qName, doer)
    end
end

function GFQuestTracker:QuestAccepted(doer, qName, hash)
    if hash ~= nil and self.giverHashes[hash] ~= nil then 
        self.giverHashes[hash].components.gfquestgiver:OnQuestAccepted(qName, doer)
    end
end

function GFQuestTracker:QuestCompleted(doer, qName, hash)
    if hash ~= nil and self.giverHashes[hash] ~= nil then 
        self.giverHashes[hash].components.gfquestgiver:OnQuestCompleted(qName, doer)
    end
end

function GFQuestTracker:TrackGiver(giver, hash)
    if hash == nil then
        hash = GenerateHash()
        while self.giverHashes[hash] ~= nil do
            hash = GenerateHash()
        end
    end

    self.questGivers[giver] = hash
    self.giverHashes[hash] = giver

    self.inst:ListenForEvent("onremove", self._giverRemoved, giver)

    return hash
end

function GFQuestTracker:GetWorldHash(data)
    return self.worldHash
end

function GFQuestTracker:HandlePlayerLeaving(player)
    if player.components.gfquestdoer == nil then return end
    self.inst:ListenForEvent("ms_playerdespawnanddelete", self._playerLeave, player)    
end

function GFQuestTracker:OnSave()
    return {hash = self.worldHash}
end

function GFQuestTracker:OnLoad(data)
    if data ~= nil and data.hash ~= nil then self.worldHash = data.hash end
end

return GFQuestTracker