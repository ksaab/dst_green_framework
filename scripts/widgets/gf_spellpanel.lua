--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

local Widget = require "widgets/widget"
local SpellButton = require "widgets/gf_spellbutton"
local Image = require "widgets/image"
local Text = require "widgets/text"
local SpellPanelBG = require "widgets/gf_spellpanel_bg"

local ALL_SPELLS = GF.GetSpells()

local SpellPanel = Class(Widget, function(self, owner)
	self.owner = owner
    Widget._ctor(self, "SpellPanel")

    self:SetPosition(-750, 170)
	self:MoveToBack()
	self:SetScale(0.9)

    self:Hide()

    self.body = self:AddChild(SpellPanelBG(owner))
    --self.body:SetHRegPoint(ANCHOR_LEFT)
    self.body.icons = {}

    self.owner:ListenForEvent("gfSCPanelAdd", function(owner, data) self:AddSpell(data) end, self.owner)
    self.owner:ListenForEvent("gfSCPanelRemove", function(owner, data) self:RemoveSpell(data) end, self.owner)
end)

function SpellPanel:AddSpell(data)
    if data == nil or data.sName == nil then return end

    self:Show()

    local size = 1
    local names = {}
    for sName, icon in pairs(self.body.icons) do
        size = size + 1
        table.insert(names, sName)
    end

    local sName = data.sName

    self.body:SetSize(size)
    self.body.icons[sName] = self.body:AddChild(SpellButton(self.owner, sName))

    table.insert(names, data.sName)
    table.sort(names)

    local i = 0
    for _, sName in pairs(names) do
        self.body.icons[sName]:SetPosition(78 * i + 36, -12, 0)
        i = i + 1
    end
end

function SpellPanel:RemoveSpell(data)
    if data == nil or data.sName == nil or self.body.icons[data.sName] == nil then return end

    local size = 0
    local names = {}
    for sName, icon in pairs(self.body.icons) do
        if sName ~= data.sName then
            size = size + 1
            table.insert(names, sName)
        end
    end

    self.body:SetSize(size)
    self.body.icons[data.sName]:Kill()
    self.body.icons[data.sName] = nil

    table.sort(names)

    local i = 0
    for _, sName in pairs(names) do
        self.body.icons[sName]:SetPosition(78 * i + 36, -12, 0)
        i = i + 1
    end

    if #names == 0 then self:Hide() end
end

function SpellPanel:GetIcons()
    return self.body.icons
end

return SpellPanel