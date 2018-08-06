--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

local spellList = GFSpellList

local function GetSpell(spellname)
    return spellname and spellList[spellname] or nil
end

local GFSpellCaster = Class(function(self, inst)
    self.inst = inst
    --full spell list, all non-passive spells will be added to the player's panel
    --and will be checked with creatures brain (if creature is setted as caster)
    self.spells = {} 

    self.spellsReadyTime = {}
    self.spellsRechargeDuration = {}

    self.lastCastTime = 0

    self.onClient = inst:HasTag("player") --don't need to network things if the inst isn't a player
    --self.onClient = inst._gfclientside ~= nil

    self.baseSpellPower = 1
    self.baseRecharge = 1

    self.modifiers = {} --has no handle for now, but can be used to modify spell power
    self.friendlyFireCheckFn = nil

    --set up custom sp and recharge modifiers
    self.rechargeExternal = SourceModifierList(self.inst) 
    self.spellPowerExternal = SourceModifierList(self.inst)
end)

function GFSpellCaster:ForceUpdateReplicaSpells()
    if self.onClient then
        self.inst.replica.gfspellcaster:SetSpells()
    end
end

--this function updates HUD when the weapon spell is changed
function GFSpellCaster:ForceUpdateReplicaHUD()
    if self.onClient then
        self.inst.replica.gfspellcaster._forceUpdateRecharges:push()
        if not GFGetIsDedicatedNet() and self.inst == GFGetPlayer() then
            self.inst:PushEvent("gfforcerechargewatcher")
        end
    end
end

--use this function to add spells to the entity
--AddSpell("spellname") or AddSpell({"spellname1, spellname2, ..."})
function GFSpellCaster:AddSpell(spellStr)
    if spellStr == nil then 
        print("GFSpellCaster: spell params are nil...")
        return false 
    end

    if type(spellStr) == "table" then
        for k, spellName in pairs(spellStr) do
            if not self.spells[spellName] then
                local spell = GetSpell(spellName)
                if spell then
                    self.spells[spellName] = spell
                end
            end
        end
    else
        if not self.spells[spellStr] then
            local spell = GetSpell(spellStr)
            if spell then
                self.spells[spellStr] = spell
            end
        end
    end

    if self.onClient then
        self.inst.replica.gfspellcaster:SetSpells()
    end
    
    return true
end

--use this function to remove spells from the entity
--nonUpdateReplica should be setted if couple of spell are removed
--to prevent multiple replica updates (but the replica need to be updated on the last removed spell or 
--with the ForceUpdateReplicaSpells function)
function GFSpellCaster:RemoveSpell(spellName, nonUpdateReplica)
    if spellName then
        self.spells[spellName] = nil
    end

    if not nonUpdateReplica and self.onClient then
        self.inst.replica.gfspellcaster:SetSpells()
    end
end

function GFSpellCaster:SetModifier(name, value)
    self.modifiers[name] = self.modifiers[name] ~= nil and self.modifiers[name] + value or 1 + value
end

function GFSpellCaster:GetModifier(name)
    return self.modifiers[name] or 1
end

function GFSpellCaster:PushRecharge(spellname, recharge)
    --GFDebugPrint(("GFSpellCaster: spell %s recharge started on %s, duration %.2f"):format(spellname, tostring(self.inst), recharge))
    self.spellsReadyTime[spellname] = GetTime() + recharge
    self.spellsRechargeDuration[spellname] = recharge
    if self.onClient then
        self.inst.replica.gfspellcaster:SetSpellRecharges()
    end

    self.inst:PushEvent("gfrechargestarted", {spell = spellname})
end

function GFSpellCaster:CastSpell(spellname, target, pos, item, spellParams, noRecharge)
    local spell = GetSpell(spellname)
    if spell == nil then
        GFDebugPrint(("GFSpellCaster: attemp to cast invalid spell %s"):format(spellname or "none"))
        return false
    end

    if not spell:DoCastSpell(self.inst, target, pos, item, spellParams) then
        GFDebugPrint(("GFSpellCaster: spell %s cast failed"):format(spellname))
        return false
    end

    if not noRecharge then
        local doerRecharge = spell:GetDoerRecharge(self.inst)
        if doerRecharge > 0 then
            self:PushRecharge(spellname, doerRecharge * self.baseRecharge * self.rechargeExternal:Get())
        end
    end

    if item and item.components.gfspellitem then
        item.components.gfspellitem:OnCastDone(spellname, self.inst)
    end

    if self.onClient then
        self.inst.replica.gfspellcaster._forceUpdateRecharges:push()
        if GFGetIsDedicatedNet() and self.inst == GFGetPlayer() then
            self.inst:PushEvent("gfforcerechargewatcher")
        end
    end

    self.lastCastTime = GetTime()

    self.inst:PushEvent("gfspellcastsuccess", {spell = spell, target = target, pos = pos, item = item, params = spellParams})

    return true
end

--[[ function GFSpellCaster:DoPostCast(data)
    if data.spell and spellList[data.spell] and spellList[data.spell]:HasPostCast() then
        if spellList[data.spell]:DoPostCast(self.inst, data.target, data.pos, data.invobject) then
            self.inst:PushEvent("gfpostcastsuccess", {spell = data.spell, target = data.target, pos = data.pos})
        end
    end
end ]]

--the main problem for spells is to find a correct target to prevent injuring a friend
--(ex: pigman-shaman shouldn't hit other pigman or player-leader with the lightning spell)
function GFSpellCaster:SetIsTargetFriendlyFn(fn)
    self.isTargetFriendlyfn = fn
end

function GFSpellCaster:IsTargetFriendly(target)
    if self.isTargetFriendlyfn then
        return self:isTargetFriendlyfn(target)
    end

    return false
end

--this fn checks casts from the player's spell panel
function GFSpellCaster:IsSpellValidForCaster(spellName)
    return self.spells[spellName] ~= nil
        and self:CanCastSpell(spellName)
end

function GFSpellCaster:CanCastSpell(spellname)
    --if not spellList[spellname]:CanBeCasted(self.inst) then return false end
    if spellList[spellname].passive then return false end
    
    if self.spellsReadyTime[spellname] ~= nil then
        return GetTime() > self.spellsReadyTime[spellname]
    else
        return true
    end
end

function GFSpellCaster:GetSpellRecharge(spellname)
    local r, t = 0, 0
    if self.spellsReadyTime[spellname] then
        t = self.spellsRechargeDuration[spellname]
        r = math.max(0, self.spellsReadyTime[spellname] - GetTime())
    end

    return r, t
end

function GFSpellCaster:GetSpellCount()
    return GetTableSize(self.spells)
end

--you can get character's spell power to modify a damage for your spell 
function GFSpellCaster:GetSpellPower()
    return math.max(0, self.baseSpellPower * self.spellPowerExternal:Get())
end

--pick a spell for creatures 
function GFSpellCaster:GetValidAiSpell()
    if self.lastCastTime + 1.5 > GetTime() then return end
    for spellName, spell in pairs(self.spells) do
        if self:CanCastSpell(spellName) then
            local spellData = spell:AICheckFn(self.inst)
            if spellData then
                spellData.spell = spellName
                return spellData
            end
        end
    end

    --creatures usually doesn't carry a weapon, but this allow to check it
    --not used now... commented
    --[[if self.inst.components.inventory then
        local item = self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if item and item.components.gfspellitem then
            itemSpell = item.components.gfspellitem:GetItemSpellName()
            if self:CanCastSpell(itemSpell) and item.components.gfspellitem:CanCastSpell(itemSpell) then
                local spellData = spellList[spell]:AICheckFn(self.inst)
                if spellData then
                    spellData.spell = itemSpell
                    spellData.invobject = item
                    return spellData
                end
            end
        end
    end]]

    return false
end

function GFSpellCaster:PreCastCheck(spellName)
    if spellName and spellList[spellName] then
        local preCheck = spellList[spellName]:PreCastCheck(self.inst)
        if not preCheck or type(preCheck) == "string" then
            --if STRINGS.CHARACTERS.GENERIC[preCheck] then
            if self.inst.components.talker then
                self.inst.components.talker:Say(GetString(self.inst, "PRECAST_FAILED", preCheck), 2.5, false, true, false)
            end

            return false
        end

        return true
    end
end

function GFSpellCaster:HandleIconClick(spellName)
    local inst = self.inst
    if spellName 
        and spellList[spellName] 
        and not (inst:HasTag("playerghost") or inst:HasTag("corpse"))
        and not inst.sg:HasStateTag("busy")
        and (not inst.components.rider or not inst.components.rider:IsRiding())
        and self:IsSpellValidForCaster(spellName)
        and self:PreCastCheck(spellName)
    then
        if spellList[spellName].instant then
            local act = BufferedAction(inst, inst, ACTIONS.GFCASTSPELL)
            act.spell = spellName
            inst:ClearBufferedAction()
            --inst:PushBufferedAction(act)
            inst.components.locomotor:PushAction(act, true, true)
        elseif inst.components.gfspellpointer then
            inst.components.gfspellpointer:Enable(spellName)
        end
    end
end

--don't need to update the component now...
--[[ function GFSpellCaster:OnUpdate(dt)
    local str = {}
    for k, v in pairs(self.spellsReadyTime) do
        local cooldown = v - GetTime()
        if cooldown > 0 then
            table.insert(str, ("%s ready in %.2f"):format(k, cooldown))
        end
    end
    if #str > 0 then
        print(table.concat(str))
    end
end ]]

function GFSpellCaster:OnSave(data)
    local savetable = {}
    local currTime = GetTime()
    for spellName, val in pairs(self.spellsReadyTime) do
        local rech = val - currTime
        if rech > 30 then --don't need to save short coodlwns
            savetable[spellName] = {r = rech, t = self.spellsRechargeDuration[spellName]}
        end
    end

    return {savedata = savetable}
end

function GFSpellCaster:OnLoad(data)
    if data ~= nil and data.savedata ~= nil then 
        local savedata = data.savedata
        local currTime = GetTime()
        for spellName, rech in pairs(savedata) do
            self.spellsReadyTime[spellName] = rech.r + currTime
            self.spellsRechargeDuration[spellName] = rech.t
        end

        if self.onClient then
            self.inst.replica.gfspellcaster:SetSpellRecharges()
        end
    end
end

function GFSpellCaster:GetDebugString()
    local str = {}
    local currTime = GetTime()
    for k, v in pairs(self.spells) do
        local cd = self.spellsReadyTime[k] ~= nil and self.spellsReadyTime[k] - currTime or -1
        cd = cd > 0 and string.format("%.2f/%.2f", cd, self.spellsRechargeDuration[k]) or "ready"
        table.insert(str, string.format("[%s %s]", k, cd))
    end

    return #str > 0 and table.concat(str, ", ") or "none"
end

return GFSpellCaster