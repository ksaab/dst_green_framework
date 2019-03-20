--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

local ALL_SPELLS = GF.GetSpells()

local GFSpellCaster = Class(function(self, inst)
    self.inst = inst

    self.spells = {}
    self.spellData = {}

    self.lastCastTime = 0

    self.baseSpellPower = 1
    self.baseRecharge = 1

    self.modifiers = {} --has no handle for now, but can be used to modify spell power
    self.friendlyFireCheckFn = nil

    self.rechargeExternal = SourceModifierList(self.inst) 
    self.spellPowerExternal = SourceModifierList(self.inst)

    self.onClient = inst:HasTag("player") --don't need to do network things if the inst isn't a player

    if self.onClient then
        local function ListenOnce(inst)
            print(inst, "is ready, removing spellcaster component listener")
            inst.replica.gfspellcaster:SetSpells()
            inst.replica.gfspellcaster:SetSpellRecharges()
            inst:RemoveEventCallback("gfplayerisready", ListenOnce)
        end

        inst:ListenForEvent("gfplayerisready", ListenOnce)--, TheWorld)
    end

    if self.onClient and self.inst.replica.gfspellcaster then 
        self.inst.replica.gfspellcaster.spells = self.spells
        self.inst.replica.gfspellcaster.spellData = self.spellData
    end
end)

-----------------------------------------
--Safe methods---------------------------
-----------------------------------------

--set component
function GFSpellCaster:AddSpell(sName)
    if sName == nil or ALL_SPELLS[sName] == nil or self.spells[sName] == true then return false end

    self.spells[sName] = true
    if self.onClient then
        self.inst.replica.gfspellcaster:AddSpell(sName)
    end
end

function GFSpellCaster:AddSpells(spells)
    if spells == nil then return false end
    for i = 1, #spells do
        self:AddSpell(spells[i])
    end
end

function GFSpellCaster:RemoveSpell(sName)
    if self.spells[sName] == nil then return end
    self.spells[sName] = nil
    if self.onClient then
        self.inst.replica.gfspellcaster:RemoveSpell(sName)
    end
end

--custom modifiers
function GFSpellCaster:SetModifier(name, value)
    self.modifiers[name] = self.modifiers[name] ~= nil and self.modifiers[name] + value or 1 + value
end

function GFSpellCaster:GetModifier(name)
    return self.modifiers[name] or 1
end

--recharge
function GFSpellCaster:PushRecharge(sName, duration)
    if sName == nil or ALL_SPELLS[sName] == nil then return false end

    local sData = 
    {
        endTime = GetTime() + duration,
        startTime = GetTime()
    }

    self.spellData[sName] = sData

    if self.onClient then
        self.inst.replica.gfspellcaster:PushRecharge(sName, sData.endTime - GetTime(), GetTime() - sData.startTime)
    end

    self.inst:PushEvent("gfSCRechargeStarted", {sName = sName})
end

function GFSpellCaster:ReduceRecharge(sName, reduce)
    if sName == nil or ALL_SPELLS[sName] == nil or self.spellData[sName] == nil then return false end
    
    local sData = self.spellData[sName]
    sData.endTime = sData.endTime - reduce
    
    if self.onClient then
        self.inst.replica.gfspellcaster:PushRecharge(sName, sData.endTime - GetTime(), GetTime() - sData.startTime)
    end
end

--main
function GFSpellCaster:CastSpell(sName, target, pos, item, params)
    if sName == nil or ALL_SPELLS[sName] == nil then return end

    local sInst = ALL_SPELLS[sName]

    --if not sInst:DoCastSpell(self.inst, target, pos, item, params) then return false end
    local res, reason = sInst:DoCastSpell(self.inst, target, pos, item, params)
    if not res then return false, reason end

    if params == nil or not params.norecharge then
        local doerRecharge = sInst:GetDoerRecharge(self.inst)
        if doerRecharge > 0 then
            self:PushRecharge(sName, doerRecharge * self.baseRecharge * self.rechargeExternal:Get())
        else
            self.inst.replica.gfspellcaster:ForceRechargesDirty()
        end
    end

    if item and item.components.gfspellitem then
        item.components.gfspellitem:OnCastDone(sName, self.inst)
    end

    self.lastCastTime = GetTime()

    self.inst:PushEvent("gfSCCastSuccess", {spell = sInst, target = target, pos = pos, item = item, params = spellParams})

    return true
end

--friendlyfire
function GFSpellCaster:SetIsTargetFriendlyFn(fn)
    self.isTargetFriendlyfn = fn
end

function GFSpellCaster:IsTargetFriendly(target)
    if self.isTargetFriendlyfn then
        return self.isTargetFriendlyfn(self.inst, target)
    end

    return false
end

function GFSpellCaster:IsSpellReady(sName)
    return self.spellData[sName] == nil or GetTime() > self.spellData[sName].endTime
end

function GFSpellCaster:IsSpellValidForCaster(sName)
    return not ALL_SPELLS[sName].passive and self.spells[sName] ~= nil
end

function GFSpellCaster:CanCastSpell(sName)
    return self:IsSpellReady(sName) and self:IsSpellValidForCaster(sName)
end

--get component info
function GFSpellCaster:GetSpellRecharge(sName)
    local r, t = 0, 0
    local sData = self.spellData[sName]
    if sData then
        t = sData.endTime - sData.startTime 
        r = math.max(0, sData.endTime - GetTime())
    end

    return r, t
end

function GFSpellCaster:GetSpellCount()
    return GetTableSize(self.spells)
end

function GFSpellCaster:GetSpellPower()
    return math.max(0, self.baseSpellPower * self.spellPowerExternal:Get())
end

-----------------------------------------
--Unsafe methods-------------------------
-----------------------------------------
function GFSpellCaster:GetValidAiSpell()
    if self.lastCastTime + 1.5 > GetTime() then return end
    for sName, _ in pairs(self.spells) do
        if self:IsSpellReady(sName) then
            local spellData = ALL_SPELLS[sName]:AICheckFn(self.inst)
            if spellData then
                spellData.spell = sName
                return spellData
            end
        end
    end

    --creatures usually doesn't carry a weapon, but this allows to check it
    --not used now... commented
    --[[if self.inst.components.inventory then
        local item = self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if item and item.components.gfspellitem then
            itemSpell = item.components.gfspellitem:GetCurrentSpell()
            if self:CanCastSpell(itemSpell) and item.components.gfspellitem:IsSpellReady(itemSpell) then
                local spellData = ALL_SPELLS[spell]:AICheckFn(self.inst)
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

--called main spell function
function GFSpellCaster:PreCastCheck(sName, target, pos)
    return ALL_SPELLS[sName]:PreCastCheck(self.inst, target, pos)
end

--TODO: Write a hook for instant-targeted spells (maybe pick a target with Input:GetEntityUnderMouse and insert it as an act.target)
function GFSpellCaster:HandleIconClick(sName)
    local inst = self.inst
    if sName and ALL_SPELLS[sName] --spell is correct
        and self:IsSpellValidForCaster(sName) --player has the spell
        and not (inst:HasTag("playerghost") or inst:HasTag("corpse")) --player is ready to
        and not inst:HasTag("busy")                                   --cast the spell
        and (not inst.components.rider or not inst.components.rider:IsRiding()) --player isn't mounted
    then
        local check, reason = ALL_SPELLS[sName]:CheckCaster(inst)
        if not check then self.inst:PushEvent("gfSCCastFailed", reason)
        elseif self:IsSpellReady(sName) then
            if ALL_SPELLS[sName].instant then
                --so we can't use instant-targeted spells here
                if not ALL_SPELLS[sName].needTarget then
                    --pushing the buffered action is not the best idea but I couldn't find any alternatives
                    local act = BufferedAction(inst, nil, ACTIONS.GFCASTSPELL)
                    act.spell = sName
                    inst:ClearBufferedAction()
                    inst.components.locomotor:PushAction(act, true, true)
                end
            elseif inst.components.gfspellpointer then
                inst.components.gfspellpointer:Enable(sName)
            end
        else
            self.inst:PushEvent("gfSCCastFailed", "NOTREADY")
        end
    end
end

-----------------------------------------
--Ingame methods-------------------------
-----------------------------------------
function GFSpellCaster:OnSave(data)
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

function GFSpellCaster:OnLoad(data)
    if data ~= nil and data.savedata ~= nil then 
        local savedata = data.savedata
        local currTime = GetTime()
        for sName, rech in pairs(savedata) do
            if ALL_SPELLS[sName] ~= nil then
                self.spellData[sName] = 
                {
                    endTime = rech.r + currTime,
                    startTime = currTime - rech.t,
                }

                if self.onClient then
                    self.inst.replica.gfspellcaster:PushRecharge(sName, rech.r, rech.t)
                end
            end
        end
    end
end

function GFSpellCaster:GetDebugString()
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

    return selfSpells .. cd
end

return GFSpellCaster