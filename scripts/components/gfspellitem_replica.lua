local spellList = GFSpellList
local spellNamesToID = GFSpellNameToID
local spellIDToNames = GFSpellIDToName

local function SliceSpellString(inst)
    local self = inst.replica.gfspellitem
    GFDebugPrint(inst, self._spellString:value())
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
    if val == "" then
        self.itemSpell = nil
        if self.inst.components.gfspellpointer then
            self.inst.components.gfspellpointer:SetPointer()
        end
    else
        local spellName = spellIDToNames[tonumber(val)]
        self.itemSpell = spellList[spellName]
        GFDebugPrint(inst, self.itemSpell)

        --set pointer on server-side
        if self.inst.components.gfspellpointer then
            self.inst.components.gfspellpointer:SetPointer(spellList[spellName].pointer)
        end
    end
end

local function SetRechargesDirty(inst)
    local self = inst.replica.gfspellitem
    GFDebugPrint("GFSpellItemReplica: recharge", inst, self._spellRecharges:value())
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
    self.itemSpell = nil
   
    self.spellsReadyTime = {}
    self.spellsRechargeDuration = {}
    
    --net variables
    self._spellString = net_string(inst.GUID, "GFSpellItem._netSpellString", "gfsi_setspells")
    self._itemSpell = net_string(inst.GUID, "GFSpellItem._itemSpell", "gfsi_setitemspelldirty")
    self._spellRecharges = net_string(inst.GUID, "GFSpellItem._spellRecharges", "gfsi_setspellrechargesdirty")

    self._forceUpdateRecharges = net_event(inst.GUID, "gfsi_updaterechargesdirty")

    if not TheWorld.ismastersim then 
        inst:ListenForEvent("gfsi_setspells", SliceSpellString)
        inst:ListenForEvent("gfsi_setitemspelldirty", SetItemSpellDirty)
        inst:ListenForEvent("gfsi_setspellrechargesdirty", SetRechargesDirty)
    end

    if not GFGetDedicatedNet() then 
        inst:ListenForEvent("gfsi_updaterechargesdirty", function(inst) inst:PushEvent("gfforcerechargewatcher") end)
    end
end)

function GFSpellItem:SetSpells()
    if not TheWorld.ismastersim then return end

    local splstr = {}
    self._spellString:set_local("")
    for spellName, spell in pairs(self.inst.components.gfspellitem.spells) do
        self.spells[spellName] = spell
        table.insert(splstr, spellNamesToID[spellName])
    end
    self._spellString:set(table.concat(splstr, ';'))
end

function GFSpellItem:SetItemSpell(spellname)
    if not TheWorld.ismastersim then return end

    self.itemSpell = spellname ~= "" and spellList[spellname] or nil
    self._itemSpell:set_local("")
    self._itemSpell:set(spellNamesToID[spellname])

    --set pointer on server-side
    if self.inst.components.gfspellpointer then
        self.inst.components.gfspellpointer:SetPointer(spellList[spellname].pointer)
    end
end

function GFSpellItem:SetSpellRecharges()
    if not TheWorld.ismastersim then return end

    local splstr = {}
    self._spellRecharges:set_local("")
    local totals = self.inst.components.gfspellitem.spellsRechargeDuration
    for k, v in pairs(self.inst.components.gfspellitem.spellsReadyTime) do
        local remain = v - GetTime()
        self.spellsReadyTime[k] = v
        self.spellsRechargeDuration[k] = totals[k]
        table.insert(splstr, ("%s,%.2f,%.2f"):format(spellNamesToID[k], v - GetTime(), totals[k]))
    end
    self._spellRecharges:set(table.concat(splstr, ';'))
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


return GFSpellItem