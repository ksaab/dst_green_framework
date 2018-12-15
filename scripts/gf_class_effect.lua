--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

------------------------------------------------------------
--INFO------------------------------------------------------
------------------------------------------------------------
--All methods are unsafe, do not use them directly
--Valid ways to work with effects are implemented in
--gfeffectable component
------------------------------------------------------------

local Effect = Class(function(self, name)
    --[[SERVER AND CLIENT]]
    self.name = name
    self.type = 0

    --image
    self.icon = nil
    self.iconAtlas = nil

    --flags
    self.pushToReplica = false
    self.pushToClassified = false

    --hud functions
    self.hudonapplyfn = nil
    self.hudonrefreshfn = nil
    self.hudonremovefn = nil

    --flags
    self.savable = false --save effect or not
    self.nonRefreshable = false --can effect be refreshed or not

    self.updateDurationOnRefresh = true
    self.updateStacksOnRefresh = false
    self.updateable = true --need to update on ticks or not
    self.static = true --for static effects without timers (affixes and etc)
    self.sleeper = false
    self.removableByStacks = true --can be removed by consuming stacks or not

    --effect data
    self.tags = {}
    self.maxStacks = 1

    --effect timers
    self.baseDuration = 10 --base duration
    self.tickPeriod = 1 --how often onupdate function will be called 
    
    --functions
    self.checkfn = nil
    self.onapplyfn = nil
    self.onrefreshfn = nil
    self.onupdatefn = nil
    self.onremovefn = nil
end)

------------------------------------------------------------
--server and client metods ---------------------------------
------------------------------------------------------------

function Effect:HUDOnUpdate(inst, eData)
    if self.hudonapplyfn then self:hudonapplyfn(inst, eData) end
end

function Effect:HUDOnRemove(inst, eData)
    if self.hudonremovefn then self:hudonremovefn(inst) end
end

------------------------------------------------------------
--server only metods ---------------------------------------
------------------------------------------------------------

function Effect:Check(inst)
    if self.checkfn ~= nil then 
        return self:checkfn(inst)
    end
    return true
    --return self.checkfn ~= nil and self:checkfn(inst) or true
end

function Effect:Apply(inst, eData, eParams)
    eParams = eParams or {} --define if nil
    local currTime = GetTime()

    eData.applier = eParams.applier
    eData.stacks = math.min(self.maxStacks, eParams.stacks or 1)
    eData.expirationTime = self.static and 0 or currTime + (eParams.duration or self.baseDuration)
    eData.applicationTime = currTime
    eData.nextTick = currTime + self.tickPeriod
    eData.static = self.static

    if self.onapplyfn then
        self:onapplyfn(inst, eData, eParams)
    end
end

function Effect:Refresh(inst, eData, eParams)
    eParams = eParams or {} --define if nil

    if not self.static and self.updateDurationOnRefresh then
        local duration = GetTime() + (eParams.duration or self.baseDuration)
        if eData.expirationTime < duration then
            eData.expirationTime = duration
        end
    end

    if self.updateStacksOnRefresh then
        eData.stacks = math.min(eData.stacks + (eParams.stacks or 1), self.maxStacks)
    end

    if self.onrefreshfn then
        self:onrefreshfn(inst, eData, eParams)
    end
end

function Effect:Remove(inst, eData, reason)
    if self.onremovefn then self:onremovefn(inst, eData, reason) end
end

function Effect:ConsumeStacks(inst, eData, value)
    value = value or 1
    local stacks = eData.stacks - value

    if stacks <= 0 then
        if self.removableByStacks then
            inst.components.gfeffectable:RemoveEffect(self.name, "dispell")
            return
        else
            eData.stacks = 1
        end
    else
        eData.stacks = math.max(stacks, self.maxStacks)
    end

    self:Refresh(inst, eData, {duration = 0, stacks = 0})
end

function Effect:HasTag(tag)
    return self.tags[tag] ~= nil
end

function Effect:AddTag(tag)
    self.tags[tag] = true
end

function Effect:RemoveTag(tag)
    self.tags[tag] = nil
end

------------------------------------------------------------
--ingame metods --------------------------------------------
------------------------------------------------------------

function Effect:Update(inst, eData)
    eData.nextTick = GetTime() + self.tickPeriod
    if self.onupdatefn then self:onupdatefn(inst, eData) end
end

function Effect:OnWake(inst, eData)
    if self.onentwakefn then self:onentwakefn(inst, eData) end
end

function Effect:OnSleep(inst, eData)
    if self.onentsleepfn then self:onentsleepfn(inst, eData) end
end


return Effect