--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

local ALL_SPELLS = GF.GetSpells()
local SPELLS_IDS = GF.GetSpellsIDs()

local function EmptySpell(self)
    print(("Spell: spell %s has no cast function..."):format(self.name))
end

local Spell = Class(function(self, name)
    --both side
    self.name = name --spell name
    self.title = nil --a title for the hoverer widget
    --self.description = nil --not used
    self.iconAtals = nil
    self.icon = nil
    self.actionFlag = nil

    self.range = 12 --cast range
    self.instant = false --can be casted by one right-click or not
    self.needTarget = false
    self.passive = false --if true, spell can not be casted by players or creatures, but can be casted with gfspellcaster:CastSpell()

    self.pointer = nil --spell pointer
    self.playerState = "gfcustomcast" --player goes to this state when he try to cast the spell

    --spell checks, work for players only, AI doesn't check this
    self.preCastCheckFn = nil
    self.spellCheckFn = nil --custon check for spells (check for the day time or caster's sanity pool)
                            --args (self, caster)
    self.requiredTag = nil --fail cast if caster DOESN'T have this tag
    self.forbiddenTag = nil --fail cast if caster HAVE this tag

    --self.resourceCost = {0, 0, 0, 0}

    self.tags = {} --not sure shoud this be server only or not

    self.spellParams = {}
    self.spellVisuals = {}
    self.stateVisuals = {}
    
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

function Spell:HasTag(tag)
    return self.tags[tag] ~= nil
end

function Spell:AddTag(tag)
    self.tags[tag] = true
end

function Spell:RemoveTag(tag)
    self.tags[tag] = nil
end

--used in the spellitem component
function Spell:GetItemRecharge(item)
    if self.getRechargefn then
        local _, r = self:getRechargefn(nil, item)
        return r
    else
        return self.itemRecharge
    end
    --return self.modRechacgeFn and self:modRechacgeFn(self.itemRecharge) or self.itemRecharge
end

--used in the spellcaster component
function Spell:GetDoerRecharge(doer)
    if self.getRechargefn then
        local r = self:getRechargefn(doer)
        return r
    else
        return self.doerRecharge
    end
    --return self.modRechacgeFn and self:modRechacgeFn(self.doerRecharge) or self.doerRecharge
end

--used in stategraphs
function Spell:GetRange()
    return self.range
end

--used in stategraphs
function Spell:GetSpellParams()
    return self.spellParams
end

--used in stategraphs
function Spell:GetPlayerState()
    return self.playerState
end

--AI call this fn from the brain
function Spell:AICheckFn(ent)
    return self.aicheckfn and self:aicheckfn(ent) or false
end

function Spell:ResourceCheck(inst)
    if GFGetIsMasterSim() then
        if self.resourceCost[1] > 0 and inst.components.sanity and self.resourceCost[1] > inst.components.sanity.current then return "SANITY_FAIL"
        elseif self.resourceCost[2] > 0 and inst.components.health and self.resourceCost[2] > inst.components.health.currenthealth then return "HEALTH_FAIL" 
        elseif self.resourceCost[3] > 0 and inst.components.hunger and self.resourceCost[3] > inst.components.hunger.current then return "HUNGER_FAIL" 
        --elseif self.resourceCost[4] > 0 and self.resourceCost[4] > inst.components.health.value then return "HEALTH_FAIL" 
        end
    else
        if self.resourceCost[1] > 0 and inst.replica.sanity and self.resourceCost[1] > inst.replica.sanity.current then return "SANITY_FAIL"
        elseif self.resourceCost[2] > 0 and inst.replica.health and self.resourceCost[2] > inst.replica.health.currenthealth then return "HEALTH_FAIL" 
        elseif self.resourceCost[3] > 0 and inst.replica.hunger and self.resourceCost[3] > inst.replica.hunger.current then return "HUNGER_FAIL" 
        --elseif self.resourceCost[4] > 0 and self.resourceCost[4] > inst.replica.health.value then return "HEALTH_FAIL" 
        end
    end

    return true
end

function Spell:CheckTarget(inst, target)
    if target == nil or target:HasTag("FX") or target:HasTag("NOCLICK") or target:HasTag("shadow")
        or (target:HasTag("player") and not GFGetPVPEnabled() and self:HasTag("harmful"))
    then 
        return false 
    end

    if self.targetCheckFn then
        return self:targetCheckFn(inst, target)
    end

    return true
end

function Spell:CheckCaster(inst)
    if self.preCastCheckFn then
        return self:preCastCheckFn(inst)
    end

    return true
end

function Spell:PreCastCheck(inst, target, position)
    --[[ local resCheck = self:ResourceCheck(inst)
    if resCheck ~= true then
        return resCheck
    end ]]
    local check, reason
    check, reason = self:CheckCaster(inst)
    if not check then return false, reason end
    if self.needTarget then
        if target == nil then return false, "NEEDTARGET" end
        check, reason = self:CheckTarget(inst, target)
        if not check then return false, reason end
    end
    
    return true
end

--it is called at the CASTPELL action, if this returns false, the action will return true ("silent" fail)
--and character will say alerting phrase ("Nothing happens")
function Spell:CanBeCastedBy(inst)
    return not (self.spellCheckFn and not self:spellCheckFn(inst))
        and not (self.requiredTag and not inst:HasTag(self.requiredTag))
        and not (self.forbiddenTag and inst:HasTag(self.forbiddenTag))
end

function Spell:DoCastSpell(...)
    local res, reason = self:spellfn(...)
    return res, reason
end

--[[ function Spell:HasPostCast()
    return self.postCastfn ~= nil
end

function Spell:GetPostCastDelay()
    return self.postCastfn ~= nil
end

function Spell:DoPostCast(...)
    self.postCastfn(...)
end ]]

function Spell:__tostring()
    return string.format("spell: name: %s, id: %i, item: %.2f, doer: %.2f, state: %s", 
        self.name or "UNKNOWN", self.id or 0, self.itemRecharge or 0, self.doerRecharge or 0, self.state or "none")
end

return Spell