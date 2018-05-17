local GFSpell = require("gf_spell")

local function EmptySpell(self)
    print(("Spell: spell %s has no cast function..."):format(self.name))
end

local Spell = Class(GFSpell, function(self)
    GFSpell._ctor(self, "_spell_template")  --set the "phantom" name, which will be used ONLY in the gf_spell constuctor, 
                                            --real spell name will math the file name
    --both side
    self.title = STRINGS.GF.SPELLS.INVALID_TITLE --a title for the hoverer widget

    self.range = 12 --cast range
    self.instant = true --can be casted by one right-click or not
    self.passive = false --if true, spell can not be casted by players or creatures, but can be casted with gfspellcaster:CastSpell()

    self.pointer = nil --spell pointer
    self.playerState = "gfcastwithstaff" --player goes to this state when he try to cast the spell

    --spell checks, work for players only, AI doesn't check this
    self.spellCheckFn = nil --custon check for spells (check for the day time or caster's sanity pool)
                            --args (self, caster)
    self.requiredTag = nil --fail cast if caster DOESN'T have this tag
    self.forbiddenTag = nil --fail cast if caster HAVE this tag

    self.tags = {} --not sure shoud this be server only or not
    
    if not GFGetIsMasterSim() then 
        GFDebugPrint(("Spell: spell %s created"):format(self.name))
        return 
    end
    --server side
    self.itemRecharge = 0 --can't cast the spell with item
    self.doerRecharge = 0 --caster can't cast the spell (even if he equips an another item with the same spell)

    self.getRechargefn = nil    --if recharge values are non-static (ex: shorter at the night). 
                                --It must return 2 values (doerRecharge, itemRecharge)

    --item decay and removing after the spell is casted
    self.decayPerCast = 1 --finiteuses durability loss
    self.removeOneOnCast = true --stackable stack loss
    self.removeAllOnCast = false --remove the item on cast

    --channeling doesn't work for now
    --self.channelTickfn = nil --called every tick
    --self.channelDonefn = nil --called when channeling is complete
    --self.channelDuration = nil --max channeling duration
    --self.channelTickPeriod = nil --how often channelTickfn will be called
    
    self.castTime = 0 --cast time duration (works only for states that supports it)

    self.spellfn = EmptySpell   --spell logic, the main thing here
                                --args (self, caster, target, pos)
    self.aicheckfn = nil    --AI call this fn from the brain
                            --args (self, caster)
end)

return Spell()