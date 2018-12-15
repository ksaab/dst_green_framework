--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

local ALL_SPELLS = GF.GetSpells()
local SPELLS_IDS = GF.GetSpellsIDs()

local function DeserializeStream(classified)
    if classified._parent == nil then return end

    local eventArr = classified._gfSCSpellStream:value():split('^')
    local self = classified._parent.replica.gfspellcaster
    for _, event in pairs(eventArr) do
        local eData = event:split(';')
        if eData[1] == '1' then
            self:AddSpell(eData[2])
        elseif eData[1] == '2' then
            self:RemoveSpell(eData[2])
        elseif eData[1] == '3' then
            self:PushRecharge(eData[2], tonumber(eData[3]), tonumber(eData[4]))
        end
    end
end

local function _pushEvent(self)
    if self._pushTask == nil then
        self._pushTask = self.inst:DoTaskInTime(0, function(inst) 
            self._pushTask = nil
            inst:PushEvent("gfRWPush") 
        end)
    end
end

local function _forceRecharges(classified)
    if classified._parent ~= nil then classified._parent:PushEvent("gfRWPush") end
end

local GFSpellCaster = Class(function(self, inst)
    self.inst = inst

    --full replica is required only for players
    --other casters don't use this replica at all
    if not inst:HasTag("player") then return end
    
    self.spells = {}
    self.spellData = {}

    self._pushTask = nil

    --attaching classified on the server-side
    if self.classified == nil and inst.player_classified ~= nil then
        self:AttachClassified(inst.player_classified)
    end

    if GFGetIsMasterSim() and self.inst.components.gfspellcaster ~= nil then 
        self.spells = self.inst.components.gfspellcaster.spells
        self.spellData = self.inst.components.gfspellcaster.spellData
    end
end)

-----------------------------------------
--Classified methods---------------------
-----------------------------------------

function GFSpellCaster:AttachClassified(classified)
    if self.classified ~= nil then return end

    self.classified = classified
    --default things, like in the others replicatable components
    self.ondetachclassified = function() self:DetachClassified() end
    self.inst:ListenForEvent("onremove", self.ondetachclassified, classified)

    if not GFGetIsMasterSim() then 
        --collecting events directly from the classified prefab
        self.inst:ListenForEvent("gfSCForceRechargesEvent", _forceRecharges, classified)
        self.inst:ListenForEvent("gfSCEventDirty", DeserializeStream, classified)
    end
end

function GFSpellCaster:DetachClassified()
    --default things, like in the others replicatable components
    self.classified = nil
    self.ondetachclassified = nil
end

-----------------------------------------
--Safe methods---------------------------
-----------------------------------------

function GFSpellCaster:AddSpell(sName)
    if sName == nil or ALL_SPELLS[sName] == nil then return false end

    if GFGetIsMasterSim() then
        if self.inst == ThePlayer and not GFGetIsDedicatedNet() then
            _pushEvent(self)
            self.inst:PushEvent("gfSCPanelAdd", {sName = sName}) 
        elseif self.classified ~= nil then
            self.classified._gfSCSpellStream:push_string(string.format("1;%s", sName))
        end
    else
        self.spells[sName] = true
        _pushEvent(self)
        self.inst:PushEvent("gfSCPanelAdd", {sName = sName}) 
    end
end

function GFSpellCaster:RemoveSpell(sName)
    if GFGetIsMasterSim() then
        if self.inst == ThePlayer and not GFGetIsDedicatedNet() then
            _pushEvent(self)
            self.inst:PushEvent("gfSCPanelRemove", {sName = sName}) 
        elseif self.classified ~= nil then
            self.classified._gfSCSpellStream:push_string(string.format("2;%s", sName))
        end
    else
        self.spells[sName] = nil
        _pushEvent(self)
        self.inst:PushEvent("gfSCPanelRemove", {sName = sName}) 
    end
end

function GFSpellCaster:PushRecharge(sName, remain, pass)
    --print(("cooldown %.2f/%.2f"):format(GetTime() + remain, GetTime() - pass))
    if sName == nil or ALL_SPELLS[sName] == nil then return false end

    if GFGetIsMasterSim() then
        if self.inst == ThePlayer and not GFGetIsDedicatedNet() then
            _pushEvent(self)
        elseif self.classified ~= nil then
            self.classified._gfSCSpellStream:push_string(string.format("3;%s;%.2f;%.2f", sName, remain, pass))
        end
    else
        self.spellData[sName] = 
        {
            endTime = GetTime() + remain,
            startTime = GetTime() - pass,
        }
        --print(("cooldown %.2f/%.2f"):format(GetTime() + remain, GetTime() - pass))
        _pushEvent(self)
    end
end

function GFSpellCaster:CanCastSpell(sName)
    if sName == nil and ALL_SPELLS[sName] == nil then return false end

    if not ALL_SPELLS[sName].passive then
        return self.spellData[sName] == nil or GetTime() > self.spellData[sName].endTime
    end
end

function GFSpellCaster:IsSpellValidForCaster(sName)
    return self.spells[sName] ~= nil and self:CanCastSpell(sName)
end

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

-----------------------------------------
--Unsafe methods-------------------------
-----------------------------------------

function GFSpellCaster:PreCastCheck(sName)
    if sName and ALL_SPELLS[sName] then
        local preCheck = ALL_SPELLS[sName]:PreCastCheck(self.inst)
        local result, reason = ALL_SPELLS[sName]:PreCastCheck(self.inst)
        if not result then
            if self.inst.components.talker then
                self.inst.components.talker:Say(GetActionFailString(self.inst, "GFCASTSPELL", reason or "GENERIC"), 2.5, false, true, false)
            end

            return false
        end

        return true
    end
end

function GFSpellCaster:HandleIconClick(sName)
    local inst = self.inst
    if sName 
        and ALL_SPELLS[sName] 
        and not (inst:HasTag("playerghost") or inst:HasTag("corpse"))
        and not inst:HasTag("busy")
        and (not inst.replica.rider or not inst.replica.rider:IsRiding())
        and self:IsSpellValidForCaster(sName)
        and self:PreCastCheck(sName)
    then
        SendModRPCToServer(MOD_RPC["GreenFramework"]["GFCLICKSPELLBUTTON"], sName)
    end
end

function GFSpellCaster:ForceRechargesDirty(sName)
    if self.inst == ThePlayer and not GFGetIsDedicatedNet() then self.inst:PushEvent("gfRWPush") 
    elseif self.classified ~= nil then self.classified._gfSCForceRechargesEvent:push()
    end
end


return GFSpellCaster