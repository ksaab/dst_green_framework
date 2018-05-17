local GFEffect = require("gf_effect")

local function OnUpdate(self, inst)
    inst.components.health:DoDelta(10)
    SpawnPrefab("green_leaves_chop").Transform:SetPosition(inst.Transform:GetWorldPosition())
end

local function DoCheck(self, inst, effectParam)
    --check for required components, tags and other things
    return inst.components.health ~= nil
end

local function HudOnApply(self, inst)
    print(("Effect %s HUD OnApply for %s"):format(self.name, tostring(inst)))
end

local function HudOnRemove(self, inst)
    print(("Effect %s Hud OnRemove for %s"):format(self.name, tostring(inst)))
end


local Effect = Class(GFEffect, function(self, inst)
    GFEffect._ctor(self, "lesser_rejuvenation") --inheritance
    self.type = 1

    self.hoverText = "rejuvenation" --text under name for pos and neg effect, text above for affixes
    self.titleText = "Lesser Rejuvenation" --title for icon
    self.descText = "Heals over time." --text for icon

    self.wantsIcon = true
    self.wantsHover = true

    --self.hudonapplyfn = HudOnApply --effect applied
    --self.hudonrefreshfn = HudOnRefresh --effect refreshed
    --self.hudonremovefn = HudOnRemove --effect removed

    if not GFGetIsMasterSim() then return end

    self.updateable = true
    self.static = false

    self.tags = 
    {
        healing = true,
        positive = true,
    }

    self.baseDuration = 20
    self.tickPeriod = 1

    --self.followPrefab = "effectbloodlust"
    --self.followPrefabOffset = true

    --self.onapplyfn = OnApply
    --self.onrefreshfn = OnRefresh
    self.onupdatefn = OnUpdate
    --self.onremovefn = OnRemove

    self.checkfn = DoCheck
end)

return Effect