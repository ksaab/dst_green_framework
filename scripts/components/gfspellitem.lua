local spellList = GFSpellList

local function GetSpell(spellname)
    return spellname and spellList[spellname] or nil
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

    inst:ListenForEvent("onpickup", ForcePushRecharges)
end)

function GFSpellItem:ForceUpdateReplicaSpells()
    self.inst.replica.gfspellitem:SetSpells()
end

function GFSpellItem:AddSpell(spellname, nonUpdateReplica)
    if GetSpell(spellname) then
        if not self.spells[spellname] then
            self.spells[spellname] = spellList[spellname]
            if not nonUpdateReplica then
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

function GFSpellItem:RemoveSpell(spellName, nonUpdateReplica)
    if spellName then
        self.spells[spellName] = nil
    end

    if not nonUpdateReplica then
        self.inst.replica.gfspellcaster:SetSpells()
    end
end

function GFSpellItem:SetItemSpell(spellname, removeOld)
    if not GetSpell(spellname) then
        print(("GFSpellItem: spell %s is not valid"):format(spellname or "none"))
        return
    end

    if spellname == self:GetItemSpell() then return end

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
    local currSpell = self:GetItemSpell()
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
end

function GFSpellItem:CanCastSpell(spellname)
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

function GFSpellItem:GetItemSpell()
    return self.itemSpell and self.itemSpell.name
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