local SpellArchetype = require("spells/archetypes/crushlightning_archetype")

local Spell = Class(SpellArchetype, function(self)
    SpellArchetype._ctor(self, "equip_crushlightning") --inheritance

    if not GFGetIsMasterSim() then 
        return 
    end

    self.itemRecharge = 5
    self.doerRecharge = 5

    self.damage = 50
    self.sector = 120

    self.requiredEffects = 4
    self.lightningDrawerColour = 3
end)

return Spell()