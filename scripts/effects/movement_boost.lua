local function OnApply(self, inst, eData, effectParam)
    inst.components.locomotor:SetExternalSpeedMultiplier(inst, self.name, self.value) 
end

local function OnRemove(self, inst)
    inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, self.name) 
end

local function DoCheck(self, inst)
    return inst.components.locomotor
end

local function CreateEffect(positive, id, value)
    local function fn()
        local effect = GF.CreateStatusEffect()

        effect:AddTag(positive and "positive" or "negative")
        effect:AddTag("movement")

        effect.static = false
        effect.shared = positive and "movement_boost" or "movement_penalty"

        effect.baseDuration = 10
        effect.value = value

        effect.onapplyfn = OnApply
        effect.onremovefn = OnRemove
        effect.checkfn = DoCheck

        return effect
    end

    GF.StatusEffect((positive and "movement_boost_" or "movement_penalty_") .. id, fn)
end

local res = 
{
    CreateEffect(true, "low",     1.05),
    CreateEffect(true, "lowmed",  1.10),
    CreateEffect(true, "med",     1.25),
    CreateEffect(true, "highmed", 2.50),
    CreateEffect(true, "high",    2.00),

    CreateEffect(false, "low",     0.95),
    CreateEffect(false, "lowmed",  0.90),
    CreateEffect(false, "med",     0.75),
    CreateEffect(false, "highmed", 0.50),
    CreateEffect(false, "high",    0.10),
}

return unpack(res)