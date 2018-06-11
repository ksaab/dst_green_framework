local STRINGS = GLOBAL.STRINGS
local ACTIONS = GLOBAL.ACTIONS
local spellList = GLOBAL.GFSpellList

--[[ AddAction("GFCASTSPELL", "Cast", function(act)
    if act.doer.components.gfspellcaster then 
        if act.doer:HasTag("player") then
            local item = act.invobject
            if item ~= nil then
                if item.components.gfspellpointer then
                    item.components.gfspellpointer:SetEnabled(false)
                end
                if item.components.gfspellitem then
                    local itemSpell = item.components.gfspellitem:GetItemSpellName()
                    if not spellList[itemSpell]:CanBeCastedBy(act.doer) then
                        act.doer.components.talker:Say("Something wrong", 2.5)
                        return true
                    end
                    return itemSpell 
                        and act.doer.components.gfspellcaster:CanCastSpell(itemSpell)
                        and item.components.gfspellitem:CanCastSpell(itemSpell)
                        and act.doer.components.gfspellcaster:CastSpell(itemSpell, act.target, act.pos, item)
                        or false
                end
            end
        elseif act.spell ~= nil then
            return act.doer.components.gfspellcaster:CastSpell(act.spell, act.target, act.pos)
        end
    end

	return false
end) ]]

AddAction("GFCASTSPELL", STRINGS.ACTIONS.GFCASTSPELL.GENERIC, function(act)
    local doer = act.doer
    local spellName = act.spell
    local item = act.invobject
    if spellName ~= nil and doer.components.gfspellcaster ~= nil and spellList[spellName] ~= nil then 
        if doer:HasTag("player") then
            if doer.components.gfspellpointer then
                doer.components.gfspellpointer:Disable()
            end
            if not spellList[spellName]:CanBeCastedBy(doer) then
                if doer.components.talker then
                    doer.components.talker:Say("Something wrong", 2.5)
                end
                return true
            end
            return doer.components.gfspellcaster:CanCastSpell(spellName)
                and not (item and item.components.gfspellitem and not item.components.gfspellitem:CanCastSpell(spellName))
                and not (doer:HasTag("playerghost") or doer:HasTag("corpse"))
                and doer.components.gfspellcaster:CastSpell(spellName, act.target, act.pos, item)
                or false
        else
            return doer.components.gfspellcaster:CastSpell(spellName, act.target, act.pos, item)
        end
    end

    return false
end)

ACTIONS.GFCASTSPELL.distance = math.huge
ACTIONS.GFCASTSPELL.priority = 10
ACTIONS.GFCASTSPELL.instant = false
--ACTIONS.GFCASTSPELL.forced = true
--ACTIONS.GFCASTSPELL.canforce = true

--[[ AddAction("GFSTARTSPELLTARGETING", "Target", function(act)
	local item = act.invobject--doer.replica.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS)
	if item and item.components.gfspellpointer then
		item.components.gfspellpointer:SetEnabled(true)
		return true
	end
end) ]]

AddAction("GFSTARTSPELLTARGETING", STRINGS.ACTIONS.GFSTARTSPELLTARGETING, function(act)
    local doer = act.doer--doer.replica.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS)
    local item = act.invobject
    if doer and doer.components.gfspellpointer then
        if item and item.components.gfspellitem then
            local itemSpell = item.components.gfspellitem:GetItemSpellName()
            if item.components.gfspellitem:CanCastSpell(itemSpell) then
                print("turn on")
                doer.components.gfspellpointer.withItem = true
                doer.components.gfspellpointer:Enable(itemSpell)
                return true
            end
        end
    end
    
    return false
end)

ACTIONS.GFSTARTSPELLTARGETING.distance = math.huge
ACTIONS.GFSTARTSPELLTARGETING.rmb = true
ACTIONS.GFSTARTSPELLTARGETING.instant = true
--ACTIONS.GFSTARTSPELLTARGETING.priority = 10

--[[ AddAction("GFSTOPSPELLTARGETING", "Cancel", function(act)
	local item = act.invobject--doer.replica.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS)
	if item and item.components.gfspellpointer then
		item.components.gfspellpointer:SetEnabled(false)
		return true
	end
end) ]]

AddAction("GFSTOPSPELLTARGETING", STRINGS.ACTIONS.GFSTOPSPELLTARGETING, function(act)
	local doer = act.doer--doer.replica.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS)
    if doer and doer.components.gfspellpointer then
        print("turn off")
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
        if act.invobject.components.gfspellitem:ChangeSpell() then
            print(("GFCHANGEITEMSPELL: Change spell for %s to %s"):format(tostring(act.invobject), act.invobject.components.gfspellitem:GetItemSpellName()))
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
		and act.doer:HasTag("gfcandrink") 
	then
        return act.doer.components.eater:Drink(obj)
    end
end)

--ACTION COLLECTORS------
-------------------------
AddComponentAction("POINT", "gfspellitem", function(inst, doer, pos, actions, right)
    if doer.sg:HasStateTag("casting") -- player is casting something at this moment
        or doer.replica.inventory:GetActiveItem() ~= nil --prevent casts with an active item
        or doer.replica.gfspellcaster == nil --doer must be a caster
        or doer.components.gfspellpointer == nil --and have a pointer
    then 
        return
    end 

    local gfsp = doer.components.gfspellpointer
    local spellName
    local spell

    if right and not gfsp:IsEnabled() then
        spellName = inst.replica.gfspellitem:GetItemSpellName()
        if spellName ~= nil then
            spell = spellList[spellName]
            if spell 
                and inst.replica.gfspellitem:CanCastSpell(spellName)
                and doer.replica.gfspellcaster:CanCastSpell(spellName) 
            then
                if not spell.instant then
                    table.insert(actions, ACTIONS.GFSTARTSPELLTARGETING)
                elseif not spell.needTarget then
                    table.insert(actions, ACTIONS.GFCASTSPELL)
                end
            end
        end
    end
end)

AddComponentAction("EQUIPPED", "gfspellitem", function(inst, doer, target, actions, right)
    if doer.sg:HasStateTag("casting") -- player is casting something at this moment
        or doer.replica.inventory:GetActiveItem() ~= nil --prevent casts with an active item
        or doer.replica.gfspellcaster == nil --doer must be a caster
        or doer.components.gfspellpointer == nil --and have a pointer
    then 
        return
    end 

    local gfsp = doer.components.gfspellpointer
    local spellName
    local spell

    if right and not gfsp:IsEnabled() then
        spellName = inst.replica.gfspellitem:GetItemSpellName()
        if spellName ~= nil then
            spell = spellList[spellName]
            if spell 
                and inst.replica.gfspellitem:CanCastSpell(spellName)
                and doer.replica.gfspellcaster:CanCastSpell(spellName) 
            then
                if not spell.instant then
                    table.insert(actions, ACTIONS.GFSTARTSPELLTARGETING)
                else
                    table.insert(actions, ACTIONS.GFCASTSPELL)
                end
            end
        end
    end
end)

AddComponentAction("INVENTORY", "gfspellitem", function(inst, doer, actions)
    if inst.replica.gfspellitem
        and inst.replica.gfspellitem:GetSpellCount() > 1
    then
        table.insert(actions, ACTIONS.GFCHANGEITEMSPELL)
    end
end)

AddComponentAction("INVENTORY", "gfdrinkable", function(inst, doer, actions, right)
    if (right or inst.replica.equippable == nil) and
        not (doer.replica.inventory:GetActiveItem() == inst
            and doer.replica.rider ~= nil
			and doer.replica.rider:IsRiding())
		and doer:HasTag("gfcandrink")
    then
        table.insert(actions, ACTIONS.GFDRINKIT)
    end
end)