local effectList = GFEffectList

local function RemoveEffectsOnDeath(inst)
    inst.components.gfeffectable:RemoveAllEffects(false, "death")
end

local GFEffectable = Class(function(self, inst)
    self.inst = inst
    self.effects = {}
    self.resists = {}

    self.isNew = true
    --set data for effect fx
    self.effectsfx = {}
    self.followSymbol = "body"
    self.followYOffset = -200

    self.isUpdating = false
    
    inst:AddTag("gfeffectable")
    inst:ListenForEvent("death", RemoveEffectsOnDeath)
    inst:StartUpdatingComponent(self)
end)

function GFEffectable:ChangeResist(resist, value)
    if resist == nil or value == nil then 
        GFDebugPrint("GFEffectable: can't add resist, data is wrong")
        return 
    end
    local res = self.resists[resist]
    self.resists[resist] = res == nil and value or res + value
end

function GFEffectable:GetResist(resist)
    return self.resists[resist] or 0
end

function GFEffectable:CheckResists(effect)
    if effect.checkfn and not effect:checkfn(self.inst) then  --effect check (maybe the target doesn't have the required component)
        GFDebugPrint(("GFEffectable: effects %s can not be applied to %s"):format(effect.name, tostring(self.inst)))
        return false
    end
    
    if not effect.ignoreResist then --check for resists
        for tag, value in pairs(effect.tags) do
            if self.resists[tag] and self.resists[tag] ~= 0 then
                if math.random() < self.resists[tag] then
                    GFDebugPrint(("GFEffectable: effects %s was resisted by %s"):format(effect.name, tostring(self.inst)))
                    self.inst:PushEvent("gfeffectresisted", {effect = effect})
                    return false
                end
            end
        end
    end

    return true
end

function GFEffectable:ApplyEffect(effectName, effectParam)
    local effectLink = effectList[effectName]
    if effectLink == nil then 
        --effect isn't valid
        print(("GFEffectable: effect with name %s not found"):format(effectName))
        return false
    end

    effectParam = effectParam or {} --set to empty if nil
    local effect

    if self.effects[effectName] then
        --effect already exists on entity
        effect = self.effects[effectName]
        if not effect.nonRefreshable --not all effects are refresheable
            and self:CheckResists(effect) --check resists and other stuff
        then 
            effect:Refresh(self.inst, effectParam)
            if not effect.static then
                self.inst:PushEvent("gfeffectrefreshed", {effect = effect})
            end
            self.inst.replica.gfeffectable:UpdateEffectsList()

            return true
        end
    else
        --applying the new effect
        effect = effectLink(effectParam)
        if self:CheckResists(effect) then --check resists and other stuff
            effect:Apply(self.inst, effectParam)
            self.effects[effectName] = effect
            if not effect.static then
                self.inst:PushEvent("gfeffectapplied", {effect = effect})
            end
            self.inst.replica.gfeffectable:UpdateEffectsList()

            return true
        end
    end

    return false
end

function GFEffectable:ConsumeStacks(effectName, value)
    if effectName == nil or self.effects[effectName] == nil then return end
    self.effects[effectName]:ConsumeStack(inst, value)
end

function GFEffectable:RemoveEffect(effectName, reason)
    reason = reason or "expire"

    local effect = self.effects[effectName]
    if effect == nil then return end --effect isn't existed on entity

    if self.effectsfx[effectName] and self.effectsfx[effectName]:IsValid() then
        self.effectsfx[effectName]:Remove()
    end

    effect:Remove(self.inst)
    self.effects[effectName] = nil
    self.inst.replica.gfeffectable:UpdateEffectsList()

    if not effect.static then
        self.inst:PushEvent("gfeffectremoved", {effect = effect, reason = reason}) 
    end
end

function GFEffectable:RemoveAllEffects(removeStatic, reason)
    for effectName, effect in pairs(self.effects) do
        if removeStatic or not effect.static then
            self:RemoveEffect(effectName, reason)
        end
    end
end

function GFEffectable:RemoveAllEffectsWithTag(tag, reason)
    if tag == nil then return end
    for effectName, effect in pairs(self.effects) do
        if effect.tags[tag] ~= nil then
            self:RemoveEffect(effectName, reason)
        end
    end
end

function GFEffectable:EffectExists(effectName)
    if effectName == nil then return end
    return self.effects[effectName] or false
end

function GFEffectable:EffectRemainTime(effectName)
    if effectName == nil then return end
    return self.effects[effectName] and math.max(0, self.effects[effectName].expirationTime - GetTime()) or 0
end

function GFEffectable:GetEffectsCount()
    local all = 0
    local nonStatic = 0
    for effectName, effect in pairs(self.effects) do
        all = all + 1
        if not effect.static then
            nonStatic = nonStatic + 1
        end
    end

    return all, nonStatic
end

function GFEffectable:OnUpdate(dt)
    local currTime = GetTime()
    for effectName, effect in pairs(self.effects) do
        if effect.updateable then
            --call the effect onupdate funtion when it's needed
            if currTime >= effect.updateTime then
                effect:Update(self.inst)
                effect.updateTime = currTime + effect.tickPeriod
            end
        end

        if not effect.static then
            if currTime >= effect.expirationTime then
                self:RemoveEffect(effectName, "expire")
            end
        end
    end
end

function GFEffectable:GetDebugString()
    local currTime = GetTime()
    local str = {}
    for effectName, effect in pairs(self.effects) do
        local timer = effect.static and "static" or string.format("%.2f/%.2f", 
            effect.expirationTime - currTime, effect.expirationTime - effect.applicationTime)
        table.insert(str, string.format("[%s(%i) %s]", effectName, effect.type, timer))
    end

    local res = {}
    for resist, value in pairs(self.resists) do
        table.insert(res, string.format("[%s - %i%%]", resist, value * 100))
    end

    local resstr 
    if #res > 0 then 
        resstr = table.concat(res, ',')
    else
        resstr = "none"
    end

    local a, n = self:GetEffectsCount()
    return string.format("effects %i (%i): %s, resists: %s", a, n, table.concat(str, ", "), resstr)
end


return GFEffectable