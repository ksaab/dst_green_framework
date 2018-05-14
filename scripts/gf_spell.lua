local spelllist = GFSpellList
local spelllistcached = GFSpellNameToID

local function EmptySpell(self)
    print(("Spell: spell %s has no cast function..."):format(self.name))
end

local Spell = Class(function(self, name)
    --both side
    self.name = name

    self.range = 12 --cast range
    self.instant = true --can be casted by one click or not
    self.pointer = nil --spell pointer

    self.playerState = "gfcastwithstaff"
    self.spellCheckFn = nil

    self.tags = {}
    
    if not GFGetIsMasterSim() then 
        GFDebugPrint(("Spell: spell %s created"):format(self.name))
        return 
    end
    --server side
    self.itemRecharge = 0
    self.doerRecharge = 0

    self.rechargeModFn = nil

    self.decayPerCast = 10
    self.removeOneOnCast = true
    self.removeAllOnCast = false

    self.spellfn = EmptySpell
    self.aicheckfn = nil

    GFDebugPrint(("Spell: spell %s created"):format(self.name))
end)

function Spell:HasSpellTag(tag)
    return self.tags[tag]
end

function Spell:GetItemRecharge()
    return self.modRechacgeFn and self.modRechacgeFn(self.itemRecharge) or self.itemRecharge
end

function Spell:GetDoerRecharge()
    return self.modRechacgeFn and self.modRechacgeFn(self.doerRecharge) or self.doerRecharge
end

function Spell:GetRange()
    return self.range
end

function Spell:GetPlayerState()
    return self.playerState
end

function Spell:AICheckFn(ent)
    return self.aicheckfn and self:aicheckfn(ent) or false
end

function Spell:DoCastSpell(...)
    return self:spellfn(...)
end

function Spell:__tostring()
    return string.format("spell: name: %s, id: %i, item: %.2f, doer: %.2f, state: %s", 
        self.name or "UNKNOWN", self.id or 0, self.itemRecharge or 0, self.doerRecharge or 0, self.state or "none")
end

return Spell