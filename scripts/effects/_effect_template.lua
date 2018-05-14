local GFEffect = require("gf_effect")

local function OnApply(self, inst, effectParam)
    print(("Effect %s applied to %s"):format(self.name, tostring(inst)))
end

local function OnRefresh(self, inst, effectParam)
    print(("Effect %s refreshed on %s"):format(self.name, tostring(inst)))
end

local function OnUpdate(self, inst)
    print(("Effect %s updated on %s"):format(self.name, tostring(inst)))
end

local function OnRemove(self, inst)
    print(("Effect %s removed from %s"):format(self.name, tostring(inst)))
end

local function DoCheck(self, inst, effectParam)
    --check for required components, tags and other things
    return true
end

local function HudOnApply(self, inst)
    print(("Effect %s HUD OnApply for %s"):format(self.name, tostring(inst)))
end

local function HudOnRefresh(self, inst)
    print(("Effect %s Hud OnRefresh for %s"):format(self.name, tostring(inst)))
end

local function HudOnRemove(self, inst)
    print(("Effect %s Hud OnRemove for %s"):format(self.name, tostring(inst)))
end

local Effect = Class(GFEffect, function(self, name)
    --[[SERVER AND CLIENT]]
    GFEffect._ctor(self, "Effectname") --inheritance
    self.type = 0 --Effect type: 0 - server side only, 1 - positive, 2 - negative, 3 - affix, 4 - enchant

    --image
    self.icon = nil
    self.iconAtlas = nil

    --text info
    self.enchantText = nil --text ABOVE name
    self.hoverText = nil --text UNDER name
    self.titleText = nil --title for icon
    self.descText = nil --text for icon

    --flags
    self.wantsIcon = false
    self.wantsHover = false

    --hudfunctions are called on clients, when
    self.hudonapplyfn = HudOnApply --effect applied
    self.hudonrefreshfn = HudOnRefresh --effect refreshed
    self.hudonremovefn = HudOnRemove --effect removed

    if not GFGetIsMasterSim() then return end
    --[[SERVER ONLY]]
    --flags
    self.nonRefreshable = false --can effect be refreshed or not
    self.updateDurationOnRefresh = true
    self.updateStacksOnRefresh = true
    self.updateable = true --need to update on ticks or not
    self.static = true --for static effects without timers (affixes and etc)
    self.savable = false --save effect or not
    self.removableByStacks = true --can be removed by consuming stacks or not

    --effect data
    self.tags = {} --can be used for resists checks, event listeners and etc
    self.applier = nil --who apply the effect
    self.stacks = 0 --current amount of stacks
    self.maxStacks = 1 --max amount of stacks

    --effect timers
    self.expirationTime = 0
    self.applicationTime = 0
    self.updateTime = 0 --this will be setted is gfeffectable
    self.baseDuration = 10 --base duration
    self.tickPeriod = 1 --how often onupdate function will be called 
    
    --functions, feel free to set any to nil
    self.checkfn = DoCheck
    self.onapplyfn = OnApply
    self.onrefreshfn = OnRefresh
    self.onupdatefn = OnUpdate
    self.onremovefn = OnRemove

    GFDebugPrint(("Effect: effect %s created"):format(self.name))
end)

return Effect