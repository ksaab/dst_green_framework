local SpellArchetype = require("spells/archetypes/chainlightning_archetype")

local Spell = Class(SpellArchetype, function(self)
    SpellArchetype._ctor(self, "character_chainlightning") --inheritance
    self.iconAtlas = "images/gficons.xml"
    self.icon = "chainlightning.tex"
    self.pointer = 
    {
        pointerPrefab = "gf_reticule_nature_triangle",
        validColour = { 230 / 255, 200 / 255, 75 / 255, .3 },
        range = self.range,
    }

    self.itemRecharge = 0
    self.doerRecharge = 4

    self.castTime = 1

    --params
    self.spellParams.burnChance = 0
    self.spellParams.damage = 35
    self.spellParams.jumpCount = 4
    
    --visual
    self.spellVisuals.lightningDrawerColour = 2
    self.spellVisuals.impactFx = "shock_fx"
    self.spellVisuals.impactSound = nil

end)

return Spell()