--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

local ALL_SPELLS = GFSpellList
local SNAME_TO_ID = GFSpellNameToID
local SID_TO_NAME = GFSpellIDToName

local function DeserializeSpellsString(inst)
    local self = inst.replica.gfspellitem
    local spellArr = self._spellString:value():split(';')

    self.spells = {}
    for _, sID in pairs(spellArr) do
        local sName = SID_TO_NAME[tonumber(sID)]
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
        local sName = SID_TO_NAME[tonumber(rech[1])]
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
    local sName = SID_TO_NAME[self._currentSpell:value()]
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

function GFSpellItem:CanCastSpell(sName)
    if sName == nil or ALL_SPELLS[sName] == nil then return false end

    if not ALL_SPELLS[sName].passive then
        return self.spells[sName] ~= nil 
            and (self.spellData[sName] == nil or GetTime() > self.spellData[sName].endTime)
    end
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
        table.insert(str, SNAME_TO_ID[sName])
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
                SNAME_TO_ID[sName], sData.endTime - currTime, currTime - sData.startTime))
        end
    end

    str = table.concat(str, '^')
    self._rechargesString:set_local(str)
    self._rechargesString:set(str)
end

function GFSpellItem:UpdateCurrentSpell(sName)
    self.currentSpell = sName
    self._currentSpell:set_local(0)
    self._currentSpell:set(SNAME_TO_ID[sName] or 0)
end


return GFSpellItem