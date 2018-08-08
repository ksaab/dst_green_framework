--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

local spellList = GFSpellList
local spellNamesToID = GFSpellNameToID
local spellIDToNames = GFSpellIDToName

local function SliceSpellString(inst)
    local self = inst.replica.gfspellcaster
    --GFDebugPrint(inst, self._spellString:value())
    local spells = self._spellString:value():split(';')
    self.spells = {}
    for _, v in pairs(spells) do
        local spellName = spellIDToNames[tonumber(v)]
        self.spells[spellName] = spellList[spellName]
    end

    self.inst:PushEvent("gfupdatespellshud")
end

local function SetRechargesDirty(inst)
    local self = inst.replica.gfspellcaster
    --GFDebugPrint("GFSpellCasterReplica: recharge", inst, self._spellRecharges:value())
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
    self.onClient = inst:HasTag("player")

    if not self.onClient then 
        return 
    end
    
    self.spells = {}
    self.spellsReadyTime = {}
    self.spellsRechargeDuration = {}
    
    self._spellString = net_string(inst.GUID, "GFSpellCaster._netSpellString", "gfsetspellsdirty")
    self._spellRecharges = net_string(inst.GUID, "GFSpellCaster._spellRecharges", "gfsetrechargesdirty")
    self._forceUpdateRecharges = net_event(inst.GUID, "gfupdaterechargesdirty")

    if not TheWorld.ismastersim and inst == GFGetPlayer() then 
        inst:ListenForEvent("gfsetspellsdirty", SliceSpellString)
        inst:ListenForEvent("gfsetrechargesdirty", SetRechargesDirty)

        inst:DoTaskInTime(0.5, function()
            SendModRPCToServer(MOD_RPC["Green Framework"]["GFPLAYEISRREADY"])
        end)
    end
end)

function GFSpellCaster:SetSpells()
    if not TheWorld.ismastersim then return end

    --GFDebugPrint("Updating spells on", self.inst)
    local splstr = {}
    --self._spellString:set_local("")
    self.spells = {}
    for k, v in pairs(self.inst.components.gfspellcaster.spells) do
        self.spells[k] = spellList[k]
        table.insert(splstr, spellNamesToID[k])
    end

    local setstr = table.concat(splstr, ';')
    self._spellString:set_local(setstr)
    self._spellString:set(setstr)
    --self._spellString:set(table.concat(splstr, ';'))

    self.inst:PushEvent("gfupdatespellshud") --refresh hud on the host-side
end

function GFSpellCaster:SetSpellRecharges()
    if not TheWorld.ismastersim then return end

    --GFDebugPrint("Updating recharges on", self.inst)
    local splstr = {}
    --self._spellRecharges:set_local("")
    local totals = self.inst.components.gfspellcaster.spellsRechargeDuration
    for k, v in pairs(self.inst.components.gfspellcaster.spellsReadyTime) do
        local remain = v - GetTime()
        self.spellsReadyTime[k] = v
        self.spellsRechargeDuration[k] = totals[k]
        table.insert(splstr, ("%s,%.2f,%.2f"):format(spellNamesToID[k], v - GetTime(), totals[k]))
    end

    --print(table.concat(splstr, ';'))
    local setstr = table.concat(splstr, ';')
    self._spellRecharges:set_local(setstr)
    self._spellRecharges:set(setstr)
    --self._spellRecharges:set(table.concat(splstr, ';'))
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

function GFSpellCaster:PreCastCheck(spellName)
    if spellName and spellList[spellName] then
        local preCheck = spellList[spellName]:PreCastCheck(self.inst)
        if not preCheck or type(preCheck) == "string" then
            --if STRINGS.CHARACTERS.GENERIC[preCheck] then
            if self.inst.components.talker then
                self.inst.components.talker:Say(GetString(self.inst, "PRECAST_FAILED", preCheck), 2.5, false, true, false)
            end

            return false
        end

        return true
    end
end

function GFSpellCaster:HandleIconClick(spellName)
    local inst = self.inst
    if spellName 
        and spellList[spellName] 
        and not (inst:HasTag("playerghost") or inst:HasTag("corpse"))
        and not inst.sg:HasStateTag("busy")
        and (not inst.replica.rider or not inst.replica.rider:IsRiding())
        and self:IsSpellValidForCaster(spellName)
        and self:PreCastCheck(spellName)
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