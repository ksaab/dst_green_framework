--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

local Widget = require "widgets/widget"
local Image = require "widgets/image"

local SpellPanelBG = Class(Widget, function(self, owner)
	self.owner = owner
    Widget._ctor(self, "SpellPanel")
    self.left = self:AddChild(Image("images/gfspellhud.xml", "gf_spell_panel_left.tex"))
    self.right = self:AddChild(Image("images/gfspellhud.xml", "gf_spell_panel_right.tex"))
    self.segmets = {}
end)

function SpellPanelBG:SetSize(size)
    self.right:SetPosition(78 * (size - 1) + 69, 0, 0)
    local currN = GetTableSize(self.segmets)
    if size > currN then
        for i = 1, size - 1 do
            if self.segmets[i] == nil then
                self.segmets[i] = self:AddChild(Image("images/gfspellhud.xml", "gf_spell_panel_element.tex"))
                self.segmets[i]:SetHRegPoint(ANCHOR_LEFT)
                self.segmets[i]:SetPosition(78 * (i - 1) + 35, 0, 0)
                self.segmets[i]:MoveToBack()
            end
        end
    elseif size < currN then
        for i = currN, size, -1 do
            if self.segmets[i] ~= nil then
                self.segmets[i]:Kill()
                self.segmets[i] = nil
            end
        end
    end
end


return SpellPanelBG