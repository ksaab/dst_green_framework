--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

local ALL_SPELLS = GF.GetSpells()
local SPELLS_IDS = GF.GetSpellsIDs()

local function DeserializeSpellsString(inst)
    local self = inst.replica.gfspellitem
    local spellArr = self._spellString:value():split(';')

    self.spells = {}
    for _, sID in pairs(spellArr) do
        local sName = SPELLS_IDS[tonumber(sID)]
        if sName ~= nil then
            self.spells[sName] = true
        end
    end
end

local function DeserializeRechargesString(inst)
    local self  = inst.replica.gfspellitem
    local rechArr = self._rechargesString:value():split('^')

    self.spellData = {}
    local currTime = GetTime()
    for _, rData in pairs(rechArr) do
        local rech = rData:split(';')
        local sName = SPELLS_IDS[tonumber(rech[1])]
        if sName ~= nil then
            self.spellData[sName] = 
            {
                startTime = currTime - tonumber(rech[3]),
                endTime = currTime + tonumber(rech[2]),
            }
        end
    end
end

local function SetCurrentSpell(inst)
    local self = inst.replica.gfspellitem
    local sName = SPELLS_IDS[self._currentSpell:value()]
    if sName ~= nil then
        self.currentSpell = sName
    end
end

local GFSpellItem = Class(function(self, inst)
    self.inst = inst
    
    self.spells = {} --all spells
    self.spellData = {} --current active spell
    self.currentSpell = nil
    
    --net variables
    self._currentSpell = net_int(inst.GUID, "GFSpellItem._itemSpell", "gfSICurrentDirty")
    self._spellString = net_string(inst.GUID, "GFSpellItem._spellString", "GFSISpellsDirty")
    self._rechargesString = net_string(inst.GUID, "GFSpellItem._spellRecharges", "gfSERechargesDirty")

    --self._forceUpdateRecharges = net_event(inst.GUID, "GFSpellItem._forceUpdateRecharges")

    if not GFGetIsMasterSim() then 
        inst:ListenForEvent("gfSICurrentDirty", SetCurrentSpell)
        inst:ListenForEvent("GFSISpellsDirty", DeserializeSpellsString)
        inst:ListenForEvent("gfSERechargesDirty", DeserializeRechargesString)
    end

    --[[ if not GFGetIsDedicatedNet() then 
        inst:ListenForEvent("GFSpellItem._forceUpdateRecharges", function(inst) inst:PushEvent("gfRWPush") end)
    end ]]

    if GFGetIsMasterSim() and self.inst.components.gfspellitem ~= nil then 
        self.spells = self.inst.components.gfspellitem.spells
        self.spellData = self.inst.components.gfspellitem.spellData
    end

    inst:AddTag("rechargeable")
end)

-----------------------------------------
--Safe methods---------------------------
-----------------------------------------

function GFSpellItem:IsSpellReady(sName)
    return self.spellData[sName] == nil or GetTime() > self.spellData[sName].endTime
end

function GFSpellItem:IsSpellValidForItem(sName)
    return not ALL_SPELLS[sName].passive and self.spells[sName] ~= nil
end

function GFSpellItem:CanCastSpell(sName)
    return self:IsSpellReady(sName) and self:IsSpellValidForCaster(sName)
end

function GFSpellItem:GetSpellRecharge(sName)
    local r, t = 0, 0
    local sData = self.spellData[sName]
    if sData then
        t = sData.endTime - sData.startTime 
        r = math.max(0, sData.endTime - GetTime())
    end

    return r, t
end

function GFSpellItem:GetCurrentSpell()
    return self.currentSpell
end

function GFSpellItem:GetSpellCount()
    return GetTableSize(self.spells)
end

function GFSpellItem:GetItemSpellTitle()
    local str = ""
    if self.currentSpell ~= nil then
        str = GetSpellString(self.currentSpell, "title", true)
    end

    return str
end

-----------------------------------------
--unsafe methods-------------------------
-----------------------------------------

function GFSpellItem:UpdateSpells()
    local str = {}
    for sName, v in pairs(self.spells) do
        table.insert(str, ALL_SPELLS[sName].id)
    end

    str = table.concat(str, ';')
    self._spellString:set_local(str)
    self._spellString:set(str)
end

function GFSpellItem:UpdateRecharges()
    local str = {}
    local currTime = GetTime()
    for sName, sData in pairs(self.spellData) do
        if sData.endTime > currTime then
            table.insert(str, string.format("%i;%.2f;%.2f", 
                ALL_SPELLS[sName].id, sData.endTime - currTime, currTime - sData.startTime))
        end
    end

    str = table.concat(str, '^')
    self._rechargesString:set_local(str)
    self._rechargesString:set(str)
end

function GFSpellItem:UpdateCurrentSpell(sName)
    self.currentSpell = sName
    self._currentSpell:set_local(0)
    self._currentSpell:set(ALL_SPELLS[sName].id or 0)
end


return GFSpellItem