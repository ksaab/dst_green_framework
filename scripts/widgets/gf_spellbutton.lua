--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

local Button = require "widgets/button"
local Image = require "widgets/image"
local UIAnim = require "widgets/uianim"
local Text = require "widgets/text"

local INVALID_TITLE = STRINGS.GF.HUD.INVALID_LINES.INVALID_TITLE
local INVALID_TEXT = STRINGS.GF.HUD.INVALID_LINES.INVALID_TEXT

local ALL_SPELLS = GF.GetSpells()

local function OnClick(self)
    if self == nil then return end
    local sName = self.spell

    if GFGetIsMasterSim() then	
        if self.owner.components.gfspellcaster then
            self.owner.components.gfspellcaster:HandleIconClick(sName)
        end
    else
        if self.owner.replica.gfspellcaster then
            self.owner.replica.gfspellcaster:HandleIconClick(sName)
        end
    end
end

local SpellButton = Class(Button, function(self, owner, panel, sName, num)
	self.owner = owner
    Button._ctor(self, "SpellButton")
    
    self._name = "spellbutton"
    self.num = num
    --self:SetHAnchor(ANCHOR_LEFT)
    --self:SetVAnchor(ANCHOR_BOTTOM)

    self:Enable()
    self:Show()
    self:SetClickable(true)	

    self.background = self:AddChild(Image("images/gfspellhud.xml", "gf_spell_panel_icon.tex"))
    self.panel = panel

    if sName then
        local sInst = ALL_SPELLS[sName]
        self.spell = sName
        if sInst.icon ~= nil and sInst.iconAtlas ~= nil then
            self.icon = self:AddChild(Image(sInst.iconAtlas, sInst.icon))
            --self.icon:SetScale(0.7)
        end

        self:SetTooltip(string.format("%s\n%s", 
            GetSpellString(sName, "title"), 
            GetSpellString(sName, "desc")
        ))
    end

    self.hint = self:AddChild(Text(TALKINGFONT, 32))
    self.hint:SetPosition(-24, 24)
    self.hint:Hide()

    --self:SetOnClick(function() OnClick(self) end)
    self:SetOnGainFocus(function() self:Highlight() end)
    self:SetOnLoseFocus(function() self:DeHighlight() end)
end)

function SpellButton:UpdatePosition(n)
    if self.num ~= n then
        self.num = n
        self:SetPosition(78 * (n - 1) + 36, -12, 0)
    end
end

function SpellButton:SetHint(val)
    if val then
        if self.num <= 4 then
            --print("show hint for", self)
            self.hint:Show()
            self.hint:MoveToFront()
            local controller_id = TheInput:GetControllerID()
            if      self.num == 1 then self.hint:SetString(TheInput:GetLocalizedControl(controller_id, CONTROL_INVENTORY_EXAMINE))
            elseif  self.num == 2 then self.hint:SetString(TheInput:GetLocalizedControl(controller_id, CONTROL_INVENTORY_USEONSELF))
            elseif  self.num == 3 then self.hint:SetString(TheInput:GetLocalizedControl(controller_id, CONTROL_INVENTORY_DROP))
            elseif  self.num == 4 then self.hint:SetString(TheInput:GetLocalizedControl(controller_id, CONTROL_INVENTORY_USEONSCENE))
            end
        else
            self.hint:SetString("")
        end
    else
        self.hint:SetString("")
        self.hint:Hide()
    end
end

function SpellButton:RechargeStarted()
    if self.rechargeframe == nil then
        self.rechargeframe = self:AddChild(UIAnim())
        self.rechargeframe:GetAnimState():SetBank("recharge_meter")
        self.rechargeframe:GetAnimState():SetBuild("recharge_meter")
        --self.rechargeframe:GetAnimState():PlayAnimation("frame")
        --self.rechargeframe:SetScale(0.7)
    end
end

function SpellButton:RechargeTick(percent)
    if self.rechargeframe ~= nil then
        self.rechargeframe:GetAnimState():SetPercent("recharge", percent)
    end
end

function SpellButton:RechargeDone()
    if self.rechargeframe ~= nil then
        self.rechargeframe:Kill()
        self.rechargeframe = nil
    end
end

function SpellButton:Highlight()
    self:SetScale(1.25, 1.25, 1.25)
    self.hovered = true
    if self.panel ~= nil then self.panel:SetHint(true) end
end

function SpellButton:DeHighlight()
    self:SetScale(1, 1, 1)
    self.hovered = false
    if self.panel ~= nil then self.panel:SetHint(false) end
end

function SpellButton:GetTextLines()
    return GetSpellString(self.spell, "TITLE"), GetSpellString(self.spell, "DESC")
end

function SpellButton:CastSpell()
    OnClick(self)
end

function SpellButton:OnMouseButton(button, down, x, y)
    if not self.focus or down then return false end

    if button == MOUSEBUTTON_LEFT then
        self:CastSpell()
    elseif button ==  MOUSEBUTTON_RIGHT and self.panel ~= nil then
        self.panel:SwapIcons(self.num)
        --[[ local pos = self:GetLocalPosition()
        print(pos.y, x)
        self.panel:SwapIcons(self.num, pos.y > x) ]]
    end
end

function SpellButton:__tostring()
    return string.format("button: %s", self.spell or "none")
end

return SpellButton