local Widget = require "widgets/widget"
local Image = require "widgets/image"
local Text = require "widgets/text"

local invalidText = STRINGS.GF.INVALID_TITLE
local munitesLetter = STRINGS.GF.MINUTES_LETTER

local defaultAtlas = "images/gfdefaulticons.xml"
local defaultImage = "defaultnegative.tex"

local function ConvertTimeToText(val)
    if val >= 60 then
        val = val / 60
        return string.format("%i%s", val, munitesLetter)
    end

    return tostring(val)
end

local DebuffPanel = Class(Widget, function(self, owner)

	self.owner = owner
	Widget._ctor(self, "DebuffPanel")

    self.counter = 0
    self.debuffs = {}
    self.updateTick = 0

    self:SetScale(0.7)

    self:Update()
    self.inst:ListenForEvent( "gfupdateeffectshud", function() self:Update() end, self.owner)
    self.inst:ListenForEvent( "gfupdatedebuffpanelpos", function(owner, data) 
        if data and data.x  and data.y then
            self:SetPosition(-450 + data.x, 150 + data.y, 0) 
        end
    end, self.owner)

    print("Debuff Panel was added to ", self.owner)
end)

function DebuffPanel:Update()
    local posEffects = self.owner.replica.gfeffectable.hudInfo.negative
    local exists = {}

    for name, effect in pairs(posEffects) do
        exists[name] = true
        if self.debuffs[name] == nil then
            --icon
            self.debuffs[name] = self:AddChild(Image(effect.iconAtlas or defaultAtlas, effect.icon or defaultImage))
            --icon text
            self.debuffs[name]:SetTooltip(string.format("%s\n%s", 
                effect.titleText or invalidText, 
                effect.descText or invalidText
            ))
            --icon timer
            if not effect.static then
                local remainTime = math.ceil(effect.expirationTime - GetTime())
                remainTime = remainTime <= 0 and "" or ConvertTimeToText(remainTime)
                self.debuffs[name].timer = self.debuffs[name]:AddChild(Text(UIFONT, 45, remainTime))
                self.debuffs[name].timer:SetPosition(0, -5, 0)
            end
        end
    end

    for k, v in pairs(self.debuffs) do
        if not exists[k] then
            self.debuffs[k]:Kill()
            self.debuffs[k] = nil
        end
    end

    local counter = 0
    local all = {}
    for k, v in pairs(self.debuffs) do
        table.insert(all , k)
        v:SetPosition(-counter * 65, 0, 0)
        counter = 1 + counter
    end

    if counter > 0 then
        self:StartUpdating()
    else
        self:StopUpdating()
    end
end

function DebuffPanel:OnUpdate(dt)
    if self.updateTick > 1 and self.owner.replica.gfeffectable then
        self.updateTick = 0

        local posEffects = self.owner.replica.gfeffectable.hudInfo.negative
        local ctime = GetTime()

        for name, effect in pairs(posEffects) do
            if not effect.static then
                local remainTime = math.ceil(effect.expirationTime - GetTime())
                remainTime = remainTime <= 0 and "" or ConvertTimeToText(remainTime)
                self.debuffs[name].timer:SetString(remainTime)
            end
        end
    end

    self.updateTick = self.updateTick + dt
end


return DebuffPanel