local SpellArchetype = require("spells/archetypes/groundslam_archetype")

local Spell = Class(SpellArchetype, function(self)
    SpellArchetype._ctor(self, "equip_groundslam") --inheritance
    self.title = STRINGS.GF.SPELLS.EQUIP_GROUND_SLAM.TITLE
    self.iconAtlas = "images/gficons.xml"
    self.icon = "groundslam.tex"
    self.pointer = 
    {
        isArrow = true,
        pointerPrefab = "gf_reticule_crackles",
        validColour = { 75 / 255, 200 / 255, 255 / 255, .3 },
        range = self.range,
    }

    if not GFGetIsMasterSim() then 
        return 
    end
    
    self.itemRecharge = 5
    self.doerRecharge = 5

    self.spellParams.damage = 50
    self.spellParams.sector = 120

    self.spellVisuals.impactOnDoer = false
    self.spellVisuals.requiredEffects = 5
    self.spellVisuals.crackleDrawerBloom = false
    self.spellVisuals.crackleDrawerColour = 2
    self.spellVisuals.castSound = "dontstarve/impacts/lava_arena/hammer"
    self.spellVisuals.impactFx = "shovel_dirt"
end)

return Spell()