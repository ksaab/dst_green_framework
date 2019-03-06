local CURRENCIES_LINKS = GF.CurrenciesLinks

local GFCurrency = Class(function(self, inst)
    self.inst = inst
    self.values = {}
end)

function GFCurrency:SetValue(type, value)
    if CURRENCIES_LINKS[type] ~= nil then
        self.values[CURRENCIES_LINKS[type].id] = value
    end
end

function GFCurrency:GetValue(type)
    return self.values[CURRENCIES_LINKS[type].id] or 0
end

return GFCurrency