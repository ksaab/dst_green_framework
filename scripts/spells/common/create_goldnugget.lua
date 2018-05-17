local GFSpell = require("gf_spell")

local function DoCast(self, doer, target, pos, spelldata)
    if pos == nil then return false end

    local flower = SpawnPrefab("goldnugget")
    flower.Transform:SetPosition(pos.x, 0, pos.z)

    return true
end

local function AiCheck(self, inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local res = 
    {
        pos = GFGetValidSpawnPosition(x, y, z, 10)
    }

    return res
end

local Spell = Class(GFSpell, function(self, inst)
    GFSpell._ctor(self, "create_goldnugget") --inheritance
    --recharge
    --self.doerRecharge = 5 --perconal cd is shared on all item for caster with same spell
    self.itemRecharge = 10

    self.instant = false
    --self.passive = true
    self.forbiddenTag = "valkyrie"

    self.spellfn = DoCast --the main spell function
    self.aicheckfn = AiCheck

    self.playerState = "gfcastwithstaff"
    self.pointer = require("pointers/thinarrow")
end)

return Spell()