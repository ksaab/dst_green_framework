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