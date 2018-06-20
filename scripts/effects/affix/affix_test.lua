local GFEffect = require("gf_effect")

local function OnApply(self, inst, effectParam)
    inst.components.locomotor:SetExternalSpeedMultiplier(inst, "affix_test", 2) 
end

local function OnRemove(self, inst)
    inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "affix_haste") 
end

local function DoCheck(self, inst, effectParam)
    return true--not inst:HasTag("player")
end

local Effect = Class(GFEffect, function(self, name)
    --[[SERVER AND CLIENT]]
    GFEffect._ctor(self, "affix_test") --inheritance
    self.type = 3 --Effect type: 0 - server side only, 1 - positive, 2 - negative, 3 - affix, 4 - enchant

    self.hoverText = "test affix" --text UNDER name
    --flags
    self.wantsHover = true

    self.savable = true

    --effect data
    self.tags = {} --can be used for resists checks, event listeners and etc
    self.applier = nil --who apply the effect
    self.stacks = 0 --current amount of stacks
    self.maxStacks = 1 --max amount of stacks
    
    --functions, feel free to set any to nil
    self.checkfn = DoCheck
    self.onapplyfn = OnApply
    self.onremovefn = OnRemove
end)


return Effect