--pointer params:
--[[-------------------------
pointerPrefab = "reticuleaoe", --prefab
isArrow = false, --if false follows the cursor, if true is bound to the caster and turns to the cursor
needTarget = false, --set to true if the spell that requires a target
prefersTarget = true, --if true targets entity under cursor (mouse) or search for a target in front of the player (gamepad)
range = 8, --range for a gamepad, do not change it without need
maxRange = 8, --range for a gamepad, do not change it without need
validColour = { 0, 1, 0.3, 0.3 },
invalidColour = { 1, 0, 0, 0.3 },
noTargetColour = { 1, 0, 0, 0.3 },
]]---------------------------

local function EmptySpell(spell, caster, target, pos, item)
    --use GetSpellPower() and IsTargetFriendly(target) from caster.components.gfspellcaster
    --to make your spell really cool
    print(("Spell: spell %s has no cast function..."):format(spell.name))
end

local function fn()
    local spell = GF.CreateSpell()

    --textures - used on the spell panel widget
    spell.iconAtals = nil --atlas for spell icon
    spell.icon = nil      --texture name

    spell.actionFlag = nil  --defines action string (cast, jump, throw) - check strings.lua
                            --it's possible to add custom flags - STRINGS.ACTIONS._GFCASTSPELL.<FLAG> = <STRING>
    spell.pointer = { pointerPrefab = "reticuleaoe" } --spell pointer, check the parameters above
    spell.playerState = "gfcustomcast"  --player goes to this state when he try to cast the spell

    --spell strings should be defined in global STRINGS
    --STRINGS.GF.SPELLS.MY_FIRST_SPELL = {}
    --STRINGS.GF.SPELLS.MY_FIRST_SPELL.TITLE = "My Spell"
    --STRINGS.GF.SPELLS.MY_FIRST_SPELL.DESC = "It's my spell."
    --where MY_FIRST_SPELL is the spell name (check the last string of this file) in the upper case

    --spell flags
    spell.instant = false       --can be casted by one right-click or not
    spell.needTarget = false    --is target necessary or not, don't forget to the same option in pointer
    spell.passive = false       --if true, spell can not be casted by players or creatures, but can be casted with gfspellcaster:CastSpell()
    
    --some states supports visuals for spells
    spell.stateVisuals = nil
    
    --mumbers
    spell.range = 12        --cast range (actually defines distance for the "cast spell" action)
    spell.itemRecharge = 0  --item cooldown
    spell.doerRecharge = 0  --caster cooldown
    spell.castTime = 0      --cast time duration (works only for states that supports it)

    spell.getRechargefn = nil    --function, if recharge values are non-static (ex: shorter at the night). 
                                 --must return 2 values (doerRecharge, itemRecharge)

    --item decay and removing after the spell is casted
    spell.decayPerCast = 1 --finiteuses durability loss
    spell.removeOneOnCast = true --stackable stack loss
    spell.removeAllOnCast = false --remove the item on cast

    --spell checks, work for players only, AI doesn't check this
    spell.preCastCheckFn = nil
    spell.spellCheckFn = nil --custon check for spells (check for the day time or caster's sanity pool), args (spell, caster)
                            
    spell.requiredTag = nil  --fail cast if caster DOESN'T have this tag
    spell.forbiddenTag = nil --fail cast if caster HAS this tag

    --spell main function
    spell.spellfn = EmptySpell   --spell logic, the main thing here, args (spell, caster, target, pos)

    --AI - this requires valid spell caster creature (brain, state, action handler and component)
    --AI calls this fn from the brain, args (spell, caster)
    --this function must return false (if the spell can't be casted) or a correct table value: 
    --{ target = target entity for spell, pos = target position for spell, distance = valid distance }
    --spell main function will be called with this values
    spell.aicheckfn = nil 
    
    --some spells presets use this in thier main functions
    spell.spellParams = nil
    spell.spellVisuals = nil

    return spell
end

return GF.Spell("my_first_spell", fn)