--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

local spellList = GFSpellList
local spellNamesToID = GFSpellNameToID
local spellIDToNames = GFSpellIDToName

--listening for dirty events directly from the player_classified
local function DeserializeSpells(classified)
    if classified._parent == nil then GFDebugPrint("DeserializeSpells: parent is nil") return end

    local self = classified._parent.replica.gfspellcaster
    local spells = classified._spellString:value():split(';')
    GFDebugPrint(classified._spellString:value())
    self.spells = {}
    for _, v in pairs(spells) do
        local spellName = spellIDToNames[tonumber(v)]
        self.spells[spellName] = spellList[spellName]
    end

    classified._parent:PushEvent("gfpushwatcher")
    classified._parent:PushEvent("gfpushpanel")
end

--listening for dirty events directly from the player_classified
local function DeserializeRecharges(classified)
    if classified._parent == nil then GFDebugPrint("DeserializeRecharges: parent is nil") return end

    local self = classified._parent.replica.gfspellcaster
    local spellArray = classified._spellRecharges:value():split(';')
    GFDebugPrint(classified._spellRecharges:value())
    self.spellsReadyTime = {}
    self.spellsRechargeDuration = {}
    for k, v in pairs(spellArray) do
        local recharges = v:split(',')
        recharges[1] = spellIDToNames[tonumber(recharges[1])]
        self.spellsReadyTime[recharges[1]] = GetTime() + tonumber(recharges[2])
        self.spellsRechargeDuration[recharges[1]] = tonumber(recharges[3] or recharges[2])
    end

    classified._parent:PushEvent("gfpushwatcher")
end

--listening for dirty events directly from the player_classified
local function PushRechargesDirty(classified)
    if classified._parent == nil then print("PushRechargesDirty: parent is nil") return end
    classified._parent:PushEvent("gfpushwatcher")
end

local GFSpellCaster = Class(function(self, inst)
    self.inst = inst

    --full replica is required only for players
    --other casters don't use this replica at all
    if not inst:HasTag("player") then return end
    
    self.spells = {}
    self.spellsReadyTime = {}
    self.spellsRechargeDuration = {}

    --attaching classified on the server-side
    if GFGetIsMasterSim() and inst.player_classified ~= nil then
        self.classified = inst.player_classified
    end
end)

--attaching classified on the client-side
function GFSpellCaster:AttachClassified(classified)
    if self.classified ~= nil then return end

    self.classified = classified
    --default things, like in the others replicatable components
    self.ondetachclassified = function() self:DetachClassified() end
    self.inst:ListenForEvent("onremove", self.ondetachclassified, classified)

    if not GFGetIsMasterSim() then 
        --collecting events directly from the classified prefab
        self.inst:ListenForEvent("gfsetspellsdirty", DeserializeSpells, classified)
        self.inst:ListenForEvent("gfsetrechargesdirty", DeserializeRecharges, classified)
        self.inst:ListenForEvent("gfupdaterechargesdirty", PushRechargesDirty, classified)
    end
end

function GFSpellCaster:DetachClassified()
    --default things, like in the others replicatable components
    self.classified = nil
    self.ondetachclassified = nil
end

function GFSpellCaster:SetSpells()
    if not GFGetIsMasterSim() then return end

    GFDebugPrint("Updating spells on", self.inst)
    local splstr = {}
    self.spells = {} --resetting current spells

    --collecting all spells from the component
    --component and replica on the server have the same set of data — looks like a waste of the memory, 
    --but I don't want to create a lot of ismastersim checks in HUD methods
    for k, v in pairs(self.inst.components.gfspellcaster.spells) do
        self.spells[k] = spellList[k]
        table.insert(splstr, spellNamesToID[k])
    end

    if self.classified ~= nil then
        if self.inst == GFGetPlayer() and not GFGetIsDedicatedNet() then
            --refresh recharge-watcher on the host-side
            self.inst:PushEvent("gfpushwatcher") 
            self.inst:PushEvent("gfpushpanel")
        else
            --sending information about current spells to the client
            --sending string which contains all spells enumerated with a separator
            local setstr = table.concat(splstr, ';')
            self.classified._spellString:set_local(setstr)
            self.classified._spellString:set(setstr)
        end
    end
end

function GFSpellCaster:SetSpellRecharges()
    if not GFGetIsMasterSim() then return end

    GFDebugPrint("Updating recharges on", self.inst)
    local splstr = {}  --resetting current cooldowns
    local totals = self.inst.components.gfspellcaster.spellsRechargeDuration

    --collecting all cooldowns from the component
    --duplicating data like above, but the reason is the same too
    for k, v in pairs(self.inst.components.gfspellcaster.spellsReadyTime) do
        local remain = v - GetTime()
        self.spellsReadyTime[k] = v
        self.spellsRechargeDuration[k] = totals[k]
        print(("%s,%.2f,%.2f"):format(spellNamesToID[k], v - GetTime(), totals[k]))
        table.insert(splstr, ("%s,%.2f,%.2f"):format(spellNamesToID[k], v - GetTime(), totals[k]))
    end

    if self.classified ~= nil then
        if self.inst == GFGetPlayer() and not GFGetIsDedicatedNet() then
            --refresh recharge-watcher on the host-side
            self.inst:PushEvent("gfpushwatcher")
        else
            --sending information about current cooldowns to the client
            local setstr = table.concat(splstr, ';')
            self.classified._spellRecharges:set_local(setstr)
            self.classified._spellRecharges:set(setstr)
        end
    end
end

function GFSpellCaster:PushSpellRecharges()
    if self.classified ~= nil then
        if self.inst == GFGetPlayer() and not GFGetIsDedicatedNet() then
            --refresh hud on the host-side
            self.inst:PushEvent("gfpushwatcher")
        else
            --forcing a refresh event on the client
            self.classified._forceUpdateRecharges:push()
        end
    end
end

function GFSpellCaster:IsSpellValidForCaster(spellName)
    return self.spells[spellName] ~= nil
        and self:CanCastSpell(spellName)
end

function GFSpellCaster:CanCastSpell(spellname)
    if spellList[spellname].passive then return false end --can't cast passive spells
    
    if self.spellsReadyTime[spellname] ~= nil then --there is a recharge for this spell
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

    --first - remaingg time, secont - total recharge time
    return r, t
end

function GFSpellCaster:GetSpellCount()
    return GetTableSize(self.spells)
end

function GFSpellCaster:PreCastCheck(spellName)
    if spellName and spellList[spellName] then
        local preCheck = spellList[spellName]:PreCastCheck(self.inst)
        if not preCheck or type(preCheck) == "string" then
            if self.inst.components.talker then
                self.inst.components.talker:Say(GetActionFailString(self.inst, "GFCASTSPELL", preCheck or "GENERIC"), 2.5, false, true, false)
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
        and not inst:HasTag("busy")
        and (not inst.replica.rider or not inst.replica.rider:IsRiding())
        and self:IsSpellValidForCaster(spellName)
        and self:PreCastCheck(spellName)
    then
        SendModRPCToServer(MOD_RPC["GreenFramework"]["GFCLICKSPELLBUTTON"], spellName)

        --[[ if spellList[spellName].instant then
            local act = BufferedAction(inst, inst, ACTIONS.GFCASTSPELL)
            act.spell = spellName
            inst:ClearBufferedAction()
            inst.components.locomotor:PreviewAction(act, true, true)
        end ]]
    end
end


return GFSpellCaster