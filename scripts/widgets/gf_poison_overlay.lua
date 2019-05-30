local Widget = require "widgets/widget"
local Image = require "widgets/image"
local easing = require("easing")

local PoisonOverlay = Class(Widget, function(self, owner)
	self.owner = owner
    Widget._ctor(self, "PoisonOverlay")

    self:SetClickable(false)

    self.sources = {}
    
    self.lastpeak = GetTime()
    self.needtostop = true
    self.current = 0
    self.max = 1
    self.min = 0

    self.bg = self:AddChild(Image("images/gfoverlays.xml", "poison_overlay.tex"))
    self.bg:SetVRegPoint(ANCHOR_MIDDLE)
    self.bg:SetHRegPoint(ANCHOR_MIDDLE)
    self.bg:SetVAnchor(ANCHOR_MIDDLE)
    self.bg:SetHAnchor(ANCHOR_MIDDLE)
    self.bg:SetScaleMode(SCALEMODE_FILLSCREEN)
	
	self:Hide()

    self.inst:ListenForEvent("gfHUDPushPoison", function(inst, data)
        if data ~= nil and data.source ~= nil and data.percent ~= nil and data.percent > 0 then
            self:PushSource(data.source, data.percent) 
        end
    end, self.owner)

    self.inst:ListenForEvent("gfHUDPopPoison", function(inst, data)
        if data ~= nil and data.source ~= nil then
            self:RemoveSource(data.source) 
        end
    end, self.owner)

    print("Poison Effect HUD added to ", self.owner)
end)

function PoisonOverlay:PushSource(source, percent)
    self:Show()
    self:StartUpdating()

    self.sources[source] = percent
    self.needtostop = false
    self.min = 0.1

    local max, source = 0, "unknown"
    for k, v in pairs(self.sources) do
        if v > max then max = v end --source = k end
    end

    if max > 0 then
        self.max = easing.inQuad(max, 0.25, 0.75, 1)
        if self._max == nil then self._max = self.max end
        --print("now strength is", max, "from", source)
    end
end

function PoisonOverlay:RemoveSource(source)
    --self:Hide()
    --self:StopUpdating()
    --print("source", source, "removed")
    self.sources[source] = nil
    local max = 0 --, source = 0, "unknown"
    for k, v in pairs(self.sources) do
        if v > max then max = v end --source = k end
    end

    if max == 0 then
        --print("no more sources, disabling")
        self.needtostop = true
        self.min = 0
    else
        self.max = easing.inQuad(max, 0.25, 0.75, 1)
        --print("now strength is", max, "from", source)
    end
end

function PoisonOverlay:OnUpdate(dt)
    if not self.needtostop  then
        if self.current > self._max then
            self.fade = true
            self.lastpeak = GetTime()
        elseif self.current < self.min then
            self.fade = false
            self.lastpeak = GetTime()
            self._max = self.max
        end

        if self.fade then
            self.current = easing.inQuad(GetTime() - self.lastpeak, self._max, self.min - self._max, 3)
        else
            self.current = easing.inQuad(GetTime() - self.lastpeak, self.min, self._max - self.min, 2)
        end
    else
        self.current = self.current - dt
    end

    self.bg:SetTint(1, 1, 1, self.current)

    if self.current <= self.min and self.needtostop then
        --print("current is 0, stop updating") 
        self:StopUpdating()
        self:Hide()
    end
end

return PoisonOverlay