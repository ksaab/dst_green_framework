local spellList = GFSpellList

local function GetSpell(spellname)
    return spellname and spellList[spellname] or nil
end

local function AfterCast(self, spellName)
    local inst = self.inst
    local spell = spellList[spellName]

    if spell.removeAllOnCast then
        inst:Remove()
    elseif inst.components.finiteuses and spell.decayPerCast then
        inst.components.finiteuses:SetUses(inst.components.finiteuses:GetUses() - spell.decayPerCast)
    elseif inst.components.stackable and spell.removeOneOnCast then
        inst.components.stackable:Get():Remove()
    end
end

local function ForcePushRecharges(inst)
    if inst.replica.gfspellitem then
        inst.replica.gfspellitem:SetSpellRecharges()
    end
end

local GFSpellItem = Class(function(self, inst)
    self.inst = inst
    self.spells = {} --full spell list
    self.itemSpell = nil

    self.spellsReadyTime = {}
    self.spellsRechargeDuration = {}

    self.afterCastFn = AfterCast
    self.onCastDoneFn = nil

    inst:ListenForEvent("onpickup", ForcePushRecharges)
end)

function GFSpellItem:ForceUpdateReplicaSpells()
    self.inst.replica.gfspellitem:SetSpells()
end

function GFSpellItem:AddSpell(spellStr)
    if spellStr == nil then 
        print("GFSpellItem: spell string or array is not valid")
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

    self.inst.replica.gfspellitem:SetSpells()
    
    return true
end

--[[ function GFSpellItem:AddSpell(spellname, nonUpdateReplica)
    if GetSpell(spellname) then
        if not self.spells[spellname] then
            self.spells[spellname] = spellList[spellname]
            if self.onClient then
                self.inst.replica.gfspellitem:SetSpells()
            end
            return true
        end

        GFDebugPrint(("GFSpellItem: %s already has spell %s"):format(tostring(self.inst), spellname))
        return false
    end

    print(("GFSpellItem: spell %s is not valid"):format(spellname or "none"))
    return false
end

function GFSpellItem:AddSpells(spellArr)
    if spellArr then
        for k, v in pairs(spellArr) do
            if not self.spells[spellname] then
                local spell = GetSpell(spellname)
                if spell then
                    self.spells[spellname] = spell
                end
            end
        end

        if self.onClient then
            self.inst.replica.gfspellcaster:SetSpells()
        end

        return true
    end

    print("GFSpellCaster: spell array is not valid"))
    return false
end ]]

function GFSpellItem:RemoveSpell(spellName, nonUpdateReplica)
    if spellName then
        self.spells[spellName] = nil
    end

    if not nonUpdateReplica then
        self.inst.replica.gfspellcaster:SetSpells()
    end
end

function GFSpellItem:SetItemSpell(spellname)
    if not GetSpell(spellname) then
        print(("GFSpellItem: spell %s is not valid"):format(spellname or "none"))
        return
    end

    if spellname == self:GetItemSpellName() then return end

    if not self.spells[spellname] then
        print(("GFSpellItem: spell %s is not binded to %s"):format(spellname, tostring(self.inst)))
        return
    end
    
    self.itemSpell = spellList[spellname]
    
    if self.inst.components.gfspellpointer then
        self.inst.components.gfspellpointer:SetEnabled(false) --disable active pointer
    end
        
    self.inst.replica.gfspellitem:SetItemSpell(spellname)
end

function GFSpellItem:ChangeSpell()
    local currSpell = self:GetItemSpellName()
    local spellCount = 0
    local nextSpell 
    local firstSpell
    for k, spell in pairs(self.spells) do
        spellCount = spellCount + 1
        if spellCount == 1 then
            firstSpell = spell.name
        end
        if nextSpell then
            self:SetItemSpell(spell.name)
            return true
        end
        if spell.name == currSpell then
            nextSpell = true
        end
    end

    if spellCount > 1 then
        self:SetItemSpell(firstSpell)
        return true
    else
        GFDebugPrint(("GFSpellItem: can't switch spell on %s, there are no valid spells"):format(tostring(self.inst)))
        return false
    end
end

function GFSpellItem:PushRecharge(spellname, recharge)
    GFDebugPrint(("GFSpellItem: spell %s recharge started on %s, duration %.2f"):format(spellname, tostring(self.inst), recharge))
    
    self.spellsReadyTime[spellname] = GetTime() + recharge
    self.spellsRechargeDuration[spellname] = recharge
    self.inst.replica.gfspellitem:SetSpellRecharges()

    --self.inst:PushEvent("gfitemrechargestarted", {spell = spellname})
end

function GFSpellItem:OnCastDone(spellname, doer)
    local spell = GetSpell(spellname)
    local itemRecharge = spell:GetItemRecharge()
    if itemRecharge > 0 then
        if doer and doer.components.gfspellcaster then
            itemRecharge = itemRecharge * doer.components.gfspellcaster.baseRecharge * doer.components.gfspellcaster.rechargeExternal:Get()
        end
        self:PushRecharge(spellname,  itemRecharge)
    end

    if self.onCastDoneFn then self:onCastDoneFn(spellname) end
    self:afterCastFn(spellname)
end

function GFSpellItem:CanCastSpell(spellname)
    if spellList[spellname].passive then return false end
    
    if self.spellsReadyTime[spellname] ~= nil then
        return GetTime() > self.spellsReadyTime[spellname]
    else
        return true
    end
end

function GFSpellItem:GetSpellRecharge(spellname)
    local r, t = 0, 0
    if self.spellsReadyTime[spellname] then
        t = self.spellsRechargeDuration[spellname]
        r = math.max(0, self.spellsReadyTime[spellname] - GetTime())
    end

    return r, t
end

function GFSpellItem:GetItemSpellName()
    return self.itemSpell and self.itemSpell.name or nil
end

function GFSpellItem:GetItemSpellTitle()
    return self.itemSpell and self.itemSpell.title or nil
end

function GFSpellItem:GetItemSpell()
    return self.itemSpell
end

function GFSpellItem:GetSpellCount()
    return GetTableSize(self.spells)
end

function GFSpellItem:OnUpdate(dt)
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

function GFSpellItem:OnSave(data)
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

function GFSpellItem:OnLoad(data)
    if data ~= nil and data.savedata ~= nil then 
        local savedata = data.savedata
        local currTime = GetTime()
        for spellName, rech in pairs(savedata) do
            self.spellsReadyTime[spellName] = rech.r + currTime
            self.spellsRechargeDuration[spellName] = rech.t
        end
    end
end


function GFSpellItem:GetDebugString()
    local str = {}
    for k, v in pairs(self.spells) do
        table.insert(str, k)
    end
    if self.itemSpell ~= nil then
        table.insert(str, ("active:%s"):format(self.itemSpell.name))
    end

    return #str > 0 and table.concat(str, ", ") or "none"
end

return GFSpellItem