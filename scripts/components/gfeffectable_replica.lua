--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

local effectList = GFEffectList
local effectNamesToID = GFEffectNameToID
local effectIDToNames = GFEffectIDToName

local invalidString = "<NO INFO>"

local function GenerateHudInfo(inst)
    --reset info
    local self = inst.replica.gfeffectable

    self.hudInfo.positive = {}
    self.hudInfo.negative = {}

    local postable = {}
    local negtable = {}
    local affixtable = {}
    local enchtable = {}

    for effectName, effect in pairs(self.effects) do
        local type = effect.type
        if type == 1 then
            --positive effects
            if effect.wantsIcon then self.hudInfo.positive[effectName] = effect end
            if effect.wantsHover then table.insert(postable, effect.hoverText or invalidString) end
        elseif type == 2 then
            --negative effects
            if effect.wantsIcon then self.hudInfo.negative[effectName] = effect end
            if effect.wantsHover then table.insert(negtable, effect.hoverText or invalidString) end
        elseif type == 3 then
            --affixes
            if effect.wantsHover then table.insert(affixtable, effect.hoverText or invalidString) end
        elseif type == 4 then
            --enchants
            if effect.wantsHover then table.insert(enchtable, effect.hoverText or invalidString) end
        elseif type ~= 0 then
            GFDebugPrint(("GFEffectable Replica: effects %s has invalid type %i"):format(effectName, type))
        end
    end

    self.hudInfo.positiveString = #postable > 0 and table.concat(postable, ", ") or nil
    self.hudInfo.negativeString = #negtable > 0 and table.concat(negtable, ", ") or nil
    self.hudInfo.affixString = #affixtable > 0 and table.concat(affixtable, ", ") or nil
    self.hudInfo.enchantString = #enchtable > 0 and table.concat(enchtable, ", ") or nil

    --print("Update hud info")
    inst:PushEvent("gfupdateeffectshud")
end

local function DeserializeEffects(inst)
    local self = inst.replica.gfeffectable
    --GFDebugPrint("GFEffectable Replica: effects string: ", self._effectsList:value())
    --if GFGetIsMasterSim() then return end
    local effectsArray = self._effectsList:value():split(';')
    local newEffects = {}
    local currTime = GetTime()
    for k, v in pairs(effectsArray) do
        local effectsString = v:split(',')
        local effectName = effectIDToNames[tonumber(effectsString[1])]
        local effectStacks = tonumber(effectsString[2]) or 1
        local effectRemain = tonumber(effectsString[3]) or 0
        --local effectTotal = tonumber(effectsString[4]) or 0
        newEffects[effectName] = true --set that the effect exists, nonexisting effects will be removed

        local effect = self.effects[effectName]
        
        if effect == nil then
            effect = effectList[effectName]()
            self.effects[effectName] = effect
            if effect.hudonapplyfn  and inst == GFGetPlayer() then
                effect:hudonapplyfn(inst)
            end
        else
            if effect.hudonrefreshfn and inst == GFGetPlayer() --[[and effect.stacks ~= effectStacks]] then
                effect:hudonrefreshfn(inst)
            end
        end
        effect.expirationTime = effect.static and 0 or effectRemain + currTime
        effect.stacks = effectStacks
    end

    for effName, effect in pairs(self.effects) do
        --removing nonexistent effects
        if not newEffects[effName] then
            if effect.hudonremovefn and inst == GFGetPlayer() then
                effect:hudonremovefn(inst)
            end
            self.effects[effName] = nil
        end
    end

    GenerateHudInfo(inst)
end

local GFEffectable = Class(function(self, inst)
    self.inst = inst
    self.effects = {}
    self.hudInfo = 
    {
        positive = {},
        negative = {},
        positiveString = "",
        negativeString = "",
        affixString = "",
        enchantString = "",
    }

    self._effectsList = net_string(inst.GUID, "GFEffectable._effectsList", "gfeffectsupdated")
    if not GFGetIsMasterSim() then
        inst:ListenForEvent("gfeffectsupdated", DeserializeEffects)
    elseif not GFGetIsDedicatedNet() then
        inst:ListenForEvent("gfeffectsupdated", GenerateHudInfo)
    end
end)

function GFEffectable:UpdateEffectsList()
    local comp = self.inst.components.gfeffectable
    local str = {}
    local currTime = GetTime()
    self.effects = comp.effects
    for effectName, effect in pairs(comp.effects) do
        if effect.type ~= 0 then --0 is the server only effect type
            local expTime = (effect.static or effect.aura) and 0 or effect.expirationTime - currTime
            --print(string.format("%i,%i,%.2f", effectNamesToID[effectName], effect.stacks, expTime))
            table.insert(str, string.format("%i,%i,%.2f", effectNamesToID[effectName], effect.stacks, expTime))
        end
    end

    local setstr = table.concat(str, ';')
    self._effectsList:set_local(setstr)
    self._effectsList:set(setstr)
end

return GFEffectable