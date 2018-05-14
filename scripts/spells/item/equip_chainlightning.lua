local SpellArchetype = require("spells/archetypes/chainlightning_archetype")

local Spell = Class(SpellArchetype, function(self)
    SpellArchetype._ctor(self, "equip_chainlightning") --inheritance

    if not GFGetIsMasterSim() then 
        return 
    end

    self.itemRecharge = 2
    self.doerRecharge = 2

    self.burnChance = 0
    self.damage = 35
    self.jumpCount = 4

    self.lightningDrawerColour = 1
end)

return Spell()