--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

------------------------------------------------------------
--INFO------------------------------------------------------
------------------------------------------------------------
--All methods are unsafe, do not use them directly
--Valid ways to work with nodes are implemented in
--the gfinterlocutor/gfshop component
------------------------------------------------------------

local Currency = Class(function(self)
    self.checkItemsFn = function(item)
        print("self id", self.id)
        return item.components.gfcurrency and item.components.gfcurrency.values[self.id]
    end
end)

------------------------------------------------------------
--server only metods ---------------------------------------
------------------------------------------------------------

function Currency:GetValue(buyer)
    if self.getValueFn ~= nil then return self:getValueFn(buyer) end

    local total = 0
    if buyer.components.inventory ~= nil then
        local items = buyer.components.inventory:FindItems(self.checkItemsFn)
        for k, item in pairs(items) do
            total = item.components.stackable ~= nil
                and total + item.components.gfcurrency.values[self.id] * item.components.stackable:StackSize()
                or total + item.components.gfcurrency.values[self.id]
        end
    end

    return total
end

function Currency:Consume(buyer, value)
    if self.consumeFn ~= nil then return self:consumeFn(buyer, value) end

    local remove = {}
    if buyer.components.inventory ~= nil then
        local items = buyer.components.inventory:FindItems(self.checkItemsFn)
        local i = 1
        while value > 0 and items[i] ~= nil do
            print(value)
            local item = items[i]
            if item.components.stackable ~= nil then
                value = value - item.components.gfcurrency.values[self.id] * item.components.stackable:StackSize()
                remove[item] = value > 0 and 0 or math.ceil(value / item.components.gfcurrency.values[self.id])
            else
                value = value - item.components.gfcurrency.values[self.id]
                remove[item] = 0
            end

            i = i + 1
        end

        if value <= 0 then
            for item, num in pairs(remove) do
                if num ~= 0 then
                    item.components.stackable:Get(num):Remove()
                else
                    local r = buyer.components.inventory:RemoveItem(item, true)
                    if r ~= nil then
                        r:Remove()
                    end
                end
                
            end
            return true
        end
    end

    return false
end


return Currency