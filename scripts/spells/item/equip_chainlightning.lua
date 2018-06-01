local SpellArchetype = require("spells/archetypes/chainlightning_archetype")

local Spell = Class(SpellArchetype, function(self)
    SpellArchetype._ctor(self, "equip_chainlightning") --inheritance
    self.title = STRINGS.GF.SPELLS.EQUIP_CHAINLIGHTNING.TITLE

    if not GFGetIsMasterSim() then 
        return 
    end

    self.itemRecharge = 2
    self.doerRecharge = 2

    --params
    self.spellParams.burnChance = 0
    self.spellParams.damage = 35
    self.spellParams.jumpCount = 2
    
    --visual
    --self.spellVisuals.lightningDrawerColour = 1
    self.spellVisuals.impactFx = "shock_fx"
    self.spellVisuals.impactSound = nil

end)

return Spell()