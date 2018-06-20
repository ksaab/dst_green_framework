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


local Effect = Class(GFEffect, function(self, inst)
    GFEffect._ctor(self, "testpositive") --inheritance
    self.type = 1

    self.hoverText = "test positive" --text under name for pos and neg effect, text above for affixes
    self.titleText = "Test positive" --title for icon
    self.descText = "It's a positive test effect." --text for icon

    self.wantsIcon = true
    self.wantsHover = true

    self.hudonapplyfn = HudOnApply --effect applied
    self.hudonrefreshfn = HudOnRefresh --effect refreshed
    self.hudonremovefn = HudOnRemove --effect removed

    self.updateable = true
    self.static = false

    self.tags = 
    {
        damage = true
    }

    self.baseDuration = 20
    self.tickPeriod = 1

    self.followPrefab = "effectbloodlust"
    self.followPrefabOffset = true

    self.onapplyfn = OnApply
    self.onrefreshfn = OnRefresh
    self.onupdatefn = OnUpdate
    self.onremovefn = OnRemove

    --self.checkfn = DoCheck
end)

return Effect