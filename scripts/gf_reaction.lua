--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

local Reaction = Class(function(self, name, data)
    if data == nil or data.reactfn == nil then self.fail = true return end

    self.name = name

    self.event = data.event or "onhitother"
    self.target = data.target or "self"
    self.swapParticipant = data.swapParticipant or false
    
    self.chance = data.chance or 1
    self.charges = data.charges or false
    self.recharge = data.recharge or 0.1
    self.lastReactTime = 0

    self.checkfn = data.checkfn or nil
    self.reactfn = type(data.reactfn) == "function" and data.reactfn or require("reactions/" .. data.reactfn)

    self.reactParams = {}
    
    if data.reactParams ~= nil then
        for param, paramValue in pairs(data.reactParams) do
            self.reactParams[param] = paramValue
        end
    end

    --GFDebugPrint(("Reaction created: %s, event %s"):format(tostring(self.name), self.event))
end)

function Reaction:React(reactor, initiator, eventData)
    local inst = reactor
    if not reactor:IsValid() then 
        --GFDebugPrint(("Reaction: reaction %s failed - reactor %s isn't valid"):format(self.name, tostring(reactor)))
        return 
    end

    if self.checkfn and not self:checkfn(reactor, initiator, eventData) then
        --GFDebugPrint(("Reaction: reaction %s check failed"):format(tostring(self.name)))
        return
    end

    if GetTime() - self.lastReactTime > self.recharge and math.random() < self.chance then
        if self.swapParticipant  then
            if not initiator or not initiator:IsValid() then
                --GFDebugPrint(("Reaction: reaction %s swap failed - initiator %s isn't valid"):format(self.name, tostring(initiator)))
                return 
            end
            local tmp = reactor
            reactor = initiator
            initiator = tmp
        end

        self.lastReactTime = GetTime()
        if initiator or initiator:IsValid() then
            self:reactfn(reactor, initiator, eventData)
        else
            --GFDebugPrint(("Reaction: reaction %s failed - initiator %s isn't valid"):format(self.name, tostring(initiator)))
            return 
        end

        if self.charges then
            self.charges = self.charges - 1
            if self.charges <= 0 then
                inst.components.gfeventreactor:RemoveReaction(self.name, self.event)
            end
        end
    end
end

return Reaction