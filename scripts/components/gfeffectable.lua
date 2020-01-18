--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

local ALL_EFFECTS = GF.GetStatusEffects()
local BASE_EFFECTS = GF.EntitiesBaseEffects

local function RemoveEffectsOnDeath(inst)
    inst.components.gfeffectable:RemoveAllEffects(false, "death")
end

local gfEffectsSymbols = require("gf_var_symbols")

local function SetFollowSymbol(self)
    local inst = self.inst
    local symbol, y
    if inst:HasTag("player") then
        symbol = "torso"
        y = -200
    else
        --if symbol wasn't declared before, try to find it
        if gfEffectsSymbols[inst.prefab] ~= nil then
            local symb = gfEffectsSymbols[inst.prefab]
            symbol = symb[1]
            y = symb[2]
        else					
            if inst.AnimState ~= nil then
                local animState = inst.AnimState

                --searching for valid symbol
                if inst.components.burnable ~= nil
                    and inst.components.burnable.fxdata[1] ~= nil
                    and inst.components.burnable.fxdata[1].follow ~= nil
                then
                    symbol = inst.components.burnable.fxdata[1].follow
                else
                    if animState:BuildHasSymbol(inst.prefab .. "_torso") then
                        symbol = inst.prefab .. "_torso"
                    elseif animState:BuildHasSymbol(inst.prefab .. "_body") then
                        symbol = inst.prefab .. "_body"
                    elseif animState:BuildHasSymbol("chest") then
                        symbol = "chest"
                    elseif animState:BuildHasSymbol("torso") then
                        symbol = "torso"
                    elseif animState:BuildHasSymbol("body") then
                        symbol = "body"
                    end
                end

                --searching for offset
                if inst:HasTag("smallcreature") then
                    y = -100
                elseif inst:HasTag("largecreature") then
                    y = -400
                end
            end
        end
    end

    self.followSymbol = symbol or "not_found"
    self.followYOffset = y or -200

    if not gfEffectsSymbols[inst.prefab] then
        gfEffectsSymbols[inst.prefab] = {self.followSymbol, self.followYOffset }
        print("new symbol for effectable:")
        print(("%s = {\"%s\", %i}"):format(tostring(inst.prefab), self.followSymbol, self.followYOffset))
    end
end

local function TryAddAffix(inst)
    local self = inst.components.gfeffectable
    if self and self.isNew then
        for affixType, affixData in pairs(BASE_EFFECTS[inst.prefab]) do
            if #(affixData.list) > 0 and math.random() < affixData.chance then
                local aff = affixData.list[math.random(#(affixData.list))]
                --GFDebugPrint(("Add [%s-type] affix [%s] to %s"):format(affixType, aff, tostring(self.inst)))
                self:ApplyEffect(aff)
            end
        end
    end
end

local GFEffectable = Class(function(self, inst)
    self.inst = inst
    self.effects = {}
    self.resists = {}

    self.isNew = true

    --set data for effect fx
    self.followSymbol = "body"
    self.followYOffset = -200

    self.isUpdating = false

    if inst.components.combat then
        SetFollowSymbol(self)
    end

    if BASE_EFFECTS[inst.prefab] then
        inst:DoTaskInTime(0, TryAddAffix)
    end

    if inst:HasTag("player") then
        local function ListenOnce(inst)
            print(inst, "is ready, removing effectable component listener")
            inst.replica.gfeffectable:UpdateEffectsList()
            inst:RemoveEventCallback("gfplayerisready", ListenOnce)
        end

        inst:ListenForEvent("gfplayerisready", ListenOnce)--, TheWorld)
    end

    inst:ListenForEvent("death", RemoveEffectsOnDeath)
end)

function GFEffectable:ChangeResist(resist, value)
    if resist == nil or value == nil then 
        --GFDebugPrint("GFEffectable: can't add resist, data is wrong")
        return 
    end
    local res = self.resists[resist]
    self.resists[resist] = res == nil and value or res + value
end

function GFEffectable:GetResist(resist)
    return self.resists[resist] or 0
end

function GFEffectable:CheckResists(effect)
    if not effect.ignoreResist then --check for resists
        for tag, value in pairs(effect.tags) do
            if self.resists[tag] and self.resists[tag] ~= 0 then
                if math.random() < self.resists[tag] then
                    --GFDebugPrint(("GFEffectable: effects %s was resisted by %s"):format(effect.name, tostring(self.inst)))
                    return false
                end
            end
        end
    end

    return true
end

function GFEffectable:ApplyEffect(eName, eParams)
    if eName == nil 
        or ALL_EFFECTS[eName] == nil 
        or not ALL_EFFECTS[eName]:Check(self.inst)
        or not self.inst:IsValid()
        or self.inst:HasTag("playerghost")
        or self.inst:HasTag("corpse")
        or (self.inst.components.health ~= nil and self.inst.components.health:IsDead())
    then 
        return false 
    end

    eParams = eParams or {} --set to empty if nil
    local eInst = ALL_EFFECTS[eName]

    if not self:CheckResists(eInst) then 
        self.inst:PushEvent("gfeffectresisted", {effect = eInst})
        return false 
    end

    if self.effects[eName] ~= nil then
        --effect already exists on entity
        local eData = self.effects[eName]
        if eInst.nonRefreshable then return false end --not all effects are refresheable --and self:CheckResists(effect) --check resists and other stuff

        eInst:Refresh(self.inst, eData, eParams) --refreshing the existing effect
        if not eInst.static then self.inst:PushEvent("gfEFEffectApplied", {refreshed = true, effect = eInst, params = eData}) end

        --GFDebugPrint(("%s refreshes %s"):format(tostring(self.inst), eName))
        self.inst.replica.gfeffectable:RefreshEffect(eName)

        return true
    else
        local eData = {}
        self.effects[eName] = eData
        eInst:Apply(self.inst, eData, eParams)

        if not eInst.static then self.inst:PushEvent("gfEFEffectApplied", {refreshed = true, effect = eInst, params = eData}) end

        if eInst.updateable or not eInst.static then --static effects are permanent modificators, so don't need to update
            self.inst:StartUpdatingComponent(self)
            self.isUpdating = true
        end

        --GFDebugPrint(("%s now is affected by %s"):format(tostring(self.inst), eName))
        self.inst.replica.gfeffectable:ApplyEffect(eName)

        return true
    end
    
    return false
end

function GFEffectable:PushEffect(name, from, duration, stacks, other)
    local data = 
    {
        applier = from,
        stacks = stacks,
        duration = duration,
    }
    if other ~= nil then
        if type(other) == "table" then
            for k, v in pairs(other) do
                data[k] = v
            end
        else
            data.custom = other
        end
    end

    self:ApplyEffect(name, data)
end

function GFEffectable:PushFX(eName, prefab, symbol, offset)
    if eName == nil or ALL_EFFECTS[eName] == nil or self.effects[eName] == nil then return false end

    local eData = self.effects[eName]
    
    if eData._fx ~= nil and eData._fx:IsValid() then
        eData._fx:Remove()
    end

    local fx = SpawnPrefab(prefab)
    if fx ~= nil then
        if fx.Follower ~= nil then
            local x, y, z
            if offset ~= nil then
                x, y, z = unpack(offset)
            else
                x, y, z = 0, self.followYOffset, 0
            end
            fx.Follower:FollowSymbol(self.inst.GUID, symbol or self.followSymbol, x, y, z)
            eData._fx = fx
        else
            eData._fx = nil
            fx:Remove()
            GFDebugPrint(string.format("incorrect follower prefab %s for effect %s", prefab, eName))
        end
    end
end

function GFEffectable:PushTempFX(prefab, symbol, offset)
    local fx = SpawnPrefab(prefab)
    if fx ~= nil then
        if fx.Follower ~= nil then
            local x, y, z
            if offset ~= nil then
                x, y, z = unpack(offset)
            else
                x, y, z = 0, self.followYOffset, 0
            end
            fx.Follower:FollowSymbol(self.inst.GUID, symbol or self.followSymbol, x, y, z)
        else
            fx:Remove()
            GFDebugPrint(string.format("incorrect temp fx prefab %s", prefab))
        end
    end
end

function GFEffectable:ConsumeStacks(eName, value)
    if eName == nil or self.effects[eName] == nil then return false end

    local eInst = ALL_EFFECTS[eName]
    eInst:ConsumeStacks(self.inst, self.effects[eName], value or 1)

    self.inst.replica.gfeffectable:RefreshEffect(eName)
end

function GFEffectable:DurationDelta(eName, value)
    if eName == nil or self.effects[eName] == nil then return false end

    local eInst = ALL_EFFECTS[eName]
    self.effects[eName].expirationTime = self.effects[eName].expirationTime + value or 0

    self.inst.replica.gfeffectable:RefreshEffect(eName)
end

function GFEffectable:RemoveEffect(eName, reason)
    if eName == nil or ALL_EFFECTS[eName] == nil or self.effects[eName] == nil then return false end

    reason = reason or "unknown"
    local eInst = ALL_EFFECTS[eName]
    local eData = self.effects[eName]

    --killing fx
    if eData._fx ~= nil and eData._fx:IsValid() then eData.fx:Remove() end

    eInst:Remove(self.inst, eData, reason)
    
    self.inst.replica.gfeffectable:RemoveEffect(eName)
    self.effects[eName] = nil

    if not eInst.static then self.inst:PushEvent("gfEFEffectRemoved", {eName = eName, reason = reason}) end

    --GFDebugPrint(("%s is no longer affected by %s, reason %s "):format(tostring(self.inst), eName, reason))
end

function GFEffectable:RemoveAllEffects(removeStatic, reason)
    for eName, _ in pairs(self.effects) do
        local eInst = ALL_EFFECTS[eName]
        if eInst:HasTag("removeondeath") or removeStatic or not eInst.static then
            self:RemoveEffect(eName, reason)
        end
    end
end

function GFEffectable:RemoveAllEffectsWithTag(tag, reason)
    if tag == nil then return false end

    for eName, _ in pairs(self.effects) do
        if ALL_EFFECTS[eName]:HasTag(tag) then
            self:RemoveEffect(eName, reason)
        end
    end
end

function GFEffectable:GetEffectData(eName)
    return self.effects[eName] 
end

function GFEffectable:GetTimer(eName)
    if eName ~= nil and self.effects[eName] ~= nil then
        local eData = self.effects[eName]
        return math.max(0, eData.expirationTime - GetTime()), eData.expirationTime - eData.applicationTime
    end

    return 0, 0
end

--[[ function GFEffectable:GetRemainTime(eName)
    if eName ~= nil and self.effects[eName] ~= nil then
        return math.max(0, self.effects[eName].expirationTime - GetTime())
    end

    return 0
end ]]

function GFEffectable:GetStacks(eName)
    if eName ~= nil and self.effects[eName] ~= nil then
        return self.effects[eName].stacks
    end

    return 0
end

function GFEffectable:HasEffect(eName)
    return eName ~= nil and self.effects[eName] ~= nil or false
end

function GFEffectable:HasEffectWithTag(tag)
    if tag == nil then return false end

    for eName, _ in pairs(self.effects) do
        if ALL_EFFECTS[eName]:HasTag(tag) then
            return true, eName
        end
    end
end

function GFEffectable:GetRemainTime(eName)
    return self:HasEffect(eName) and math.max(0, self.effects[eName].expirationTime - GetTime()) or 0
end

function GFEffectable:GetNumberEffects()
    local all = 0
    local nonStatic = 0
    for eName, _ in pairs(self.effects) do
        all = all + 1
        if not ALL_EFFECTS[eName].static then
            nonStatic = nonStatic + 1
        end
    end

    return all, nonStatic
end

--------------------------------------------------------
--ingame methods----------------------------------------
--------------------------------------------------------

function GFEffectable:OnUpdate(dt)
    local currTime = GetTime()
    local needToStopUpdating = true
    for eName, eData in pairs(self.effects) do
        local eInst = ALL_EFFECTS[eName]
        if eInst.updateable then
            --call the effect the onupdate function when it's needed
            needToStopUpdating = false
            if currTime >= eData.nextTick then
                eInst:Update(self.inst, eData)
            end
        end
        if not eInst.static then 
            needToStopUpdating = false
            if currTime >= eData.expirationTime then
                self:RemoveEffect(eName, "expire")
            end
        end
    end

    if needToStopUpdating then
        self.inst:StopUpdatingComponent(self)
        self.isUpdating = false
    end
end

function GFEffectable:OnEntitySleep()
    for eName, eData in pairs(self.effects) do
        if ALL_EFFECTS[eName].sleeper then
            ALL_EFFECTS[eName]:OnSleep(self.inst, eData)
        end
    end
end

function GFEffectable:OnEntityWake()
    for eName, eData in pairs(self.effects) do
        if ALL_EFFECTS[eName].sleeper then
            ALL_EFFECTS[eName]:OnWake(self.inst, eData)
        end
    end
end

function GFEffectable:OnSave(data)
    local savetable = {}
    local currTime = GetTime()
    for eName, eData in pairs(self.effects) do
        local eInst = ALL_EFFECTS[eName]
        if eInst.savable then
            local remain = eData.expirationTime - currTime
            if eInst.static or (eData.expirationTime ~= nil and remain > 0) then
                savetable[eName] = 
                {
                    remain = remain,
                    stacks = eData.stacks,
                }
            end
        end
    end

    return {savedata = savetable}
end

function GFEffectable:OnLoad(data)
    self.isNew = false
    if data ~= nil and data.savedata ~= nil then 
        local savedata = data.savedata
        for eName, eData in pairs(savedata) do
            self:ApplyEffect(eName, 
                {
                    duration = eData.remain, 
                    stacks = eData.stacks,
                })
        end

        self.inst:StartUpdatingComponent(self)
        self.isUpdating = true
    end
end

function GFEffectable:GetDebugString()
    local currTime = GetTime()
    local str = {}
    for eName, dData in pairs(self.effects) do
        local timer = ALL_EFFECTS[eName].static 
            and "static" 
            or string.format("%.2f/%.2f", 
                dData.expirationTime - currTime, dData.expirationTime - dData.applicationTime)
        table.insert(str, string.format("[%s(%i) %s]", eName, dData.stacks, timer))
    end

    local res = {}
    for resist, value in pairs(self.resists) do
        table.insert(res, string.format("[%s - %i%%]", resist, value * 100))
    end

    local resstr 
    if #res > 0 then 
        resstr = table.concat(res, ',')
    else
        resstr = "none"
    end

    local a, n = self:GetNumberEffects()
    return string.format("%s effects %i (%i): %s, resists: %s", tostring(self.isUpdating), a, n, table.concat(str, ", "), resstr)
end


return GFEffectable