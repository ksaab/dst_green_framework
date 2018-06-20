local GFEffect = require("gf_effect")

local function OnApply(self, inst, effectParam)
    inst.components.gfspellcaster:AddSpell("equip_crushlightning")
    inst.components.gfspellcaster:AddSpell("apply_lesser_rejuvenation")
    inst.components.gfspellcaster:AddSpell("apply_slow")
end

local function OnRemove(self, inst)
    inst.components.gfspellcaster:RemoveSpell("equip_crushlightning")
    inst.components.gfspellcaster:RemoveSpell("apply_lesser_rejuvenation")
    inst.components.gfspellcaster:RemoveSpell("apply_slow")
end

local function DoCheck(self, inst, effectParam)
    return inst.components.gfspellcaster
end

local Effect = Class(GFEffect, function(self, name)
    --[[SERVER AND CLIENT]]
    GFEffect._ctor(self, "affix_shaman") --inheritance
    self.type = 3 --Effect type: 0 - server side only, 1 - positive, 2 - negative, 3 - affix, 4 - enchant

    self.hoverText = "shaman"
    self.wantsHover = true

    self.savable = true

    --effect data
    self.tags = {} --can be used for resists checks, event listeners and etc
    self.applier = nil --who apply the effect
    
    --functions, feel free to set any to nil
    self.checkfn = DoCheck
    self.onapplyfn = OnApply
    self.onremovefn = OnRemove
end)


return Effect