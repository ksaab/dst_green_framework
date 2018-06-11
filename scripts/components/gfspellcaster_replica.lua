local spellList = GFSpellList
local spellNamesToID = GFSpellNameToID
local spellIDToNames = GFSpellIDToName

local function SliceSpellString(inst)
    local self = inst.replica.gfspellcaster
    GFDebugPrint(inst, self._spellString:value())
    local spells = self._spellString:value():split(';')
    self.spells = {}
    for _, v in pairs(spells) do
        local spellName = spellIDToNames[tonumber(v)]
        self.spells[spellName] = spellList[spellName]
    end
    for k, v in pairs(self.spells) do
        print(k, v)
    end

    self.inst:PushEvent("gfsc_updatespelllist")
end

--local function SliceActiveSpellString(inst)
--    local self = inst.replica.gfspellcaster
--    GFDebugPrint(inst, self._activeSpellString:value())
--    local spells = self._activeSpellString:value():split(';')
--    self.activeSpell = {}
--    for _, v in pairs(spells) do
--        if v ~= "" then
--            self.activeSpell[spellIDToNames[tonumber(v)]] = true
--        end
--    end
--end

local function SetRechargesDirty(inst)
    local self = inst.replica.gfspellcaster
    GFDebugPrint("GFSpellCasterReplica: recharge", inst, self._spellRecharges:value())
    local spellArray = self._spellRecharges:value():split(';')
    self.spellsReadyTime = {}
    self.spellsRechargeDuration = {}
    for k, v in pairs(spellArray) do
        local recharges = v:split(',')
        recharges[1] = spellIDToNames[tonumber(recharges[1])]
        self.spellsReadyTime[recharges[1]] = GetTime() + tonumber(recharges[2])
        self.spellsRechargeDuration[recharges[1]] = tonumber(recharges[3] or recharges[2])
    end
end

local GFSpellCaster = Class(function(self, inst)
    self.inst = inst

    self.onClient = inst:HasTag("gfscclientside")

    if not self.onClient then 
        return 
    else
        --inst:RemoveTag("gfscclientside")
    end
    
    self.spells = {} --full spell list
    --self.activeSpell = {}
   
    self.spellsReadyTime = {}
    self.spellsRechargeDuration = {}
    
    --net variables
    self._spellString = net_string(inst.GUID, "GFSpellCaster._netSpellString", "gfsc_setspells")
    --self._activeSpellString = net_string(inst.GUID, "GFSpellCaster._netActiveSpellString", "gfsc_setactivespells")
    self._spellRecharges = net_string(inst.GUID, "GFSpellCaster._spellRecharges", "gfsc_setspellrechargesdirty")

    self._forceUpdateRecharges = net_event(inst.GUID, "gfsc_updaterechargesdirty")

    if not TheWorld.ismastersim and inst == GFGetPlayer() then 
        inst:ListenForEvent("gfsc_setspells", SliceSpellString)
        --inst:ListenForEvent("gfsc_setactivespells", SliceActiveSpellString)
        inst:ListenForEvent("gfsc_setspellrechargesdirty", SetRechargesDirty)
        --inst:ListenForEvent("gfsc_updaterechargesdirty", function(inst) inst:PushEvent("gfforcerechargewatcher") end)
    end

    if not GFGetDedicatedNet() and inst == GFGetPlayer() then 
        --inst:PushEvent("gfsc_updaterechargesdirty")
    end
end)

function GFSpellCaster:SetSpells()
    if not TheWorld.ismastersim then return end

    local splstr = {}
    self._spellString:set_local("")
    self.spells = {}
    for k, v in pairs(self.inst.components.gfspellcaster.spells) do
        self.spells[k] = spellList[k]
        table.insert(splstr, spellNamesToID[k])
    end
    self._spellString:set(table.concat(splstr, ';'))

    self.inst:PushEvent("gfsc_updatespelllist")
end

function GFSpellCaster:SetSpellRecharges()
    if not TheWorld.ismastersim then return end

    local splstr = {}
    self._spellRecharges:set_local("")
    local totals = self.inst.components.gfspellcaster.spellsRechargeDuration
    for k, v in pairs(self.inst.components.gfspellcaster.spellsReadyTime) do
        local remain = v - GetTime()
        self.spellsReadyTime[k] = v
        self.spellsRechargeDuration[k] = totals[k]
        table.insert(splstr, ("%s,%.2f,%.2f"):format(spellNamesToID[k], v - GetTime(), totals[k]))
    end
    self._spellRecharges:set(table.concat(splstr, ';'))
end

function GFSpellCaster:IsSpellValidForCaster(spellName)
    return self.spells[spellName] ~= nil
        and self:CanCastSpell(spellName)
end

function GFSpellCaster:CanCastSpell(spellname)
    --if not spellList[spellname]:CanBeCasted(self.inst) then return false end
    if spellList[spellname].passive then return false end
    
    if self.spellsReadyTime[spellname] ~= nil then
        return GetTime() > self.spellsReadyTime[spellname]
    else
        return true
    end
end

function GFSpellCaster:GetSpellRecharge(spellname)
    local r, t = 0, 0
    if self.spellsReadyTime[spellname] then
        t = self.spellsRechargeDuration[spellname]
        r = math.max(0, self.spellsReadyTime[spellname] - GetTime())
    end

    return r, t
end

function GFSpellCaster:GetSpellCount()
    return GetTableSize(self.spells)
end

function GFSpellCaster:HandleIconClick(spellName)
    local inst = self.inst
    if spellName 
        and spellList[spellName] 
        and not (inst:HasTag("playerghost") or inst:HasTag("corpse"))
        and self:IsSpellValidForCaster(spellName)
    then
        SendModRPCToServer(MOD_RPC["Green Framework"]["GFCLICKSPELLBUTTON"], spellName)
        --[[ if spellList[spellName].instant then
            local act = BufferedAction(inst, inst, ACTIONS.GFCASTSPELL)
            act.spell = spellName
            inst:ClearBufferedAction()
            inst.components.locomotor:PreviewAction(act, true, true)
        end ]]
    end
end


return GFSpellCaster