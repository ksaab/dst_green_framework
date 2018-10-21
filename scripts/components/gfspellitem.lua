--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

local ALL_SPELLS = GFSpellList

local function AfterCast(self, sName)
    local inst = self.inst
    local sInst = ALL_SPELLS[sName]

    if sInst.removeAllOnCast then
        inst:Remove()
    elseif inst.components.finiteuses and sInst.decayPerCast then
        inst.components.finiteuses:SetUses(inst.components.finiteuses:GetUses() - sInst.decayPerCast)
    elseif inst.components.stackable and sInst.removeOneOnCast then
        inst.components.stackable:Get():Remove()
    end
end

local function ForcePushRecharges(inst)
    if inst.replica.gfspellitem then inst.replica.gfspellitem:UpdateRecharges() end
end

local GFSpellItem = Class(function(self, inst)
    self.inst = inst

    self.spells = {} --all spells
    self.spellData = {} --current active spell
    self.currentSpell = nil
    
    self.AfterCastFn = AfterCast
    self.onCastDoneFn = nil

    inst:ListenForEvent("onpickup", ForcePushRecharges)
    inst:ListenForEvent("equipped", ForcePushRecharges)

    if self.inst.replica.gfspellitem then 
        self.inst.replica.gfspellitem.spells = self.spells
        self.inst.replica.gfspellitem.spellData = self.spellData
    end
end)

-----------------------------------------
--Safe methods---------------------------
-----------------------------------------

--set spell list
function GFSpellItem:AddSpell(sName)
    if sName == nil or ALL_SPELLS[sName] == nil then return false end
    self.spells[sName] = true
    if self.currentSpell == nil then self:SetCurrentSpell(sName) end
    self.inst.replica.gfspellitem:UpdateSpells()
end

function GFSpellItem:AddSpells(spells)
    if spells == nil then return false end
    for i = 1, #spells do
        self:AddSpell(spells[i])
    end
end

function GFSpellItem:RemoveSpell(sName)
    self.spells[sName] = nil
    self.inst.replica.gfspellitem:UpdateSpells()
end

--set current spell
function GFSpellItem:SetCurrentSpell(sName)
    if sName == nil or ALL_SPELLS[sName] == nil or self.spells[sName] == nil then return false end
    self.currentSpell = sName
    self.inst.replica.gfspellitem:UpdateCurrentSpell(sName)
end

function GFSpellItem:GetCurrentSpell()
    return self.currentSpell
end

function GFSpellItem:ForceUpdateReplicaSpells()
    self.inst.replica.gfspellitem:UpdateSpells()
end

--cast stuff
function GFSpellItem:PushRecharge(sName, duration)
    if sName == nil or ALL_SPELLS[sName] == nil then return false end

    local sData = 
    {
        endTime = GetTime() + duration,
        startTime = GetTime()
    }

    self.spellData[sName] = sData
    self.inst.replica.gfspellitem:UpdateRecharges()

    self.inst:PushEvent("gfSIRechargeStarted", {sName = sName})
end

function GFSpellItem:ReduceRecharge(sName, reduce)
    if sName == nil or ALL_SPELLS[sName] == nil or self.spellData[sName] == nil then return false end
    
    local sData = self.spellData[sName]
    sData.endTime = sData.endTime - reduce
    
    self.inst.replica.gfspellitem:PushRecharge(sName, sData.endTime - GetTime(), GetTime() - sData.startTime)
end

function GFSpellItem:CanCastSpell(sName)
    if sName == nil or ALL_SPELLS[sName] == nil then return false end

    if not ALL_SPELLS[sName].passive then
        return self.spells[sName] ~= nil 
            and (self.spellData[sName] == nil or GetTime() > self.spellData[sName].endTime)
    end
end

--get component info
function GFSpellItem:GetSpellRecharge(sName)
    local r, t = 0, 0
    local sData = self.spellData[sName]
    if sData then
        t = sData.endTime - sData.startTime 
        r = math.max(0, sData.endTime - GetTime())
    end

    return r, t
end

function GFSpellItem:GetSpellCount()
    return GetTableSize(self.spells)
end

-----------------------------------------
--Unsafe methods-------------------------
-----------------------------------------

function GFSpellItem:OnCastDone(sName, doer, noRecharge)
    if sName == nil or ALL_SPELLS[sName] == nil then return false end

    if not noRecharge then
        local itemRecharge = ALL_SPELLS[sName]:GetItemRecharge(self.inst)
        if itemRecharge > 0 then
            if doer and doer.components.gfspellcaster then
                itemRecharge = itemRecharge * doer.components.gfspellcaster.baseRecharge * doer.components.gfspellcaster.rechargeExternal:Get()
            end
            self:PushRecharge(sName, itemRecharge)
        end
    end

    if self.onCastDoneFn then self:onCastDoneFn(sName, doer) end
    self:AfterCastFn(sName)
end

function GFSpellItem:SwitchSpell()
    local currSpell = self:GetCurrentSpell()
    local spellCount = 0
    local nextSpell, firstSpell

    for sName, _ in pairs(self.spells) do
        spellCount = spellCount + 1
        if spellCount == 1 then
            firstSpell = sName
        end
        if nextSpell then
            self:SetCurrentSpell(sName)
            return true
        end
        if sName == currSpell then
            nextSpell = true
        end
    end

    if spellCount > 1 then
        self:SetCurrentSpell(firstSpell)
        return true
    end

    return false
end

-----------------------------------------
--ingame methods-------------------------
-----------------------------------------

function GFSpellItem:OnSave(data)
    local savetable = {}
    local currTime = GetTime()
    for sName, sData in pairs(self.spellData) do
        local rech = sData.endTime - currTime
        if rech > 15 then --don't need to save short coodlwns
            savetable[sName] = {r = rech, t = currTime - sData.startTime}
        end
    end

    return {savedata = savetable}
end

function GFSpellItem:OnLoad(data)
    if data ~= nil and data.savedata ~= nil then 
        local savedata = data.savedata
        local currTime = GetTime()
        for sName, rech in pairs(savedata) do
            self.spellData[sName] = 
            {
                endTime = rech.r + currTime,
                startTime = currTime - rech.t,
            }
        end
    end
end

function GFSpellItem:GetDebugString()
    local str = {}
    local currTime = GetTime()
    local selfSpells = {}
    for sName, v in pairs(self.spells) do
        table.insert(selfSpells, sName)
    end

    selfSpells = #selfSpells > 0 and table.concat(selfSpells, ", ") or ""

    local cd = {}
    for sName, sData in pairs(self.spellData) do
        if sData.endTime > currTime then
            table.insert(cd, string.format("[%s %.2f/%.2f]", sName, sData.endTime - currTime, sData.endTime - sData.startTime))
        end
    end

    cd = #cd > 0 and table.concat(cd, " ") or ""

    return string.format("[%s], current: %s, %s", self:GetCurrentSpell() or "none", selfSpells, cd)
end


return GFSpellItem