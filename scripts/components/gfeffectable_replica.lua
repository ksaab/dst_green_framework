--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.
local ALL_EFFECTS = GF.GetStatusEffects()
local EFFECTS_IDS = GF.GetStatusEffectsIDs()

local INVALID_TITLE = STRINGS.GF.HUD.INVALID_LINES.INVALID_TITLE
local INVALID_TEXT = STRINGS.GF.HUD.INVALID_LINES.INVALID_TEXT

local function UpdateClassifiedEffect(inst, eName, timer, stacks)
    local self = inst.replica.gfeffectable

    if not GFGetIsMasterSim() then
        if self.effects[eName] ~= nil then
            self.effects[eName].expirationTime = GetTime() + timer
            self.effects[eName].stacks = stacks
        else
            self.effects[eName] = 
            {
                expirationTime = GetTime() + timer,
                stacks = stacks,
                static = ALL_EFFECTS[eName].static == true,
            }
        end
    end

    ALL_EFFECTS[eName]:HUDOnUpdate(inst, self.effects[eName])
    if not ALL_EFFECTS[eName].noicon then
        inst:PushEvent("gfEFUpdateIcon", {eName = eName, timer = timer, stacks = stacks})
    end
end

local function RemoveClasifiedEffect(inst, eName)
    local self = inst.replica.gfeffectable

    ALL_EFFECTS[eName]:HUDOnRemove(inst, self.effects[eName])

    if not GFGetIsMasterSim() then
        self.effects[eName] = nil
    end

    if not ALL_EFFECTS[eName].noicon then
        inst:PushEvent("gfEFRemoveIcon", {eName = eName})
    end
end

local function DoDeserealizeEventStream(classified)
    if classified._parent == nil then return end
    --local self = classified._parent.replica.gfeffectable

    local eventsArray = classified._gfEFEventStream:value():split('^')
    for i = 1, #eventsArray do
        local eventData = eventsArray[i]:split(';')
        if #eventData >= 2 then --don't need to process invalid strings
            local eName = EFFECTS_IDS[tonumber(eventData[2])]
            if eName ~= nil then
                if eventData[1] == '1' or eventData[1] == '2' then --create a new icon for effect
                    UpdateClassifiedEffect(classified._parent, eName, tonumber(eventData[3] or 0), tonumber(eventData[4] or 1))
                elseif eventData[1] == '3' then --remove an icon
                    RemoveClasifiedEffect(classified._parent, eName)
                end
            end
        end
    end
end

local function DeserealizeEventStream(classified)
    if classified._parent ~= nil and classified._parent == ThePlayer then
        classified:DoTaskInTime(0, DoDeserealizeEventStream)
    end
end

local function DeserializeStaticHovers(inst)
    local self = inst.replica.gfeffectable

    --if GFGetIsMasterSim() then self:GenerateHoverStrings(true) return end

    local effectsArray = self._staticEString:value():split(';')
    local currEffects = {}

    for _, eID in pairs(effectsArray) do
        local eName = EFFECTS_IDS[tonumber(eID)]
        currEffects[eName] = true --set that the effect exists, nonexisting effects will be removed
        local eData = self.effects[eName]

        if eData == nil then
            eData = {}
            eData.expirationTime = 0
            eData.stacks = 1
            eData.static = ALL_EFFECTS[eName].static
            self.effects[eName] = eData

            eInst:ClientOnApply(inst, eData)
        end
    end

    --removing nonexistent effects
    for eName, _ in pairs(self.effects) do
        if ALL_EFFECTS[eName].type >= 3 and not currEffects[eName] then
            eInst:ClientOnRemove(inst, self.effects[eName])
            self.effects[eName] = nil
        end
    end

    self:GenerateHoverStrings(true)
end

local function DeserializeActiveHovers(inst)
    local self = inst.replica.gfeffectable

    --if GFGetIsMasterSim() then self:GenerateHoverStrings(false) return end

    local effectsArray = self._activeEString:value():split(';')
    local currEffects = {}

    for _, eID in pairs(effectsArray) do
        local eName = EFFECTS_IDS[tonumber(eID)]
        currEffects[eName] = true --set that the effect exists, nonexisting effects will be removed
        local eData = self.effects[eName]
        local eInst = ALL_EFFECTS[eName]

        if eData == nil then
            eData = {}
            eData.expirationTime = 0
            eData.stacks = 1
            if eInst.static then eData.static = true end
            self.effects[eName] = eData

            eInst:ClientOnApply(inst, eData)
        end
    end

    --removing nonexistent effects
    for eName, _ in pairs(self.effects) do
        if ALL_EFFECTS[eName].type < 3 and not currEffects[eName] then
            eInst:ClientOnRemove(inst, self.effects[eName])
            self.effects[eName] = nil
        end
    end

    self:GenerateHoverStrings(false)
end

local GFEffectable = Class(function(self, inst)
    self.inst = inst
    self.effects = {}

    --don't want to calculate hover for the hoverer widget every tick
    --will create them when effects are updated
    self.hudInfo = 
    {
        positiveString = "",
        negativeString = "",
        affixString = "",
        enchantString = "",
    }

    if self.classified == nil and inst.player_classified ~= nil then
        self:AttachClassified(inst.player_classified)
    end

    self._task = nil

    --1)static - for affixes and enchants - this effects shouldn't update often
    --2)active - for buffs and debuffs - this effects may update very often
    self._staticEString = net_string(inst.GUID, "GFEffectable._staticEString", "gfEFStaticDirty")
    self._activeEString = net_string(inst.GUID, "GFEffectable._activeEString", "gfEFActiveDirty")

    if not GFGetIsMasterSim() then
        inst:ListenForEvent("gfEFStaticDirty", DeserializeStaticHovers)
        inst:ListenForEvent("gfEFActiveDirty", DeserializeActiveHovers)
    end
end)

----------------------------------------------------
--classified methods (both sides)-------------------
----------------------------------------------------

function GFEffectable:AttachClassified(classified)
    if self.classified ~= nil then return end

    self.classified = classified
    --default things, like in the others replicatable components
    self.ondetachclassified = function() self:DetachClassified() end
    self.inst:ListenForEvent("onremove", self.ondetachclassified, classified)

    if not GFGetIsMasterSim() then
        self.inst:ListenForEvent("gfEFEventDirty", DeserealizeEventStream, classified)
    end
end

function GFEffectable:DetachClassified()
    --default things, like in the others replicatable components
    self.classified = nil
    self.ondetachclassified = nil
end

----------------------------------------------------
--server-only methods-------------------------------
----------------------------------------------------

function GFEffectable:UpdateReplicaEffects(static)
    --replica effects needs only hovers
    --so client should know only about the presense of them
    local str = {}
    for eName, _ in pairs(self.effects) do
        local eInst = ALL_EFFECTS[eName]
        local type = eInst.type
        if static then
            if type == 3 or type == 4 then table.insert(str, ALL_EFFECTS[eName].id) end
        else
            if type == 1 or type == 2 then table.insert(str, ALL_EFFECTS[eName].id) end
        end
    end

    --use 2 net strings:
    --1)static - for affixes and enchants - this effects shouldn't update often
    --2)active - for buffs and debuffs - this effects may update very often

    if static then
        str = table.concat(str, ';')
        self._staticEString:set_local(str)
        self._staticEString:set(str)

        if not GFGetIsDedicatedNet() then
            self:GenerateHoverStrings(true) --generating hover strings for the host player
        end
    else
        str = table.concat(str, ';')
        self._activeEString:set_local(str)
        self._activeEString:set(str)

        if not GFGetIsDedicatedNet() then
            self:GenerateHoverStrings(false) --generating hover strings for the host player
        end
    end
end

function GFEffectable:ApplyEffect(eName)
    local eInst = ALL_EFFECTS[eName]
    if GFGetIsMasterSim() and eInst.type ~= 0 then
        self.effects = self.inst.components.gfeffectable.effects 
        if self.effects[eName] == nil then return end

        if eInst.pushToReplica then
            self:UpdateReplicaEffects(eInst.type >= 3)
            --print("replica fx")
            eInst:ClientOnApply(self.inst, self.effects[eName])
        end

        if self.classified ~= nil and eInst.pushToClassified then
            if self.inst == ThePlayer and not GFGetIsDedicatedNet() then
                --if inst is the not dedicated host-player, don't need to push net variable
                eInst:HUDOnUpdate(self.inst, self.effects[eName])
                if not eInst.noicon then
                    self.inst:PushEvent("gfEFUpdateIcon", {eName = eName})
                end
            else
                --tell the player-client about a new effect
                local eData = self.effects[eName]
                local expTime = eInst.static == true and 0 or eData.expirationTime - GetTime()
                self.classified._gfEFEventStream:push_string(string.format("1;%i;%.2f;%i", ALL_EFFECTS[eName].id, expTime, eData.stacks))
            end
        end
    end

    --GFDebugPrint(("%s applies %s"):format(tostring(self.inst), eName))
end

function GFEffectable:RefreshEffect(eName)
    --replica effects (hovers) don't need to be refreshed, 
    --because client should know only about the presense of a effect
    local eInst = ALL_EFFECTS[eName]
    if GFGetIsMasterSim() and self.classified ~= nil and eInst.type ~= 0 and eInst.pushToClassified then
        --but always client should know full information about classified effects (icon)
        self.effects = self.inst.components.gfeffectable.effects
        if self.effects[eName] == nil then return end

        if self.inst == ThePlayer and not GFGetIsDedicatedNet() then
            --if inst is the not dedicated host-player, don't need to push net variable
            eInst:HUDOnUpdate(self.inst, self.effects[eName])
            if not eInst.noicon then
                self.inst:PushEvent("gfEFUpdateIcon", {eName = eName})
            end
        else
            --tell the player-client that the effect was updated
            local eData = self.effects[eName]
            local expTime = eInst.static == true and 0 or eData.expirationTime - GetTime()
            self.classified._gfEFEventStream:push_string(string.format("2;%i;%.2f;%i", ALL_EFFECTS[eName].id, expTime, eData.stacks))
        end
    end

    --GFDebugPrint(("%s refreshes %s"):format(tostring(self.inst), eName))
end

function GFEffectable:RemoveEffect(eName)
    local eInst = ALL_EFFECTS[eName]
    if GFGetIsMasterSim() and eInst.type ~= 0 then
        self.effects = self.inst.components.gfeffectable.effects
        if self.effects[eName] == nil then return end

        if eInst.pushToReplica then
            self:UpdateReplicaEffects(eInst.type >= 3)
            eInst:ClientOnRemove(self.inst, self.effects[eName])
        end

        if self.classified ~= nil and eInst.pushToClassified then
            if self.inst == ThePlayer and not GFGetIsDedicatedNet() then
                --if inst is the not dedicated host-player, don't need to push net variable
                eInst:HUDOnRemove(self.inst)
                if not eInst.noicon then
                    self.inst:PushEvent("gfEFRemoveIcon", {eName = eName})
                end
            else
                --tell the player-client that the effect was removed
                self.classified._gfEFEventStream:push_string(string.format("3;%i", ALL_EFFECTS[eName].id))
            end
        end
    end

    --GFDebugPrint(("%s removes %s"):format(tostring(self.inst), eName))
end

----------------------------------------------------
--both-sides methods--------------------------------
----------------------------------------------------

function GFEffectable:GenerateHoverStrings(static)
    local tmp1, tmp2 = {}, {}
    
    for eName, _ in pairs(self.effects) do
        local eInst = ALL_EFFECTS[eName]
        local type = eInst.type
        if eInst.pushToReplica then
            if static then
                if type == 3 then
                    table.insert(tmp1, GetEffectString(eName, "hover"))
                elseif type == 4 then
                    table.insert(tmp2, GetEffectString(eName, "hover"))
                end
            else
                if type == 1 then
                    table.insert(tmp1, GetEffectString(eName, "hover"))
                elseif type == 2 then
                    table.insert(tmp2, GetEffectString(eName, "hover"))
                end
            end
        end
    end

    if static then
        self.hudInfo.affixString    = #tmp1 > 0 and table.concat(tmp1, ", ") or ""
        self.hudInfo.enchantString  = #tmp2 > 0 and table.concat(tmp2, ", ") or ""
    else
        self.hudInfo.positiveString = #tmp1 > 0 and table.concat(tmp1, ", ") or ""
        self.hudInfo.negativeString = #tmp2 > 0 and table.concat(tmp2, ", ") or ""
    end
end

function GFEffectable:HasEffect(eName)
    if self.inst.components.gfeffectable then
        return self.inst.components.gfeffectable:HasEffect(eName)
    else
        return self.effects[eName] ~= nil
    end
end

function GFEffectable:GetRemainTime(eName)
    if self.inst.components.gfeffectable then
        return self.inst.components.gfeffectable:GetRemainTime(eName)
    else
        return self.effects[eName] ~= nil and math.max(self.effects[eName].expirationTime - GetTime(), 0) or 0
    end
end


return GFEffectable