local Widget = require "widgets/widget"
local Image = require "widgets/image"
local Text = require "widgets/text"

local invalidText = STRINGS.GF.INVALID_TITLE
local munitesLetter = STRINGS.GF.MINUTES_LETTER

local defaultAtlas = "images/gfdefaulticons.xml"
local defaultImage = "defaultpositive.tex"

local function ConvertTimeToText(val)
    if val >= 60 then
        val = val / 60
        return string.format("%i%s", val, munitesLetter)
    end

    return tostring(val)
end

local BuffPanel = Class(Widget, function(self, owner)

	self.owner = owner
	Widget._ctor(self, "BuffPanel")

    self.counter = 0
    self.buffs = {}
    self.updateTick = 0

    self:SetScale(0.7)

    self:Update()
    self.inst:ListenForEvent( "gfupdateeffectshud", function() self:Update() end, self.owner)
    self.inst:ListenForEvent( "gfupdatebuffpanelpos", function(owner, data) 
        if data and data.x  and data.y then
            self:SetPosition(-450 + data.x, 150 + data.y, 0) 
        end
    end, self.owner)

    print("Buff Panel was added to ", self.owner)
end)

function BuffPanel:Update()
    local posEffects = self.owner.replica.gfeffectable.hudInfo.positive
    local exists = {}

    for name, effect in pairs(posEffects) do
        exists[name] = true
        if self.buffs[name] == nil then
            --icon
            self.buffs[name] = self:AddChild(Image(effect.iconAtlas or defaultAtlas, effect.icon or defaultImage))
            --icon text
            self.buffs[name]:SetTooltip(string.format("%s\n%s", 
                effect.titleText or invalidText, 
                effect.descText or invalidText
            ))
            --icon timer
            if not effect.static then
                local remainTime = math.ceil(effect.expirationTime - GetTime())
                remainTime = remainTime <= 0 and "" or ConvertTimeToText(remainTime)
                self.buffs[name].timer = self.buffs[name]:AddChild(Text(UIFONT, 45, remainTime))
                self.buffs[name].timer:SetPosition(0, -5, 0)
            end
        end
    end

    for k, v in pairs(self.buffs) do
        if not exists[k] then
            self.buffs[k]:Kill()
            self.buffs[k] = nil
        end
    end

    local counter = 0
    local all = {}
    for k, v in pairs(self.buffs) do
        table.insert(all , k)
        v:SetPosition(counter * 65, 0, 0)
        counter = 1 + counter
    end

    if counter > 0 then
        self:StartUpdating()
    else
        self:StopUpdating()
    end
end

function BuffPanel:OnUpdate(dt)
    if self.updateTick > 1 and self.owner.replica.gfeffectable then
        self.updateTick = 0

        local posEffects = self.owner.replica.gfeffectable.hudInfo.positive
        local ctime = GetTime()

        for name, effect in pairs(posEffects) do
            if not effect.static then
                local remainTime = math.ceil(effect.expirationTime - GetTime())
                remainTime = remainTime <= 0 and "" or ConvertTimeToText(remainTime)
                self.buffs[name].timer:SetString(remainTime)
            end
        end
    end

    self.updateTick = self.updateTick + dt
end


return BuffPanel