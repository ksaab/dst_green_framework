local GFSpell = require("gf_spell")

local function DoCast(self, doer, target, pos, item, spellData)
    if spellData and spellData.spellName then
        doer.components.gfspellcaster:CastSpell(spellData.spellName, target, pos, nil, nil, true)
    end

    return true
end

local Spell = Class(GFSpell, function(self, inst)
    GFSpell._ctor(self, "amulet_magic_echo") --inheritance
    self.title = STRINGS.GF.SPELLS.AMULET_MAGIC_ECHO.TITLE

    --recharge
    self.itemRecharge = 10
    self.instant = true

    self.spellfn = DoCast --the main spell function
end)

return Spell()