--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

------------------------------------------------------------
--INFO------------------------------------------------------
------------------------------------------------------------
--All methods are unsafe, do not use them directly
--Valid ways to work with nodes are implemented in
--the gfinterlocutor/gfshop component
------------------------------------------------------------

local ShopItem = Class(function(self)

end)

------------------------------------------------------------
--server only metods ---------------------------------------
------------------------------------------------------------

function ShopItem:Sell(buyer, trader, num)
    if type(self.onbuy) == "function" then return self:onbuy(buyer, trader, num) end

    num = num or 1
    for i = 1, num do
        local item = SpawnPrefab(self.onbuy or self.name)
        if item ~= nil then
            if item.components.inventoryitem ~= nil and buyer.components.inventory ~= nil then
                buyer.components.inventory:GiveItem(item)
            else
                item.Transform:SetPosition(buyer.Transform:GetWorldPosition())
            end
        end
    end
end

return ShopItem