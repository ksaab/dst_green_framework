local GFDrinkable = Class(function(self, inst)
    self.inst = inst
    self.infinite = false
    self.onDrunkFn = nil
end)

function GFDrinkable:SetOnDrunkFn(fn)
    self.onDrunkFn = fn
end

function GFDrinkable:OnDrunk(drinker)
    --print("drinked")
    if self.onDrunkFn ~= nil then
        self:onDrunkFn(drinker)
    end

    --remove after drunk
    if not self.infinite then
        if self.inst.components.stackable ~= nil then
            self.inst.components.stackable:Get():Remove()
        else
            self.inst:Remove()
        end
    end

    self.inst:PushEvent("ondrunk", { drinker = drinker })
end

return GFDrinkable