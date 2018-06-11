local SpellArchetype = require("spells/archetypes/crushlightning_archetype")

local Spell = Class(SpellArchetype, function(self)
    SpellArchetype._ctor(self, "equip_crushlightning") --inheritance
    self.iconAtlas = "images/gficons.xml"
    self.icon = "crushlightning.tex"
    self.pointer = 
    {
        isArrow = true,
        pointerPrefab = "gf_reticule_crackles",
        validColour = { 75 / 255, 200 / 255, 255 / 255, .3 },
        range = self.range,
        prefersTarget = false,
    }

    if not GFGetIsMasterSim() then 
        return 
    end

    self.itemRecharge = 10
    self.doerRecharge = 5

    self.spellParams.damage = 50
    self.spellParams.sector = 120
    
    --visual
    --self.spellVisuals.lightningDrawerColour = 5 --lightning colour
    self.spellVisuals.requiredEffects = 4 --num of lightnings 
    self.spellVisuals.castSound = "dontstarve/common/whip_small"
    self.spellVisuals.impactFx = "shock_fx"

    self.stateVisuals.lightColour = {42/255, 209/255, 235/255}
    self.stateVisuals.fxColour = {42/255, 209/255, 235/255}
    self.stateVisuals.sound = "dontstarve/common/rebirth_amulet_raise"
end)

return Spell()