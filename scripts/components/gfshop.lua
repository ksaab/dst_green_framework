local CURRENCIES = GF.Currencies
local SHOP_ITEMS = GF.ShopItems
local CURRENCIES_LINKS = GF.CurrenciesLinks
local SHOP_ITEMS_LINKS = GF.ShopItemsLinks

local GFShop = Class(function(self, inst)
    self.inst = inst
    self.items = {}
end)

function GFShop:AddItem(name, count, currency, price)
    if SHOP_ITEMS_LINKS[name] ~= nil and (currency == nil or CURRENCIES_LINKS[currency] ~= nil) then
        local item = 
        {
            isInf = type(count) ~= "number",
            count = count,
            currency = (currency ~= nil and CURRENCIES_LINKS[currency] ~= nil) and CURRENCIES_LINKS[currency].id or CURRENCIES_LINKS["gold"].id,
            price = price or 1,
        }
        self.items[SHOP_ITEMS_LINKS[name].id] = item
    end
end

function GFShop:RemoveItem(name)
    if SHOP_ITEMS_LINKS[name] ~= nil then
        self.items[SHOP_ITEMS_LINKS[name].id] = nil
    end
end

function GFShop:SetItemList(list)
    self.items = {}
    for k, item in pairs(list) do
        self:AddItem(item.name, item.count, item.currency, item.price)
    end
end

function GFShop:SellItems(buyer, id, num)
    local item = self.items[id]
    if item == nil then return false end

    num = math.min((num or 1), (item.count or 1))
    local curr = CURRENCIES[item.currency]

    if curr:Consume(buyer, item.price * num) then
        if not item.isInf then
            item.count = item.count - num
        end

        SHOP_ITEMS[id]:Sell(buyer, self.inst, num)
        print(buyer, "successfully bought", curr.name)
    else
        print(buyer, "can't to spend enough currency", curr.name)
    end
end

function GFShop:GetList()
    return self.items
end

function GFShop:GetListLine()
    local str = {}
    for id, item in pairs(self.items) do
        table.insert(str, string.format("%i;%i;%i", id, item.currency, item.price))
    end

    return table.concat(str, "^")
end

function GFShop:GetDebugString()
    local inst = self.inst
    local str = {}
    for k, item in pairs(self.items) do
        table.insert(str, ("[%s(%i) - %s %i]"):format(SHOP_ITEMS[k].name, k, CURRENCIES[item.currency].name, item.price))
    end

    return table.concat(str, ", ")
end

return GFShop