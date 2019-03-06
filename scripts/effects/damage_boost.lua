local function OnApply(self, inst, eData, effectParam)
    inst.components.combat.externaldamagemultipliers:SetModifier(self.value, 1.25, self.name) 
end

local function OnRemove(self, inst)
    inst.components.combat.externaldamagemultipliers:RemoveModifier(inst, self.name) 
end

local function DoCheck(self, inst)
    return inst.components.combat
end

local function CreateEffect(id, value)
    local function fn()
        local effect = GF.CreateStatusEffect()

        effect:AddTag("positive")
        effect:AddTag("damage")

        effect.pushToReplica = true    --need to push to all clients (hover on an entity)
        effect.pushToClassified = true --need to push to the affected player (icon on the panel)

        effect.static = false
        effect.shared = "damage_boost"

        effect.baseDuration = 30
        effect.value = value

        effect.onapplyfn = OnApply
        effect.onremovefn = OnRemove
        effect.checkfn = DoCheck

        return effect
    end

    GF.StatusEffect("damage_boost_" .. id, fn)
end

local res = 
{
    CreateEffect("low",     0.05),
    CreateEffect("lowmed",  0.10),
    CreateEffect("med",     0.25),
    CreateEffect("highmed", 0.50),
    CreateEffect("high",    1.00),
}

return unpack(res)