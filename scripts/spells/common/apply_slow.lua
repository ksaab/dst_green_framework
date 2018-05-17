local SpellArchetype = require("spells/archetypes/targeteffect_archetype")

local function CustomAICheck(target)
    return not target.components.health:IsDead()
        and target.components.health:GetPercent() < 0.75
end

local Spell = Class(SpellArchetype, function(self)
    SpellArchetype._ctor(self, "apply_slow") --inheritance
    self.playerState = "gfcastwithstaff"

    if not GFGetIsMasterSim() then return end

    self.spellParams = 
    {
        isPositive = false,
        effect = "slow",
        stacks = nil,
        duration = nil,
    }

    --self.spellfn = DoCast --the main spell function
    --self.aiParams.customCheck = CustomAICheck
end)

return Spell()