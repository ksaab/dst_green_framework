local GFEffect = require("gf_effect")

local function OnApply(self, inst, effectParam)
    inst.components.locomotor:SetExternalSpeedMultiplier(inst, "effect_slow", 0.75) 
end

local function OnRemove(self, inst)
    inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "effect_slow") 
end

local function DoCheck(self, inst, effectParam)
    --check for required components, tags and other things
    return inst.components.locomotor ~= nil
end

local Effect = Class(GFEffect, function(self, inst)
    GFEffect._ctor(self, "slow") --inheritance
    self.type = 2

    self.hoverText = "slowed" --text under name for pos and neg effect, text above for affixes
    self.titleText = "Slow" --title for icon
    self.descText = "Movement speed is reduced." --text for icon

    self.wantsIcon = true
    self.wantsHover = true

    if not GFGetIsMasterSim() then return end

    self.static = false

    self.tags = 
    {
        movement = true,
        negative = true,
    }

    self.baseDuration = 10

    self.onapplyfn = OnApply
    self.onremovefn = OnRemove
    self.checkfn = DoCheck
end)

return Effect