local spellList = GFSpellList

local function GetSpell(spellname)
    return spellname and spellList[spellname] or nil
end

local GFSpellCaster = Class(function(self, inst)
    self.inst = inst
    self.spells = {} --full spell list
    --self.activeSpells = {}

    self.spellsReadyTime = {}
    self.spellsRechargeDuration = {}

    self.onClient = inst:HasTag("gfscclientside")

    self.baseSpellPower = 1
    self.baseRecharge = 1

    self.flags = {}
    self.friendlyFireCheckFn = nil

    self.rechargeExternal = SourceModifierList(self.inst)
    self.spellPowerExternal = SourceModifierList(self.inst)
end)

function GFSpellCaster:ForceUpdateReplicaSpells()
    if self.onClient then
        self.inst.replica.gfspellcaster:SetSpells()
    end
end

function GFSpellCaster:ForceUpdateReplicaHUD()
    if self.onClient then
        self.inst.replica.gfspellcaster._forceUpdateRecharges:push()
        if not GFGetDedicatedNet() and self.inst == GFGetPlayer() then
            self.inst:PushEvent("gfforcerechargewatcher")
        end
    end
end

function GFSpellCaster:AddSpell(spellStr)
    if spellStr == nil then 
        print("GFSpellCaster: spell string or array is not valid")
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

function GFSpellCaster:RemoveSpell(spellName, nonUpdateReplica)
    if spellName then
        self.spells[spellName] = nil
    end

    if not nonUpdateReplica and self.onClient then
        self.inst.replica.gfspellcaster:SetSpells()
    end
end

function GFSpellCaster:PushRecharge(spellname, recharge)
    GFDebugPrint(("GFSpellCaster: spell %s recharge started on %s, duration %.2f"):format(spellname, tostring(self.inst), recharge))
    self.spellsReadyTime[spellname] = GetTime() + recharge
    self.spellsRechargeDuration[spellname] = recharge
    if self.onClient then
        self.inst.replica.gfspellcaster:SetSpellRecharges()
    end

    self.inst:PushEvent("gfrechargestarted", {spell = spellname})
end

function GFSpellCaster:CastSpell(spellname, target, pos, item, noRecharge)
    local spell = GetSpell(spellname)
    if spell == nil then
        print(("GFSpellCaster: attemp to cast invalid spell %s"):format(spellname or "none"))
        return false
    end

    if not spell:DoCastSpell(self.inst, target, pos, item) then
        print(("GFSpellCaster: spell %s cast failed"):format(spellname))
        return false
    end

    if not noRecharge then
        local doerRecharge = spell:GetDoerRecharge()
        if doerRecharge > 0 then
            self:PushRecharge(spellname, doerRecharge * self.baseRecharge * self.rechargeExternal:Get())
        end
    end

    if item and item.components.gfspellitem then
        item.components.gfspellitem:OnCastDone(spellname, self.inst)
    end

    if self.onClient then
        self.inst.replica.gfspellcaster._forceUpdateRecharges:push()
        if GFGetDedicatedNet() and self.inst == GFGetPlayer() then
            self.inst:PushEvent("gfforcerechargewatcher")
        end
    end

    self.inst:PushEvent("gfspellcastsuccess", {spell = spell, target = target, pos = pos})
    return true
end

function GFSpellCaster:SetIsTargetFriendlyFn(fn)
    self.isTargetFriendlyfn = fn
end

function GFSpellCaster:IsTargetFriendly(target)
    if self.isTargetFriendlyfn then
        return self:isTargetFriendlyfn(target)
    end

    return false
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

function GFSpellCaster:GetSpellPower()
    return math.max(0, self.baseSpellPower * self.spellPowerExternal:Get())
end

function GFSpellCaster:GetValidAiSpell()
    for spellName, spell in pairs(self.spells) do
        if self:CanCastSpell(spellName) then
            local spellData = spell:AICheckFn(self.inst)
            if spellData then
                spellData.spell = spellName
                return spellData
            end
        end
    end

    if self.inst.components.inventory then
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
    end

    return false
end

function GFSpellCaster:OnUpdate(dt)
    local str = {}
    for k, v in pairs(self.spellsReadyTime) do
        local cooldown = v - GetTime()
        if cooldown > 0 then
            table.insert(str, ("%s ready in %.2f"):format(k, cooldown))
        end
    end
    if #str > 0 then
        GFDebugPrint(table.concat(str))
    end
end

function GFSpellCaster:OnSave(data)
    local savetable = {}
    local currTime = GetTime()
    for spellName, val in pairs(self.spellsReadyTime) do
        local rech = val - currTime
        if rech > 10 then
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
    for k, v in pairs(self.spells) do
        table.insert(str, k)
    end
    if self.itemSpell ~= nil then
        table.insert(str, ("active:%s"):format(self.itemSpell))
    end

    return #str > 0 and table.concat(str, ", ") or "none"
end

return GFSpellCaster