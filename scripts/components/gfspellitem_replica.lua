--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

local spellList = GFSpellList
local spellNamesToID = GFSpellNameToID
local spellIDToNames = GFSpellIDToName

local function SliceSpellString(inst)
    local self = inst.replica.gfspellitem
    --GFDebugPrint(inst, self._spellString:value())
    local spells = self._spellString:value():split(';')
    self.spells = {}
    for _, v in pairs(spells) do
        local spellName = spellIDToNames[tonumber(v)]
        self.spells[spellName] = spellList[spellName]
    end
end

local function SetItemSpellDirty(inst)
    local self = inst.replica.gfspellitem
    local val = self._itemSpell:value()
    if val == 0 then
        self.itemSpell = nil
    else
        self.itemSpell = spellList[spellIDToNames[val]]
    end
end

local function SetRechargesDirty(inst)
    local self = inst.replica.gfspellitem
    --GFDebugPrint("GFSpellItemReplica: recharge", inst, self._spellRecharges:value())
    local spellArray = self._spellRecharges:value():split(';')
    for k, v in pairs(spellArray) do
        local recharges = v:split(',')
        recharges[1] = spellIDToNames[tonumber(recharges[1])]
        self.spellsReadyTime[recharges[1]] = GetTime() + tonumber(recharges[2])
        self.spellsRechargeDuration[recharges[1]] = tonumber(recharges[3] or recharges[2])
    end
end

local GFSpellItem = Class(function(self, inst)
    self.inst = inst
    
    self.spells = {} --full spell list
    self.itemSpell = nil --current active spell
   
    --item spell recharges
    self.spellsReadyTime = {}
    self.spellsRechargeDuration = {}
    
    --net variables
    self._itemSpell = net_int(inst.GUID, "GFSpellItem._itemSpell", "gfsetitemspellactive")
    self._spellString = net_string(inst.GUID, "GFSpellItem._spellString", "gfsetitemspells")
    self._spellRecharges = net_string(inst.GUID, "GFSpellItem._spellRecharges", "gfsetitemspellrecharges")
    self._forceUpdateRecharges = net_event(inst.GUID, "GFSpellItem._forceUpdateRecharges")

    if not TheWorld.ismastersim then 
        inst:ListenForEvent("gfsetitemspells", SliceSpellString)
        inst:ListenForEvent("gfsetitemspellactive", SetItemSpellDirty)
        inst:ListenForEvent("gfsetitemspellrecharges", SetRechargesDirty)
    end

    if not GFGetIsDedicatedNet() then 
        inst:ListenForEvent("GFSpellItem._forceUpdateRecharges", function(inst) inst:PushEvent("gfforcerechargewatcher") end)
    end

    --need this tag for inventory tiles
    inst:AddTag("rechargeable")
end)

function GFSpellItem:SetSpells()
    if not TheWorld.ismastersim then return end

    local splstr = {}
    for spellName, spell in pairs(self.inst.components.gfspellitem.spells) do
        self.spells[spellName] = spell
        table.insert(splstr, spellNamesToID[spellName])
    end

    local setstr = table.concat(splstr, ';')
    self._spellString:set_local(setstr)
    self._spellString:set(setstr)
end

function GFSpellItem:SetItemSpell(spellname)
    if not TheWorld.ismastersim then return end

    self.itemSpell = spellname ~= "" and spellList[spellname] or nil
    self._itemSpell:set_local(spellname ~= "" and spellNamesToID[spellname] or 0)
    self._itemSpell:set(spellname ~= "" and spellNamesToID[spellname] or 0)
end

function GFSpellItem:SetSpellRecharges()
    if not TheWorld.ismastersim then return end

    local splstr = {}
    local totals = self.inst.components.gfspellitem.spellsRechargeDuration
    for k, v in pairs(self.inst.components.gfspellitem.spellsReadyTime) do
        local remain = v - GetTime()
        self.spellsReadyTime[k] = v
        self.spellsRechargeDuration[k] = totals[k]
        table.insert(splstr, ("%s,%.2f,%.2f"):format(spellNamesToID[k], v - GetTime(), totals[k]))
    end

    local setstr = table.concat(splstr, ';')
    self._spellRecharges:set_local(setstr)
    self._spellRecharges:set(setstr)
end

function GFSpellItem:CanCastSpell(spellname)
    if spellList[spellname].passive then return false end --passive spells can be casted only with DoCastSpell()
    
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
    return self.itemSpell and self.itemSpell.title or ""
end

function GFSpellItem:GetItemSpell()
    return self.itemSpell
end

function GFSpellItem:GetSpellCount()
    return GetTableSize(self.spells)
end


return GFSpellItem