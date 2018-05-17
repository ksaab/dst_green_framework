local GFSpell = require("gf_spell")

local function DoCast(self, doer, target, pos, spelldata)
    if pos == nil then return false end

    local flower = SpawnPrefab("flower")
    flower.Transform:SetPosition(pos.x, 0, pos.z)

    return true
end

local function SpellCheck(self, inst)
    return true --inst:HasTag("pyromaniac")
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
    GFSpell._ctor(self, "create_flower") --inheritance
    --recharge
    --self.doerRecharge = 5 --perconal cd is shared on all item for caster with same spell
    self.itemRecharge = 10
    self.spellCheckFn = SpellCheck
    self.instant = false

    self.requiredTag = "pyromaniac"

    self.spellfn = DoCast --the main spell function
    self.aicheckfn = AiCheck

    self.playerState = "gfcastwithstaff"
    self.pointer = require("pointers/circle")
end)

return Spell()