local STRINGS = GLOBAL.STRINGS
local ACTIONS = GLOBAL.ACTIONS
local spellList = GLOBAL.GFSpellList

AddAction("GFCASTPELL", "Cast", function(act)
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
end)

ACTIONS.GFCASTPELL.distance = math.huge
ACTIONS.GFCASTPELL.priority = 10
ACTIONS.GFCASTPELL.instant = false
ACTIONS.GFCASTPELL.forced = true

AddAction("GFSTARTSPELLTARGETING", "Target", function(act)
	local item = act.invobject--doer.replica.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS)
	if item and item.components.gfspellpointer then
		item.components.gfspellpointer:SetEnabled(true)
		return true
	end
end)

ACTIONS.GFSTARTSPELLTARGETING.distance = math.huge
ACTIONS.GFSTARTSPELLTARGETING.rmb = true
ACTIONS.GFSTARTSPELLTARGETING.instant = true
ACTIONS.GFSTARTSPELLTARGETING.priority = 12

AddAction("GFSTOPSPELLTARGETING", "Cancel", function(act)
	local item = act.invobject--doer.replica.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS)
	if item and item.components.gfspellpointer then
		item.components.gfspellpointer:SetEnabled(false)
		return true
	end
end)

ACTIONS.GFSTOPSPELLTARGETING.distance = math.huge
ACTIONS.GFSTOPSPELLTARGETING.rmb = true
ACTIONS.GFSTOPSPELLTARGETING.instant = true
ACTIONS.GFSTOPSPELLTARGETING.priority = 12

AddAction("GFCHANGEITEMSPELL", "Change Spell", function(act)
    if act.invobject ~= nil
        and act.invobject.components.gfspellitem ~= nil
    then
        if act.invobject.components.gfspellitem:ChangeSpell() then
            print(("GFCHANGEITEMSPELL: Change spell for %s to %s"):format(tostring(act.invobject), act.invobject.components.gfspellitem:GetItemSpellName()))
            if act.doer and act.doer.components.gfspellcaster then
                act.doer.components.gfspellcaster:ForceUpdateReplicaHUD()
            end
        end
    end
end)

ACTIONS.GFCHANGEITEMSPELL.instant = true
ACTIONS.GFCHANGEITEMSPELL.priority = -2

--ACTION COLLECTORS------
-------------------------
AddComponentAction("POINT", "gfspellitem", function(inst, doer, pos, actions, right)
    if doer.sg:HasStateTag("casting") then return end -- player is casting something at this moment
    if right then
        if doer.replica.gfspellcaster then
            local itemSpell = inst.replica.gfspellitem:GetItemSpellName()
            if itemSpell ~= nil then
                --spell doesn't require a pointer
                if spellList[itemSpell].instant and not spellList[itemSpell].needTarget then
                    if inst.replica.gfspellitem:CanCastSpell(itemSpell)
                        and doer.replica.gfspellcaster:CanCastSpell(itemSpell) 
                    then
                        table.insert(actions, ACTIONS.GFCASTPELL)
                    end
                else
                --spell requires a pointer
                    if inst.components.gfspellpointer then
                        if inst.replica.gfspellitem:CanCastSpell(itemSpell)
                            and doer.replica.gfspellcaster:CanCastSpell(itemSpell) 
                        then
                            if inst.components.gfspellpointer:IsEnabled() then
                                table.insert(actions, ACTIONS.GFSTOPSPELLTARGETING)
                            else
                                table.insert(actions, ACTIONS.GFSTARTSPELLTARGETING)
                            end
                        end
                    end
                end
            end
        end
    else
        --cast spell if the pointer is enabled
        local itemSpell = inst.replica.gfspellitem:GetItemSpellName()

        if itemSpell and not spellList[itemSpell].needTarget
            and doer.replica.gfspellcaster
            and inst.components.gfspellpointer
            and inst.components.gfspellpointer:IsEnabled()
            and inst.replica.gfspellitem:CanCastSpell(itemSpell)
            and doer.replica.gfspellcaster:CanCastSpell(itemSpell) 
        then
            table.insert(actions, ACTIONS.GFCASTPELL)
        end
    end
end)

AddComponentAction("EQUIPPED", "gfspellitem", function(inst, doer, target, actions, right)
    if doer.sg:HasStateTag("casting") then return end -- player is casting something at this moment
    if right then
        if doer.replica.gfspellcaster then
            local itemSpell = inst.replica.gfspellitem:GetItemSpellName()
            if itemSpell ~= nil then
                --spell doesn't require a pointer
                if spellList[itemSpell].instant and not spellList[itemSpell].needTarget then
                    if inst.replica.gfspellitem:CanCastSpell(itemSpell)
                        and doer.replica.gfspellcaster:CanCastSpell(itemSpell) 
                    then
                        table.insert(actions, ACTIONS.GFCASTPELL)
                    end
                else
                --spell requires a pointer
                    if inst.components.gfspellpointer then
                        if inst.replica.gfspellitem:CanCastSpell(itemSpell)
                            and doer.replica.gfspellcaster:CanCastSpell(itemSpell) 
                        then
                            if inst.components.gfspellpointer:IsEnabled() then
                                table.insert(actions, ACTIONS.GFSTOPSPELLTARGETING)
                            else
                                table.insert(actions, ACTIONS.GFSTARTSPELLTARGETING)
                            end
                        end
                    end
                end
            end
        end
    else
        --cast spell if the pointer is enabled
        local itemSpell = inst.replica.gfspellitem:GetItemSpellName()

        if itemSpell
            and doer.replica.gfspellcaster
            and inst.components.gfspellpointer
            and inst.components.gfspellpointer:IsEnabled()
            and inst.replica.gfspellitem:CanCastSpell(itemSpell)
            and doer.replica.gfspellcaster:CanCastSpell(itemSpell) 
        then
            table.insert(actions, ACTIONS.GFCASTPELL)
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