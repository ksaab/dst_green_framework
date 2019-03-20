--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.
local TUNING = GLOBAL.TUNING
local STRINGS = GLOBAL.STRINGS
local ACTIONS = GLOBAL.ACTIONS
local ALL_SPELLS = GLOBAL.GF.GetSpells()
local GetString = GLOBAL.GetString
local GetActionFailString = GLOBAL.GetActionFailString
local _G = GLOBAL
--local GetQuestReminderString = GLOBAL.GetQuestReminderString

AddAction("GFCASTSPELL", STRINGS.ACTIONS.GFCASTSPELL, function(act)
    print(act)
    local doer = act.doer
    local spellName = act.spell
    local item = act.invobject
    if spellName ~= nil and doer.components.gfspellcaster ~= nil and ALL_SPELLS[spellName] ~= nil and not ALL_SPELLS[spellName].passive then 
        if doer:HasTag("player") then
            if doer.components.gfspellpointer then doer.components.gfspellpointer:Disable() end --disabling the spell pointer

            if doer:HasTag("playerghost") or doer:HasTag("corpse") then return true end --caster must be alive

            --spell must be ready to cast
            if not doer.components.gfspellcaster:IsSpellReady(spellName) then
                return false, "NOTREADY"
            elseif (item and item.components.gfspellitem and not item.components.gfspellitem:IsSpellReady(spellName)) then
                return false, "ITEMNOTREADY"
            end

            --checking for ammo, target and other conditions
            --actually this should be true almost everytime, but conditions may become false during the cast animation
            local result, reason = doer.components.gfspellcaster:PreCastCheck(spellName, act.target, act.pos)
            if not result then return false, reason end

            --this check shuold be false when caster tries to cast the spell
            --but spell can't be casted by this character with current conditions
            if not ALL_SPELLS[spellName]:CanBeCastedBy(doer) then return false, "CAST_FAILED" end

            --try to cast a spell, main spell function may return false
            return doer.components.gfspellcaster:CastSpell(spellName, act.target, act.pos, item, act.params)
        else
            --TODO
            --write some logic for non-players
            return doer.components.gfspellcaster:CastSpell(spellName, act.target, act.pos, item, act.params)
        end
    end

    return false
end)

ACTIONS.GFCASTSPELL.distance = math.huge
ACTIONS.GFCASTSPELL.priority = 10
ACTIONS.GFCASTSPELL.instant = false
STRINGS.ACTIONS.GFCASTSPELL = STRINGS.ACTIONS._GFCASTSPELL
ACTIONS.GFCASTSPELL.strfn = function(act)
    local spell = act.doer.components.gfspellpointer and act.doer.components.gfspellpointer.currentSpell or nil
    if spell ~= nil then
		return ALL_SPELLS[spell].actionFlag or "GENERIC"
	else
		return "GENERIC"
	end
end

AddAction("GFSTARTSPELLTARGETING", STRINGS.ACTIONS.GFSTARTSPELLTARGETING, function(act)
    local doer = act.doer
    local item = act.invobject
    if doer and doer.components.gfspellpointer and doer.components.gfspellcaster then
        if item and item.components.gfspellitem then
            local itemSpell = item.components.gfspellitem:GetCurrentSpell()
            if item.components.gfspellitem:IsSpellReady(itemSpell) and doer.components.gfspellcaster:IsSpellReady(itemSpell) then --check for cooldown
                local valid, reason = ALL_SPELLS[itemSpell]:CheckCaster(doer) --check for ammo, target, etc
                if valid then
                    doer.components.gfspellpointer.withItem = item
                    doer.components.gfspellpointer:Enable(itemSpell)
                else
                    --player can't cast a spell, need to push info string
                    doer:PushEvent("gfSCCastFailed", reason)
                end

                return valid
            end
        end
    end
    
    return false
end)

ACTIONS.GFSTARTSPELLTARGETING.distance = math.huge
ACTIONS.GFSTARTSPELLTARGETING.rmb = true
ACTIONS.GFSTARTSPELLTARGETING.instant = true

AddAction("GFSTOPSPELLTARGETING", STRINGS.ACTIONS.GFSTOPSPELLTARGETING, function(act)
	local doer = act.doer--doer.replica.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS)
    if doer and doer.components.gfspellpointer then
		doer.components.gfspellpointer:Disable()
		return true
	end
end)

ACTIONS.GFSTOPSPELLTARGETING.distance = math.huge
ACTIONS.GFSTOPSPELLTARGETING.rmb = true
ACTIONS.GFSTOPSPELLTARGETING.instant = true
ACTIONS.GFSTOPSPELLTARGETING.priority = 12

AddAction("GFCHANGEITEMSPELL", STRINGS.ACTIONS.GFCHANGEITEMSPELL, function(act)
    if act.invobject ~= nil
        and act.invobject.components.gfspellitem ~= nil
    then
        if act.invobject.components.gfspellitem:SwitchSpell() then
            --print(("GFCHANGEITEMSPELL: Change spell for %s to %s"):format(tostring(act.invobject), act.invobject.components.gfspellitem:GetCurrentSpell()))
            if act.doer then
                if act.doer.components.gfspellcaster then
                    act.doer.components.gfspellcaster:ForceUpdateReplicaHUD()
                end
                if act.doer.components.gfspellpointer then
                    act.doer.components.gfspellpointer:Disable()
                end
            end
        end
    end
end)

ACTIONS.GFCHANGEITEMSPELL.instant = true
ACTIONS.GFCHANGEITEMSPELL.priority = -2

AddAction("GFDRINKIT", STRINGS.ACTIONS.GFDRINKIT, function(act)
	local obj = act.target or act.invobject
	if obj ~= nil 
		and obj.components.gfdrinkable ~= nil 
		and act.doer.components.eater
		and not act.doer:HasTag("gfcantdrink") 
	then
        return act.doer.components.eater:Drink(obj)
    end
end)

AddAction("GFENHANCEITEM", STRINGS.ACTIONS.GFENHANCEITEM, function(act)
    local item, target = act.invobject, act.target
    if item and target 
        and item.components.gfitemenhancer 
        and item.components.gfitemenhancer:CheckItem(target)
    then
        if item.components.gfitemenhancer:EnhanceItem(target) then
            item.components.gfitemenhancer:OnEnhanceDone()
            return true
        end
    end
end)

AddAction("GFLETSTALK", "Talk", function(act)
    local giver = act.target
    local doer = act.doer

    if giver ~= nil and giver.components.gfinterlocutor ~= nil then
        if giver.components.gfinterlocutor:StartConversation(doer) then
            return true
        else
            return false, "TARGETBUSY"
        end
    end

    return true
end)

ACTIONS.GFLETSTALK.distance = 10
ACTIONS.GFLETSTALK.priority = 10

--ACTION COLLECTORS------
-------------------------
--TODO : May be collectors should to add a spell name to the action
--spell - equipped - point
AddComponentAction("POINT", "gfspellitem", function(inst, doer, pos, actions, right)
    if not right 
        or doer:HasTag("busy")
        or doer.replica.inventory:GetActiveItem() ~= nil --prevent casts when there is an active item
        or doer.replica.gfspellcaster == nil             --doer must be a caster
        or doer.components.gfspellpointer == nil         --we need a pointer to target spells
        or doer.components.gfspellpointer:IsEnabled()    --pointer should be disabled
    then 
        return
    end 

    local spellName = inst.replica.gfspellitem:GetCurrentSpell()
    if spellName ~= nil 
        and ALL_SPELLS[spellName] ~= nil
        and inst.replica.gfspellitem:IsSpellReady(spellName)
        and doer.replica.gfspellcaster:IsSpellReady(spellName) 
    then
        local spell = ALL_SPELLS[spellName]
        if not spell.instant then
            --non-instant spells require to enable the spell pointer
            table.insert(actions, ACTIONS.GFSTARTSPELLTARGETING)
        elseif not spell.needTarget then
            --but instant spells that require a target can't be casted on point
            table.insert(actions, ACTIONS.GFCASTSPELL)
        end
    end
end)

--spell - equipped - target
AddComponentAction("EQUIPPED", "gfspellitem", function(inst, doer, target, actions, right)
    if not right 
        or doer:HasTag("busy")
        or doer.replica.inventory:GetActiveItem() ~= nil --prevent casts when there is an active item
        or doer.replica.gfspellcaster == nil             --doer must be a caster
        or doer.components.gfspellpointer == nil         --we need a pointer to target spells
        or doer.components.gfspellpointer:IsEnabled()    --pointer should be disabled
    then 
        return
    end 

    local spellName = inst.replica.gfspellitem:GetCurrentSpell()
    if spellName ~= nil 
        and ALL_SPELLS[spellName] ~= nil
        and inst.replica.gfspellitem:IsSpellReady(spellName)
        and doer.replica.gfspellcaster:IsSpellReady(spellName) 
    then
        local spell = ALL_SPELLS[spellName]
        if not spell.instant then
            --non-instant spells require to enable the spell pointer
            table.insert(actions, ACTIONS.GFSTARTSPELLTARGETING)
        elseif not spell.needTarget or spell:CheckTarget(doer, target) then
            --need to check - is target valid for this spell or not
            --CheckTarget is a both-side function, be sure that it will not cause crashes on the client side
            table.insert(actions, ACTIONS.GFCASTSPELL)
        end
    end
end)

--spell - item in inventory (scrolls, etc)
--TODO: Write a hook for instant-targeted spells (maybe pick a target with Input:GetEntityUnderMouse and insert it as an act.target)
AddComponentAction("INVENTORY", "gfspellitem", function(inst, doer, actions, right)
    if inst.replica.equippable ~= nil                    --this collector shouldn't override the "equip" action
        or doer:HasTag("busy")
        or doer.replica.inventory:GetActiveItem() ~= nil --prevent casts when there is an active item
        or doer.replica.gfspellcaster == nil             --doer must be a caster
        or doer.components.gfspellpointer == nil         --we need a pointer to target spells
        or doer.components.gfspellpointer:IsEnabled()    --pointer should be disabled
    then 
        return
    end 

    local spellName = inst.replica.gfspellitem:GetCurrentSpell()
    if spellName ~= nil 
        and ALL_SPELLS[spellName] ~= nil
        and inst.replica.gfspellitem:IsSpellReady(spellName)
        and doer.replica.gfspellcaster:IsSpellReady(spellName) 
    then
        local spell = ALL_SPELLS[spellName]
        if not spell.instant then
            --non-instant spells require to enable the spell pointer
            table.insert(actions, ACTIONS.GFSTARTSPELLTARGETING)
        elseif not spell.needTarget then
            --but instant spells that require a target can't be casted on point
            --so we can't use instant-targeted spells here
            table.insert(actions, ACTIONS.GFCASTSPELL)
        end
    end
end)

--[[ 
AddComponentAction("INVENTORY", "gfspellitem", function(inst, doer, actions)
    if inst.replica.gfspellitem
        and inst.replica.gfspellitem:GetSpellCount() > 1
    then
        table.insert(actions, ACTIONS.GFCHANGEITEMSPELL)
    end
end) ]]

AddComponentAction("INVENTORY", "gfdrinkable", function(inst, doer, actions, right)
    if not inst.replica.equippable and
        not (doer.replica.inventory:GetActiveItem() == inst
            and doer.replica.rider ~= nil
			and doer.replica.rider:IsRiding())
		and not doer:HasTag("cantdrink")
    then
        table.insert(actions, ACTIONS.GFDRINKIT)
    end
end)

AddComponentAction("USEITEM", "gfitemenhancer", function(inst, doer, target, actions, right)
    if right then
        if target and inst.CheckEnchance and inst.CheckEnchance(target, inst) then
            table.insert(actions, ACTIONS.GFENHANCEITEM)
        end
    end
end)

AddComponentAction("SCENE", "gfinterlocutor", function(inst, doer, actions, right)
    if right 
        and inst:HasTag("hasdialog")
        and inst:IsValid() 
        and (not inst.replica.health or not inst.replica.health:IsDead()) --interlocutor must be alive
    then
        table.insert(actions, ACTIONS.GFLETSTALK)
    end
end)

--[[ AddComponentAction("SCENE", "gfquestgiver", function(inst, doer, actions, right)
    if right then
        if inst:IsValid() 
            and (not inst.replica.health or not inst.replica.health:IsDead()) --quest giver must be alive
            and inst.replica.gfquestgiver:HasQuests() --and have quests
        then
            table.insert(actions, ACTIONS.GFTALKFORQUEST)
        end
    end
end) ]]
