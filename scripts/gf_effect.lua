local Effect = Class(function(self, name)
    --[[SERVER AND CLIENT]]
    self.name = name
    self.type = 0

    --image
    self.icon = nil
    self.iconAtlas = nil

    --text info
    self.enchantText = nil --enchant string
    self.hoverText = nil --text under name for pos and neg effect, text above for affixes
    self.titleText = nil --title for icon
    self.descText = nil --text for icon

    --flags
    self.wantsIcon = false
    self.wantsHover = false

    --hud functions
    self.hudonapplyfn = nil
    self.hudonrefreshfn = nil
    self.hudonremovefn = nil

    if not GFGetIsMasterSim() then return end
    --[[SERVER ONLY]]
    --flags
    self.savable = false --save effect or not
    self.nonRefreshable = false --can effect be refreshed or not
    self.updateDurationOnRefresh = true
    self.updateStacksOnRefresh = false
    self.updateable = true --need to update on ticks or not
    self.static = true --for static effects without timers (affixes and etc)
    self.removableByStacks = true --can be removed by consuming stacks or not

    --effect data
    self.tags = {}
    self.applier = nil --who apply the effect
    self.stacks = 0
    self.maxStacks = 1

    --effect timers
    self.expirationTime = 0
    self.applicationTime = 0
    self.updateTime = 0 --this will be setted is gfeffectable
    self.baseDuration = 10 --base duration
    self.tickPeriod = 1 --how often onupdate function will be called 

    --effect fx
    --fx will be attached only if has Follower
    self.applyPrefab = nil --this will be not removed by component
    self.applyPrefabOffset = false
    self.followPrefab = nil --this wili be removed by componen
    self.followPrefabOffset = false
    
    --functions
    self.checkfn = nil
    self.onapplyfn = nil
    self.onrefreshfn = nil
    self.onupdatefn = nil
    self.onremovefn = nil
end)

function Effect:ConsumeStacks(inst, value)
    value = value or 1
    local stacks = self.stacks - value
    if stacks <= 0 then
        if not self.removableByStacks then
            inst.components.gfeffectable:RemoveEffect(self.name, "dispell")
            return
        else
            self.stacks = 1
        end
    else
        self.stacks = math.max(stacks, self.maxStacks)
    end
    self:Refresh(inst, {duration = 0, stacks = 0})
end

function Effect:Apply(inst, effectParam)
    effectParam = effectParam or {} --define if nil

    local currTime = GetTime()
    self.applier = effectParam.applier
    self.stacks = math.min(effectParam.stacks or 1, self.maxStacks)
    self.expirationTime = self.static and 0 or currTime + (effectParam.duration or self.baseDuration)
    self.applicationTime = currTime
    self.updateTime = currTime

    if self.onapplyfn then
        self:onapplyfn(inst, effectParam)
    end
end

function Effect:Refresh(inst, effectParam)
    effectParam = effectParam or {} --define if nil

    if not self.static and self.updateDurationOnRefresh then
        local duration = GetTime() + (effectParam.duration or self.baseDuration)
        if self.expirationTime < duration then
            self.expirationTime = duration
        end
    end

    if self.updateStacksOnRefresh then
        self.stacks = math.min(self.stacks + (effectParam.stacks or 1), self.maxStacks)
    end

    if self.onrefreshfn then
        self:onrefreshfn(inst, effectParam)
    end
end

function Effect:Update(inst)
    if self.onupdatefn then
        self:onupdatefn(inst)
    end
end

function Effect:Remove(inst)
    if self.onremovefn then
        self:onremovefn(inst)
    end
end


return Effect