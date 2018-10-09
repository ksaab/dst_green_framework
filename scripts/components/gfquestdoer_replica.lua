--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

local function HookUltraHack(inst)
    local self = inst.replica.gfquestdoer
    if inst == ThePlayer then
        print(self._superString:value() .. " on this player " .. tostring(inst))
    else
        print(self._superString:value() .. " on another player " .. tostring(inst))
    end
end

local GFQuestDoer = Class(function(self, inst)
    self.inst = inst

    self._superString = net_string(inst.GUID, "GFQuestDoer._superString", "ultrahack")
    inst:ListenForEvent("ultrahack", HookUltraHack)
end)

return GFQuestDoer