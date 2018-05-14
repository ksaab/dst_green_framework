local SpellArchetype = require("spells/archetypes/groundslam_archetype")

local Spell = Class(SpellArchetype, function(self)
    SpellArchetype._ctor(self, "equip_groundslam") --inheritance

    if not GFGetIsMasterSim() then 
        return 
    end
    
    self.itemRecharge = 5
    self.doerRecharge = 5

    self.sector = 180
    self.requiredEffects = 6

    self.impactOnDoer = false
    self.crackleDrawerBloom = false
    self.crackleDrawerColour = 2
end)

return Spell()