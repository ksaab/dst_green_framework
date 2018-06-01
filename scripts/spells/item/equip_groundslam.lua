local SpellArchetype = require("spells/archetypes/groundslam_archetype")

local Spell = Class(SpellArchetype, function(self)
    SpellArchetype._ctor(self, "equip_groundslam") --inheritance
    self.title = STRINGS.GF.SPELLS.EQUIP_GROUND_SLAM.TITLE
    self.pointer = require("pointers/conus_crackles90")

    if not GFGetIsMasterSim() then 
        return 
    end
    
    self.itemRecharge = 50
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