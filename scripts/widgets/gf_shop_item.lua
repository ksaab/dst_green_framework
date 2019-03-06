local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"
local TEMPLATES = require "widgets/redux/templates"

local function OnGainFocus(self)
    if self.bg ~= nil then
        self.bg:SetTint(0.5, 0.5, 0.5, 1)
    end
end

local function OnLoseFocus(self)
    if self.bg ~= nil then
        self.bg:SetTint(1, 1, 1, 1)
    end
end

local function OnClick(owner, itemID)
    print("buying", itemID)
    owner:PushEvent("gfShopButton", {event = 1, itemID = itemID})
end

local ShopItem = Class(Widget, function(self, owner)
    self.owner = owner
    Widget._ctor(self, "ShopItem")

    self.index = 0
    self.itemID = -1

    self.bg = self:AddChild(Image("images/gfquestjournal.xml", "gray_fill.tex"))
    self.bg:SetSize(64, 64)

    self.itemIcon = self:AddChild(Image())
    self.itemIcon:SetPosition(0, 0)

    self.item = self:AddChild(Text(UIFONT, 18, ""))
    self.item:SetHAlign(ANCHOR_LEFT)
    self.item:SetPosition(0, -10)
    self.item:SetRegionSize(60, 30)

    self.currencyIcon = self:AddChild(Image())
    self.currencyIcon:SetPosition(0, -20)

    self.price = self:AddChild(Text(UIFONT, 20, ""))
    self.price:SetHAlign(ANCHOR_RIGHT)
    self.price:SetPosition(60, 0)
    self.price:SetRegionSize(100, 20)

    self.buy = self:AddChild(TEMPLATES.StandardButton(function() 
            OnClick(self.owner, self.itemID)
        end, 
        "Buy", 
        {60, 30})
    )
    self.buy:SetPosition(180, 0)
    self.buy:Hide()

    self:SetOnGainFocus(function()
        if self.bg ~= nil then
            self.bg:SetTint(0.5, 0.5, 0.5, 1)
        end
    end)
    self:SetOnLoseFocus(function()
        if self.bg ~= nil then
            self.bg:SetTint(0, 0, 0, 1)
        end
    end)
end)

return ShopItem