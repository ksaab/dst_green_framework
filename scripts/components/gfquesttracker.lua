--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.
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

    self._giverRemoved = function(giver)
        local hash = self.questGivers[giver]
        self.questGivers[giver] = nil
        self.giverHashes[hash] = nil
        for k, player in pairs(self.questDoers) do
            if player.components.gfquestdoer then
                print(giver, "dies")
                player.components.gfquestdoer:FailQuestsWithHash(hash)
            end
        end
    end

    inst:ListenForEvent("ms_playeractivated", function(inst, player) self:HandlePlayerLeaving(player) end)
end)

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

function GFQuestTracker:HandlePlayerLeaving(player)
    if player.components.gfquestdoer == nil then return end

    
end

return GFQuestTracker