local SpellArchetype = require("spells/archetypes/targeteffect_archetype")

local function CustomAICheck(self, inst, target)
    return inst:IsValid()
        and target:IsValid()
        and not inst:IsNear(target, 4)
end

local Spell = Class(SpellArchetype, function(self)
    SpellArchetype._ctor(self, "apply_slow") --inheritance
    self.title = "Slow"
    self.playerState = "gfcastwithstaff"
    self.instant = false
    self.needTarget = true
    self.pointer = 
    {
        pointerPrefab = "gf_reticule_nature_triangle",
        validColour = { 0.6, 0.1, 0.8, .3 },
        range = self.range,
        needTarget = true,
    }

    if not GFGetIsMasterSim() then return end

    self.spellParams = 
    {
        isPositive = false,
        effect = "slow",
        stacks = nil,
        duration = nil,
    }

    --self.spellfn = DoCast --the main spell function
    self.aiParams.customCheck = CustomAICheck
end)

return Spell()