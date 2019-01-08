--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.
local ALL_EFFECTS = GF.GetStatusEffects()

local Widget = require "widgets/widget"
local Image = require "widgets/image"
local Text = require "widgets/text"

local INVALID_TITLE = STRINGS.GF.HUD.INVALID_LINES.INVALID_TITLE
local INVALID_TEXT = STRINGS.GF.HUD.INVALID_LINES.INVALID_TEXT
local MINUTES_LETTER = STRINGS.GF.HUD.MINUTES_LETTER

local defaultAtlas = "images/gfdefaulticons.xml"
local defaultImage = "defaultpositive.tex"

local PositiveCheck = function(eName) 
    return ALL_EFFECTS[eName] ~= nil and ALL_EFFECTS[eName].type == 1
end

local NegativeCheck = function(eName) 
    return ALL_EFFECTS[eName] ~= nil and ALL_EFFECTS[eName].type == 2
end

local function ConvertTimeToText(val)
    val = math.ceil(val)
    if val <= 0 then
        return ""
    elseif val >= 60 then
        val = val / 60
        return string.format("%i%s", val, MINUTES_LETTER)
    end

    return tostring(val)
end

local EffectsPanel = Class(Widget, function(self, owner)
	self.owner = owner
    Widget._ctor(self, "EffectsPanel")
    
    self.iconsXOffset = 65
    self.iconsYOffset = 0
    self.iconSize = 64

    self.icons = {}
    self.updateTick = 0
    self.count = 0

    self.checkfn = PositiveCheck

    self:SetScale(0.7)

    --update effects list
    self.inst:ListenForEvent( "gfEFUpdateIcon", function(owner, data) self:UpdateIcon(data) end, self.owner)
    self.inst:ListenForEvent( "gfEFRemoveIcon", function(owner, data) self:RemoveIcon(data) end, self.owner)

    print("EffectsPanel Panel was added to ", self.owner)
end)

function EffectsPanel:SetPanel(xPos, yPos, positive, iconsXOffset, iconsYOffset, iconSize)
    self:SetPosition(xPos or 0, yPos or 0)
    self.checkfn = positive == true and PositiveCheck or NegativeCheck
    self.iconsXOffset = iconsXOffset or 65
    self.iconsYOffset = iconsYOffset or 0
    self.iconSize = iconSize or 64
end

function EffectsPanel:UpdatePanel()
    local static = {}
    local nonstatic = {}

    for eName, icon in pairs(self.icons) do
        if icon ~= nil then
            if ALL_EFFECTS[eName].static then
                table.insert(static, eName)
            else
                table.insert(nonstatic, eName)
            end
        end
    end

    table.sort(static)
    table.sort(nonstatic)

    local i = 0
    for _, eName in pairs(static) do
        self.icons[eName]:SetPosition(self.iconsXOffset * i, self.iconsYOffset * i)
        i = i + 1
    end

    for _, eName in pairs(nonstatic) do
        self.icons[eName]:SetPosition(self.iconsXOffset * i, self.iconsYOffset * i)
        i = i + 1
    end

    if i == 0 then
        self:StopUpdating()
    else
        self:StartUpdating()
    end
end

function EffectsPanel:UpdateIcon(data)
    --print("update icon for", data.eName)
    if data == nil or data.eName == nil or not self.checkfn(data.eName) then return end

    local eName = data.eName
    local eInst = ALL_EFFECTS[eName]

    if not self.owner.replica.gfeffectable:HasEffect(eName) then return end
    local timer = self.owner.replica.gfeffectable:GetRemainTime(eName)

    if self.icons[eName] ~= nil then
        --if not eInst.static then
        --    print(eName, "icon updated")
        --    self.icons[eName].timer:SetString(ConvertTimeToText(timer))
        --end
    else
        --print(eName, "icon added")
        --base widget
        self.icons[eName] = self:AddChild(Image("images/gfspellhud.xml", "gf_spell_panel_icon.tex"))
        --icon
        if eInst.iconAtlas ~= nil and eInst.icon ~= nil then
            self.icons[eName].icon = self.icons[eName]:AddChild(Image(eInst.iconAtlas, eInst.icon))
        end
        --tooltip
        self.icons[eName]:SetTooltip(string.format("%s\n%s", 
            GetEffectString(eName, "title"), 
            GetEffectString(eName, "desc")
        ))
        --timer for non-static
        if not eInst.static then
            self.icons[eName].timer = self.icons[eName]:AddChild(Text(UIFONT, 35, ConvertTimeToText(timer)))
            self.icons[eName].timer:SetPosition(0, -5, 0)
        end

        self.count = self.count + 1
        self:UpdatePanel()
    end
end

function EffectsPanel:RemoveIcon(data)
    if data == nil or data.eName == nil then return end
    if self.icons[data.eName] ~= nil then
        --print(data.eName, "icon removed")
        self.icons[data.eName]:Kill()
        self.icons[data.eName] = nil
        self.count = self.count - 1
        self:UpdatePanel()
    end
end

function EffectsPanel:OnUpdate(dt)
    if self.updateTick > 1 then
        --print("tick")
        local replica = self.owner.replica.gfeffectable
        local currTime = GetTime()

        for eName, icon in pairs(self.icons) do
            if icon ~= nil then
                if replica:HasEffect(eName) and not ALL_EFFECTS[eName].static then
                    icon.timer:SetString(ConvertTimeToText(replica:GetRemainTime(eName)))
                else
                    self:RemoveIcon()
                end
            end
        end

        self.updateTick = 0
    else
        self.updateTick = self.updateTick + dt
    end
end


return EffectsPanel