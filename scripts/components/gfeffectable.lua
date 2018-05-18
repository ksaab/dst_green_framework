local effectList = GFEffectList

local function RemoveEffectsOnDeath(inst)
    inst.components.gfeffectable:RemoveAllEffects(false, "death")
end

local gfEffectsSymbols = { 
	greententacle = {"tentacle_pieces", -560},	
    monkey = {"kiki_head", -100},	
    mole = {"mole_body", -100},	
    spider = {"body", -100},	
    walrus = {"pig_torso", -200},	
    knight = {"spring", -200},	
    bee = {"body", -100},	
    --houndmound = {not_found, -200},	
    pigman = {"pig_torso", -200},	
    rabbit = {"chest", -100},	
    beefalo = {"beefalo_body", -400},	
    catcoon = {"catcoon_torso", -100},	
    merm = {"pig_torso", -200},	
    beehive = {"beehive_01", -260},	
    tallbird = {"head", -400},	
    lizardman = {"body", -200},	
    bishop = {"waist", -200},	
    spiderden = {"c1", -360},	
    spider_dropper = {"body", -100},	
    spider_hider = {"body", -100},	
    tentacle = {"tentacle_pieces", -560},	
    spider_spitter = {"body", -100},	
    wasphive = {"waspnest_pieces", -260},	
    slurtle = {"shell", -200},	
    lightninggoat = {"lightning_goat_body", -200},	
    worm = {"wormlure", 0},	
    rocky = {"chest", -200},	
    spider_warrior = {"body", -100},	
    green_snake = {"body", -200},	
    frog = {"frogsack", -100},	
    robin = {"crow_body", -100},
    crawlinghorror = {"shadowcreature1_body", -260 },
    terrorbeak = {"shadowcreature2_body", -860 },
    killerbee = {"body", -100},
    smallbird = {"head", -100},
    mossling = {"swap_fire", -200},
    mosquito = {"body", -100},
    leif = {"marker", -400},
    rook = {"swap_fire", -200},
    crow = {"crow_body", -100},
    spiderqueen = {"body", -400},		
    babybeefalo = {"beefalo_body", -200},	
    bat = {"bat_body", -200},
    buzzard = {"buzzard_body", -200},
    moose = {"swap_fire", -400},
    hound = {"hound_body", -200},
    icehound = {"hound_body", -200},
    butterfly = {"butterfly_body", -100},
    perd = {"pig_torso", -200},
    bunnyman = {"manrabbit_torso", -200},
    rook_nightmare = {"swap_fire", -200},
    minotaur = {"spring", -200},
    bishop_nightmare = {"waist", -200},			
    knight_nightmare = {"spring", -200},	
    pigking = {"pigking_torso", -200},		
}

local function SetFollowSymbol(self)
    local inst = self.inst
    local symbol, y
    if inst:HasTag("player") then
        symbol = "torso"
        y = -200
    else
        --if symbol wasn't declared before, try to find it
        if gfEffectsSymbols[inst.prefab] ~= nil then
            local symb = gfEffectsSymbols[inst.prefab]
            symbol = symb[1]
            y = symb[2]
        else					
            if inst.AnimState ~= nil then
                local animState = inst.AnimState

                --searching for valid symbol
                if inst.components.burnable ~= nil
                    and inst.components.burnable.fxdata[1] ~= nil
                    and inst.components.burnable.fxdata[1].follow ~= nil
                then
                    symbol = inst.components.burnable.fxdata[1].follow
                else
                    if animState:BuildHasSymbol(inst.prefab .. "_torso") then
                        symbol = inst.prefab .. "_torso"
                    elseif animState:BuildHasSymbol(inst.prefab .. "_body") then
                        symbol = inst.prefab .. "_body"
                    elseif animState:BuildHasSymbol("chest") then
                        symbol = "chest"
                    elseif animState:BuildHasSymbol("torso") then
                        symbol = "torso"
                    elseif animState:BuildHasSymbol("body") then
                        symbol = "body"
                    end
                end

                --searching for offset
                if inst:HasTag("smallcreature") then
                    y = -100
                elseif inst:HasTag("largecreature") then
                    y = -400
                end
            end
        end
    end

    self.followSymbol = symbol or "not_found"
    self.followYOffset = y or -200

    if not gfEffectsSymbols[inst.prefab] then
        gfEffectsSymbols[inst.prefab] = {self.followSymbol, self.followYOffset }
        print("new symbol for effectable:")
        print(("%s = {\"%s\", %i}"):format(tostring(inst.prefab), self.followSymbol, self.followYOffset))
    end
end

local GFEffectable = Class(function(self, inst)
    self.inst = inst
    self.effects = {}
    self.resists = {}

    self.isNew = true
    --set data for effect fx
    self.effectsfx = {}
    self.followSymbol = "body"
    self.followYOffset = -200

    self.isUpdating = false
    
    inst:AddTag("gfeffectable")

    inst:ListenForEvent("death", RemoveEffectsOnDeath)
    SetFollowSymbol(self)
    --inst:StartUpdatingComponent(self)
end)

function GFEffectable:ChangeResist(resist, value)
    if resist == nil or value == nil then 
        GFDebugPrint("GFEffectable: can't add resist, data is wrong")
        return 
    end
    local res = self.resists[resist]
    self.resists[resist] = res == nil and value or res + value
end

function GFEffectable:GetResist(resist)
    return self.resists[resist] or 0
end

function GFEffectable:CheckResists(effect)
    if effect.checkfn and not effect:checkfn(self.inst) then  --effect check (maybe the target doesn't have the required component)
        GFDebugPrint(("GFEffectable: effects %s can not be applied to %s"):format(effect.name, tostring(self.inst)))
        return false
    end
    
    if not effect.ignoreResist then --check for resists
        for tag, value in pairs(effect.tags) do
            if self.resists[tag] and self.resists[tag] ~= 0 then
                if math.random() < self.resists[tag] then
                    GFDebugPrint(("GFEffectable: effects %s was resisted by %s"):format(effect.name, tostring(self.inst)))
                    self.inst:PushEvent("gfeffectresisted", {effect = effect})
                    return false
                end
            end
        end
    end

    return true
end

function GFEffectable:ApplyEffect(effectName, effectParam)
    local effectLink = effectList[effectName]
    if effectLink == nil then 
        --effect isn't valid
        print(("GFEffectable: effect with name %s not found"):format(effectName))
        return false
    end

    effectParam = effectParam or {} --set to empty if nil
    local effect

    if self.effects[effectName] then
        --effect already exists on entity
        effect = self.effects[effectName]
        if not effect.nonRefreshable --not all effects are refresheable
            and self:CheckResists(effect) --check resists and other stuff
        then 
            effect:Refresh(self.inst, effectParam)
            if not effect.static then
                self.inst:PushEvent("gfeffectrefreshed", {effect = effect})
            end
            self.inst.replica.gfeffectable:UpdateEffectsList()

            --update user interface for host, clients call this from the replica 
            if self.inst == ThePlayer and effect.hudonrefreshfn then
                effect:hudonrefreshfn(self.inst)
            end

            return true
        end
    else
        --applying the new effect
        effect = effectLink(effectParam)
        if self:CheckResists(effect) then --check resists and other stuff
            effect:Apply(self.inst, effectParam)
            self.effects[effectName] = effect
            if not effect.static then
                self.inst:PushEvent("gfeffectapplied", {effect = effect})
            end
            self.inst.replica.gfeffectable:UpdateEffectsList()

            if effect.applyPrefab then
                local fx = SpawnPrefab(effect.applyPrefab)
                if fx and fx.Follower ~= nil then
                    local yof = effect.applyPrefabOffset and self.followYOffset or 0
                    fx.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
                    fx.Follower:FollowSymbol(self.inst.GUID, self.followSymbol, 0, yof + (fx.yOffset or 0), 0)
                    fx.entity:SetParent(self.inst.entity)
                    fx:ApplyFX()
                else
                    fx:DoTaskInTime(0, fx.Remove)
                end
            end

            if effect.followPrefab then
                local fx = SpawnPrefab(effect.followPrefab)
                if fx and fx.Follower ~= nil then
                    local yof = effect.followPrefabOffset and self.followYOffset or 0
                    fx.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
                    fx.Follower:FollowSymbol(self.inst.GUID, self.followSymbol, 0, yof + (fx.yOffset or 0), 0)
                    fx.entity:SetParent(self.inst.entity)
                    self.effectsfx[effectName] = fx
                    fx:StartFollowFX()
                else
                    fx:DoTaskInTime(0, fx.Remove)
                end
            end

            --update user interface for host, clients call this from the replica 
            if self.inst == ThePlayer and effect.hudonapplyfn then
                effect:hudonapplyfn(self.inst)
            end

            if not effect.static--[[ and not self.isUpdating]] then --static effects are permanent modificators, so don't need to update
                self.inst:StartUpdatingComponent(self)
                self.isUpdating = true
            end

            return true
        end
    end

    return false
end

--this wasn't tested, but should work
function GFEffectable:ConsumeStacks(effectName, value)
    if effectName == nil or self.effects[effectName] == nil then return end
    self.effects[effectName]:ConsumeStack(inst, value)
    if self.effects[effectName] ~= nil then
        self.inst.replica.gfeffectable:UpdateEffectsList()
        if self.effects[effectName].hudonrefreshfn then
            self.effects[effectName]:hudonrefreshfn(self.inst)
        end
    end
end

function GFEffectable:RemoveEffect(effectName, reason)
    reason = reason or "expire"

    local effect = self.effects[effectName]
    if effect == nil then return end --effect isn't existed on entity

    if self.effectsfx[effectName] and self.effectsfx[effectName]:IsValid() then
        self.effectsfx[effectName]:StopFollowFX()
        self.effectsfx[effectName] = nil
    end

    effect:Remove(self.inst)
    self.effects[effectName] = nil
    self.inst.replica.gfeffectable:UpdateEffectsList()

    --update user interface for host, clients call this from the replica 
    if self.inst == ThePlayer and effect.hudonremovefn then
        effect:hudonremovefn(self.inst)
    end

    if not effect.static then
        self.inst:PushEvent("gfeffectremoved", {effect = effect, reason = reason}) 
    end
end

function GFEffectable:RemoveAllEffects(removeStatic, reason)
    for effectName, effect in pairs(self.effects) do
        if removeStatic or not effect.static then
            self:RemoveEffect(effectName, reason)
        end
    end
end

function GFEffectable:RemoveAllEffectsWithTag(tag, reason)
    if tag == nil then return end
    for effectName, effect in pairs(self.effects) do
        if effect.tags[tag] ~= nil then
            self:RemoveEffect(effectName, reason)
        end
    end
end

function GFEffectable:EffectExists(effectName)
    if effectName == nil then return end
    return self.effects[effectName] or false
end

function GFEffectable:EffectRemainTime(effectName)
    if effectName == nil then return end
    return self.effects[effectName] and math.max(0, self.effects[effectName].expirationTime - GetTime()) or 0
end

function GFEffectable:GetEffectsCount()
    local all = 0
    local nonStatic = 0
    for effectName, effect in pairs(self.effects) do
        all = all + 1
        if not effect.static then
            nonStatic = nonStatic + 1
        end
    end

    return all, nonStatic
end

function GFEffectable:OnUpdate(dt)
    local currTime = GetTime()
    local needToStopUpdating = true
    for effectName, effect in pairs(self.effects) do
        if effect.updateable then
            --call the effect onupdate funtion when it's needed
            if currTime >= effect.updateTime then
                effect:Update(self.inst)
                effect.updateTime = currTime + effect.tickPeriod
            end
        end

        if not effect.static then
            if currTime >= effect.expirationTime then
                self:RemoveEffect(effectName, "expire")
            end
            needToStopUpdating = false
        end
    end

    if needToStopUpdating then
        self.inst:StopUpdatingComponent(self)
        self.isUpdating = false
    end
end

function GFEffectable:OnSave(data)
    local savetable = {}
    local currTime = GetTime()
    for effectName, effect in pairs(self.effects) do
        if effect.savable then
            local remain = effect.expirationTime - currTime
            if effect.static or (effect.expirationTime ~= nil and remain > 0) then
                savetable[effectName] = 
                {
                    remain = remain,
                    --total = effect.expirationTime - effect.applicationTime,
                    stacks = effect.stacks,
                }
            end
        end
    end

    return {savedata = savetable}
end

function GFEffectable:OnLoad(data)
    self.isNew = false
    if data ~= nil and data.savedata ~= nil then 
        local savedata = data.savedata
        for k, v in pairs(savedata) do
            self:ApplyEffect(k, 
                {
                    duration = v.remain, 
                    stacks = v.stacks,
                })
        end
    end
end

function GFEffectable:GetDebugString()
    local currTime = GetTime()
    local str = {}
    for effectName, effect in pairs(self.effects) do
        local timer = effect.static and "static" or string.format("%.2f/%.2f", 
            effect.expirationTime - currTime, effect.expirationTime - effect.applicationTime)
        table.insert(str, string.format("[%s(%i) %s]", effectName, effect.type, timer))
    end

    local res = {}
    for resist, value in pairs(self.resists) do
        table.insert(res, string.format("[%s - %i%%]", resist, value * 100))
    end

    local resstr 
    if #res > 0 then 
        resstr = table.concat(res, ',')
    else
        resstr = "none"
    end

    local a, n = self:GetEffectsCount()
    return string.format("upd: %s effects %i (%i): %s, resists: %s", tostring(self.isUpdating), a, n, table.concat(str, ", "), resstr)
end


return GFEffectable