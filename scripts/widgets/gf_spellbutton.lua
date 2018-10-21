--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

local Button = require "widgets/button"
local Image = require "widgets/image"
local UIAnim = require "widgets/uianim"

local INVALID_TITLE = STRINGS.GF.HUD.INVALID_LINES.INVALID_TITLE
local INVALID_TEXT = STRINGS.GF.HUD.INVALID_LINES.INVALID_TEXT

local ALL_SPELLS = GFSpellList

local function OnClick(self)
    if self == nil then return end
    local spellName = self.spell

    if GFGetIsMasterSim() then	
        if self.owner.components.gfspellcaster then
            self.owner.components.gfspellcaster:HandleIconClick(spellName)
        end
    else
        if self.owner.replica.gfspellcaster then
            self.owner.replica.gfspellcaster:HandleIconClick(spellName)
        end
    end
end

local SpellButton = Class(Button, function(self, owner, sName)
	self.owner = owner
    Button._ctor(self, "SpellButton")
    
    --self:SetHAnchor(ANCHOR_LEFT)
    --self:SetVAnchor(ANCHOR_BOTTOM)

    self:Enable()
    self:Show()
    self:SetClickable(true)	

    self.background = self:AddChild(Image("images/gfspellhud.xml", "gf_spell_panel_icon.tex"))

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

    self:SetOnClick(function() OnClick(self) end)
end)

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

function SpellButton:__tostring()
    return string.format("button: %s", self.spell or "none")
end

return SpellButton