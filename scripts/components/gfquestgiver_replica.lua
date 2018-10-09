local allQuests = GFQuestList

local function SetClientQuestCount(inst)
    local self = inst.replica.gfquestgiver
    self.questCount = self._questCount:value()
end

local QSQuestGiver = Class(function(self, inst)
    self.inst = inst

    self.questCount = 0
    self._questCount = net_smallbyte(inst.GUID, "QSQuestGiver._hasQuests", "qssetgiverdirty")

    if not GFGetIsMasterSim() then
        inst:ListenForEvent("qssetgiverdirty", SetClientQuestCount)
    end
end)

function QSQuestGiver:AddQuest()
    self.questCount = self.questCount + 1
    self._questCount:set_local(0)
    self._questCount:set(self.questCount)
end

function QSQuestGiver:RemoveQuest()
    self.questCount = self.questCount - 1
    self._questCount:set_local(0)
    self._questCount:set(self.questCount)
end

function QSQuestGiver:HasQuests()
    return self.questCount > 0
end


return QSQuestGiver
