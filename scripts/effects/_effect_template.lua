local function OnApply(effect, inst, effectParam)
    print(("Effect %s applied to %s"):format(effect.name, tostring(inst)))
end

local function OnRefresh(effect, inst, effectParam)
    print(("Effect %s refreshed on %s"):format(effect.name, tostring(inst)))
end

local function OnUpdate(effect, inst)
    print(("Effect %s updated on %s"):format(effect.name, tostring(inst)))
end

local function OnRemove(effect, inst)
    print(("Effect %s removed from %s"):format(effect.name, tostring(inst)))
end

local function DoCheck(effect, inst, effectParam)
    --check for required components, tags and other things
    return true
end

local function HudOnApply(effect, inst)
    print(("Effect %s HUD OnApply for %s"):format(effect.name, tostring(inst)))
end

local function HudOnRemove(effect, inst)
    print(("Effect %s Hud OnRemove for %s"):format(effect.name, tostring(inst)))
end

local function fn()
    local effect = GF.CreateStatusEffect()

    --type defines colour and position for text
    effect.type = 1 --0 - server only, 1 - positive, 2 - negative, 3 - affix, 4 enchant

    --network
    effect.pushToReplica = true    --need to push to all clients (hover on an entity)
    effect.pushToClassified = true --need to push to the affected player (icon on the panel)

    --image - for panel only (doesn't do anything if pushToClassified = false)
    effect.icon = nil       --texture
    effect.iconAtlas = nil  --atlas

    --effects strings should be defined in global STRINGS
    --STRINGS.GF.EFFECTS.MY_FIRST_EFFECT = {}
    --STRINGS.GF.EFFECTS.MY_FIRST_EFFECT.TITLE = "My Effect"        --only for pushToClassified
    --STRINGS.GF.EFFECTS.MY_FIRST_EFFECT.DESC = "It's my effect."   --only for pushToClassified
    --STRINGS.GF.EFFECTS.MY_FIRST_EFFECT.HOVER = "my effect."       --only for pushToReplica
    --where MY_FIRST_EFFECT is the effects name (check the last string of this file) in the upper case

    --functions
    effect.checkfn = DoCheck
    effect.onapplyfn = OnApply
    effect.onrefreshfn = OnRefresh
    effect.onupdatefn = OnUpdate
    effect.onremovefn = OnRemove

    --hud functions
    effect.hudonapplyfn = HudOnApply    --called on clients when the effect is applied or refreshed
    effect.hudonremovefn = HudOnRemove  --called on clients when the effect is removed

    --flags
    effect.savable = false --save effect or not
    effect.nonRefreshable = false --can effect be refreshed or not

    effect.updateDurationOnRefresh = true
    effect.updateStacksOnRefresh = false
    effect.updateable = true            --need to update on ticks or not
    effect.static = true                --for static effects without timers (affixes and etc)
    effect.sleeper = false              --effects will not updated if entity is asleep (not sleeper component!)
    effect.removableByStacks = true     --can be removed by consuming stacks or not

    --numbers
    effect.maxStacks = 1
    effect.baseDuration = 10    --base duration
    effect.tickPeriod = 1       --how often the onupdate function will be called 

    return effect
end

return GF.StatusEffect("my_first_effect", fn)