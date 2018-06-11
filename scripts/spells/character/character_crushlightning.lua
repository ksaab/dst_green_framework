local SpellArchetype = require("spells/archetypes/crushlightning_archetype")

local Spell = Class(SpellArchetype, function(self)
    SpellArchetype._ctor(self, "character_crushlightning") --inheritance
    self.iconAtlas = "images/gficons.xml"
    self.icon = "crushlightning.tex"
    self.pointer = 
    {
        isArrow = true,
        pointerPrefab = "gf_reticule_crackles",
        validColour = { 230 / 255, 200 / 255, 75 / 255, .3 },
        range = self.range,
        prefersTarget = false,
    }

    if not GFGetIsMasterSim() then 
        return 
    end

    self.itemRecharge = 0
    self.doerRecharge = 10

    self.spellParams.damage = 50
    self.spellParams.sector = 60
    
    --visual
    self.spellVisuals.lightningDrawerColour = 2 --lightning colour
    self.spellVisuals.requiredEffects = 3 --num of lightnings 
    self.spellVisuals.castSound = "dontstarve/common/whip_small"
    self.spellVisuals.impactFx = "shock_fx"

    self.stateVisuals.lightColour = {42/255, 209/255, 235/255}
    self.stateVisuals.fxColour = {42/255, 209/255, 235/255}
    self.stateVisuals.sound = "dontstarve/common/rebirth_amulet_raise"
end)

return Spell()