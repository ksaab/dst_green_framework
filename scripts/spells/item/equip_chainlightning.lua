local SpellArchetype = require("spells/archetypes/chainlightning_archetype")

local Spell = Class(SpellArchetype, function(self)
    SpellArchetype._ctor(self, "equip_chainlightning") --inheritance
    self.iconAtlas = "images/gficons.xml"
    self.icon = "chainlightning.tex"
    self.pointer = 
    {
        pointerPrefab = "gf_reticule_nature_triangle",
        validColour = { 1, 1, 1, .3 },
        range = self.range,
    }

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