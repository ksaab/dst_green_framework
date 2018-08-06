--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

local Widget = require "widgets/widget"
local SpellButton = require "widgets/gf_spellbutton"
local Image = require "widgets/image"
local Text = require "widgets/text"

local function OnUpdateSpellList(self)
    local iconsPanel = self.iconsPanel
    iconsPanel:KillAllChildren()
    iconsPanel.icons = {}

    local gfsc = self.owner.replica.gfspellcaster
    if not gfsc then return end

    local count = 0

    for spellName, spell in pairs(gfsc.spells) do
        if not spell.passive then
            count = count + 1
            iconsPanel.icons[count] = iconsPanel:AddChild(SpellButton(self.owner, spell))
            --local btn = self.panel.icons[i]
            iconsPanel.icons[count]:SetPosition(70 + 78 * (count - 1), -12, 0)
        end
    end

    if count <= 0 then
        self:Hide()
    else
        self:Show()
        iconsPanel.right = iconsPanel:AddChild(Image("images/gfspellhud.xml", "gf_spell_panel_right.tex"))
        iconsPanel.right:SetHRegPoint(ANCHOR_LEFT)
        iconsPanel.right:SetPosition(78 * (count - 1) + 70, 0, 0)
        iconsPanel.right:MoveToBack()
        if count > 1 then
            iconsPanel.segments = {}
            for i = 1, count - 1 do
                iconsPanel.segments[i] = iconsPanel:AddChild(Image("images/gfspellhud.xml", "gf_spell_panel_element.tex"))
                iconsPanel.segments[i]:SetHRegPoint(ANCHOR_LEFT)
                iconsPanel.segments[i]:SetPosition(78 * (i - 1) + 70, 0, 0)
                iconsPanel.segments[i]:MoveToBack()
            end
        end
    end

    self.spellCount = count
    --self.owner:PushEvent("gfsc_updatespelllist")
    GFDebugPrint(("SpellPanel: Updated, num of skills = %i"):format(count))
end

local SpellPanel = Class(Widget, function(self, owner)
	self.owner = owner
    Widget._ctor(self, "SpellPanel")
    
    --self:SetHAnchor(ANCHOR_LEFT)
    --self:SetVAnchor(ANCHOR_BOTTOM)
    
    self:SetScale(0.55)
    --self:MoveToBack()
    

    --self:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self:SetPosition(-460, 85, 0)

    self.iconsPanel = self:AddChild(Image("images/gfspellhud.xml", "gf_spell_panel_left.tex"))
    self.iconsPanel:SetHRegPoint(ANCHOR_LEFT)
    self.iconsPanel.icons = {}
    --print(self.iconsPanel)

    self.spellCount = 0

    self.owner:ListenForEvent("gfsc_updatespelllist", function() OnUpdateSpellList(self) end, self.owner.classified)

    self:Hide()
    
    OnUpdateSpellList(self)
    owner:DoTaskInTime(3, function() OnUpdateSpellList(self) end)
end)

return SpellPanel