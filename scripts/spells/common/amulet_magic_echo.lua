local GFSpell = require("gf_spell")

local function DoCast(self, doer, target, pos, spelldata)
    return true
end

local Spell = Class(GFSpell, function(self, inst)
    GFSpell._ctor(self, "amulet_magic_echo") --inheritance
    self.title = STRINGS.GF.SPELLS.AMULET_MAGIC_ECHO.TITLE

    if not GFGetIsMasterSim() then return end
    --recharge
    self.itemRecharge = 10
    self.instant = true

    self.spellfn = DoCast --the main spell function
end)

return Spell()