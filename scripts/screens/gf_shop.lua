local Screen = require "widgets/screen"
local Text = require "widgets/text"
local Widget = require "widgets/widget"
local Image = require "widgets/image"
local TEMPLATES = require "widgets/redux/templates"
local ImageButton = require "widgets/imagebutton"
local NineSlice = require "widgets/nineslice"
local ShopItem = require "widgets/gf_shop_item"

local CURRENCIES = GF.Currencies
local SHOP_ITEMS = GF.ShopItems
local CURRENCIES_LINKS = GF.CurrenciesLinks
local SHOP_ITEMS_LINKS = GF.ShopItemsLinks

local INVALID_TITLE = STRINGS.GF.HUD.INVALID_LINES.INVALID_TITLE
local INVALID_TEXT = STRINGS.GF.HUD.INVALID_LINES.INVALID_TEXT

local ShopScreen = Class(Screen, function(self, owner, list)
    print("owner, list", owner, list)
    Screen._ctor(self, "ShopScreen")
    self.owner = owner

    self.root = self:AddChild(Widget("ROOT"))
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetPosition(0, 0)
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)

    self.window = self.root:AddChild(NineSlice("images/dialogcurly_9slice.xml"))
    local window = self.window

    local crown
    crown = window:AddCrown("crown-top-fg.tex", ANCHOR_MIDDLE, ANCHOR_TOP, 0, 68)
    crown = window:AddCrown("crown-top.tex", ANCHOR_MIDDLE, ANCHOR_TOP, 0, 44)
    crown:MoveToBack()
    crown = window:AddCrown("crown-bottom-fg.tex", ANCHOR_MIDDLE, ANCHOR_BOTTOM, 0, -14)
    crown:MoveToFront()

    window:SetSize(600, 400)
    window:SetScale(0.7, 0.7)

    window.title = window:AddChild(Text(HEADERFONT, 40, "Shop", UICOLOURS.GOLD_SELECTED))
    window.title:SetPosition(0, 225)
    window.title:SetRegionSize(300, 50)
    window.title:SetHAlign(ANCHOR_MIDDLE)

    window.topline = window:AddChild(Image("images/gfquestjournal.xml", "edgetop.tex"))
    window.topline:SetPosition(0, 175)

    window.bottomline = window:AddChild(Image("images/gfquestjournal.xml", "edgebottom.tex"))
    window.bottomline:SetPosition(0, -175)

    self.closeButton = self.root:AddChild(TEMPLATES.StandardButton(function() 
            self.owner:PushEvent("gfShopButton", {event = 0}) 
            self:Close() 
        end, 
        STRINGS.GF.HUD.JOURNAL.BUTTONS.CLOSE, 
        {180, 60})
    )
    self.closeButton:SetPosition(0, -250)

    local function RowConstructor(context, index)
        local widget = ShopItem(owner)
        return widget
    end

    local function ApplyFn(context, widget, data, index) 
        widget.index = index
        if data then 
            local item = SHOP_ITEMS[data.id]
            --print(SHOP_ITEMS[data.id].name)
            print("id:", data.id)
            --print(PrintTable(data.id))
            if item ~= nil then
                local currency = (data.currency ~= nil) and CURRENCIES_LINKS[data.currency] or CURRENCIES_LINKS[item.currency]
                if currency ~= nil then
                    widget.itemID = data.id
                    widget.item:SetString(item.dispname)
                    widget.price:SetString(data.price or item.price)
                    widget.currencyIcon:SetTexture(currency.atlas, currency.image)
                    widget.currencyIcon:SetSize(24, 24)
                    widget.itemIcon:SetTexture(item.atlas, item.image)
                    widget.itemIcon:SetSize(24, 24)
                    widget.buy:Show()
                else
                    widget.item:SetString("Error! Can't get currency data!")
                end
            else
                widget.item:SetString("Error! Can't get item data!")
            end
        end
    end

    local opts = 
    {
        context = {},
        widget_width  = 460,
        widget_height = 30,
        num_visible_rows = 10,
        num_columns = 1,
        item_ctor_fn = RowConstructor,
        apply_fn = ApplyFn,
        scrollbar_offset = 25,
        scrollbar_height_offset = -75,
    }

    if list ~= nil then
        self.scroll = self.window:AddChild(TEMPLATES.ScrollingGrid(list, opts))
    end
end)

function ShopScreen:Close()
    TheFrontEnd:PopScreen(self)
end

return ShopScreen