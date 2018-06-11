local SpellArchetype = require("spells/archetypes/targeteffect_archetype")

local function CustomAICheck(self, inst, target)
    return inst:IsValid()
        and target:IsValid()
        and not target.components.health:IsDead()
        and target.components.health:GetPercent() < 0.75
end

local Spell = Class(SpellArchetype, function(self)
    SpellArchetype._ctor(self, "apply_lesser_rejuvenation") --inheritance
    self.title = "Lesser rejuvenation"
    self.iconAtlas = "images/gficons.xml"
    self.icon = "lesser_rejuvenation.tex"
    self.playerState = "gfcastwithstaff"
    self.pointer = 
    {
        pointerPrefab = "gf_reticule_nature_triangle",
        validColour = { 0, 1, 0.1, .3 },
        range = self.range,
    }
    --self.instant = true

    if not GFGetIsMasterSim() then return end

    self.spellParams.isPositive = true
    self.spellParams.effect = "lesser_rejuvenation"
    self.spellParams.stacks = nil
    self.spellParams.duration = nil

    self.spellVisuals.castSound = "ancienttable_activate"
    --self.spellfn = DoCast --the main spell function
    self.aiParams.customCheck = CustomAICheck
end)

return Spell()