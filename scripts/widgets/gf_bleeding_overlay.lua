local Widget = require "widgets/widget"
local Image = require "widgets/image"
local easing = require("easing")

--BLOOD STROKE-------------------------------
---------------------------------------------

local ClickThrough = function() 
    return true, true 
end

local BloodStroke = Class(Widget, function(self, panel)
    Widget._ctor(self, "BloodStroke")

    self:Hide()

    self.panel = panel
    self.leakPercent = 0
    self.disapperPercent = 0
    self.mult = 0.3
    self.free = true

    self.size = {0, 0}
    self.pos = Vector3(0, 0, 0)

    self.leak = self:AddChild(Image())
    self.leak:SetVRegPoint(ANCHOR_TOP)

    self._leak = self:AddChild(Image())
    self._leak:SetVRegPoint(ANCHOR_TOP)
    self._leak:SetScale(0.75, 1)
    self._leak:SetTint(0.9, 1, 1, 1)

    self.inst.CanMouseThrough       = ClickThrough
    self.leak.inst.CanMouseThrough  = ClickThrough
    self._leak.inst.CanMouseThrough = ClickThrough
end)

function BloodStroke:InitLeak(scale, mult)
    self:Show()

    self.leakPercent = 0
    self.disapperPercent = 0
    self.mult = 0.3 + (mult or 0.3)
    self._mult = self.mult
    self.free = false

    local xpos = TheSim:GetScreenSize()
    self:SetPosition(math.random(0, xpos) - xpos / 2, 0)

    self:SetScale(scale or 1)

    local variety = math.random(6)
    self.leak:SetTexture("images/gfbloodlines.xml", "blood_line_" .. variety ..".tex")
    self._leak:SetTexture("images/gfbloodlines.xml", "blood_line_blur_" .. variety ..".tex")

    self.leak:SetTint(1, 1, 1, 1)
    self._leak:SetTint(0.9, 1, 1, 1)

    self.size = {self.leak:GetSize()}
    self.pos = self.leak:GetPosition()
end

function BloodStroke:PlayLeak(dt)
    if self.leakPercent < 1 then
        local x, y = self.pos:Get()
        local w, h = unpack(self.size)
        local hpos = - h * self.leakPercent

        self.leak:SetScissor(-w * 0.5, hpos, w, h)
        self._leak:SetScissor(-w * 0.5, hpos - 3, w, h)
        --self.drop:SetPosition(0, hpos + 10)

        self.leakPercent = self.leakPercent + dt * self.mult

        self.mult = math.max(0.3, self._mult * (1 - self.leakPercent))
        --self.mult = math.max(easing.inCubic(self.leakPercent, self._mult, -0.6, 1))
        ----print(self.mult)
    end

    if self.leakPercent > 0.5 then
        if self.disapperPercent < 1 then
            self.leak:SetTint(1, 1, 1, 1 - self.disapperPercent)
            self._leak:SetTint(0.9, 1, 1, 1 - self.disapperPercent)
            --self.drop:SetTint(1, 1, 1, 1 - self.disapperPercent)
            self.disapperPercent = self.disapperPercent + dt * self.mult * 2
        else
            self:StopLeak()
        end
    end
end

function BloodStroke:StopLeak()
    self.panel:KillLeak()
    self:Hide()
    self.free = true
end

--BLOOD OVERLAY------------------------------
---------------------------------------------

local BleedingOverlay = Class(Widget, function(self, owner)
	self.owner = owner
	Widget._ctor(self, "BleedingOverlay")

    self.bg = self:AddChild(Widget("ROOT"))

    self:SetClickable(false)

    self.leaks = {}
    self.sources = {}

    for i = 1, 10 do
        self.leaks[i] = self.bg:AddChild(BloodStroke(self))
    end

    self.strength = 0
    self.totalLeaks = 0
    self.nextLeak = 0
    self.needtostop = true
	
    self:Hide()
    
    self.inst:ListenForEvent("gfHUDPushBleeding", function(inst, data)
        if data ~= nil and data.source ~= nil and data.percent ~= nil and data.percent > 0 then
            self:PushSource(data.source, data.percent) 
        end
    end, self.owner)

    self.inst:ListenForEvent("gfHUDPopBleeding", function(inst, data)
        if data ~= nil and data.source ~= nil then
            self:RemoveSource(data.source) 
        end
    end, self.owner)

    print("Bleeding Effect HUD added to ", self.owner)
end)

function BleedingOverlay:PushSource(source, percent)
    self:Show()
    self:StartUpdating()

    self.sources[source] = percent
    self.needtostop = false

    local max, source = 0, "unknown"
    for k, v in pairs(self.sources) do
        if v > max then max = v end --source = k end
    end

    if max > 0 then
        self.strength = max
        local next = GetTime() + math.pow((1 - self.strength), 2.7) * 10 + 0.25
        self.nextLeak = self.nextLeak > next and next or self.nextLeak
        --print("now strength is", max, "from", source)
    end
end

function BleedingOverlay:RemoveSource(source)
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
        self.strength = 0
    else
        self.strength = max
        local next = GetTime() + math.pow((1 - self.strength), 2.7) * 10 + 0.25
        self.nextLeak = self.nextLeak > next and next or self.nextLeak
        --print("now strength is", max, "from", source)
    end
end

function BleedingOverlay:KillLeak(leak)
    self.totalLeaks = self.totalLeaks - 1
end

local one = false

function BleedingOverlay:OnUpdate(dt)
    --if self.totalLeaks * 3 < (one and 1 or self.strength) and GetTime() > self.nextLeak then 
    if self.strength > 0 and GetTime() > self.nextLeak then 
        for k, v in pairs(self.leaks) do
            if v.free then 
                local coeff = self.strength
                local scale = coeff * 0.5 + 0.8
                local mult = math.random(30, 40) * 0.01

                v:InitLeak(scale, mult)

                self.totalLeaks = self.totalLeaks + 1
                --self.nextLeak = GetTime() + math.pow((1 - self.strength), 2.7) * 10 + 0.25 --+ math.max(0.25, 12 * math.pow(1 - self.strength, 3))
                self.nextLeak = GetTime() + easing.outCubic(self.strength, 10, -9.75, 1)

                --print("init leak", k, "next leak in", self.nextLeak - GetTime())

                break
            end
        end
    end

    local stop = true

    for k, leak in pairs(self.leaks) do
        if not leak.free then
            leak:PlayLeak(dt)
            stop = false
        end
    end

    if self.needtostop and stop then
        --print("all leaks are free, stop updating") 
        self:StopUpdating() 
    end
end


return BleedingOverlay