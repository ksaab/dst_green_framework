local SpellArchetype = require("spells/archetypes/crushlightning_archetype")

local Spell = Class(SpellArchetype, function(self)
    SpellArchetype._ctor(self, "equip_crushlightning") --inheritance
    self.title = STRINGS.GF.SPELLS.EQUIP_CRUSHLIGHTNING.TITLE
    self.pointer = require("pointers/conus_lightning90")

    if not GFGetIsMasterSim() then 
        return 
    end

    self.itemRecharge = 5
    self.doerRecharge = 5

    self.spellParams.damage = 50
    self.spellParams.sector = 120
    
    --visual
    --self.spellVisuals.lightningDrawerColour = 5 --lightning colour
    self.spellVisuals.requiredEffects = 4 --num of lightnings 
    self.spellVisuals.castSound = "dontstarve/common/whip_small"
    self.spellVisuals.impactFx = "shock_fx"

end)

return Spell()