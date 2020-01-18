--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

local GFSpell = require("gf_class_spell")
local ThrowableParams = GF.ThrowableParams

local function DoCast(self, doer, target, position, item)
    --print(self, doer, target, position, item)
    if position == nil 
        or item == nil 
        or item.components.equippable == nil
        or item.components.equippable.equipslot ~= EQUIPSLOTS.HANDS 
    then 
        return false 
    end

    local dummy = SpawnPrefab("gf_throw_dummy")

    if dummy ~= nil then
        doer.components.inventory:Unequip(EQUIPSLOTS.HANDS)
        doer.components.inventory:DropItem(item)

        local params = ThrowableParams[item.prefab]
        if params ~= nil then
            if params == "hspin" then
                dummy:MakeHorizontalProjectile()
            elseif params == "vspin" then
                dummy:MakeVerticalProjectile()
            elseif params == "rfly" then
                dummy:MakeReverceProjectile()
            else
                dummy:MakeFlyingProjectile()
            end
        else
            if item:HasTag("hammer") then
                dummy:MakeHorizontalProjectile()
            elseif item:HasTag("axe") then
                dummy:MakeVerticalProjectile()
            else
                dummy:MakeFlyingProjectile()
            end
        end

        dummy:Launch(position, doer, item)

        return true
    end

    return false
end

local Spell = Class(GFSpell, function(self)
    GFSpell._ctor(self, "throw_archetype")  --set the "phantom" name, which will be used ONLY in the gf_spell constuctor, 
                                            --real spell name will math the file name
    --both side
    self.title = STRINGS.GF.SPELLS.SHOOT.TITLE --a title for the hoverer widget
    self.actionFlag = "THROW"

    self.range = math.huge --cast range

    self.pointer = nil
    self.playerState = "gfthrow"

    self.decayPerCast = 0

    self.spellfn = DoCast   --spell logic, the main thing here
                                --args (self, caster, target, pos)
    self.aicheckfn = nil    --AI call this fn from the brain
                            --args (self, caster)
end)

return Spell