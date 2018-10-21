--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

local GFDrinkable = Class(function(self, inst)
    self.inst = inst
    self.infinite = false
    self.onDrunkFn = nil
end)

function GFDrinkable:SetOnDrunkFn(fn)
    self.onDrunkFn = fn
end

function GFDrinkable:SetCheckFn(fn)
    self.checkDrunkFn = fn
end

function GFDrinkable:CheckBeforeDrunk(drinker)
    if drinker ~= nil and self.checkDrunkFn ~= nil then
        local c, r = self.checkDrunkFn(drinker, self.inst)
        return c, r
    end
    return true
end

function GFDrinkable:OnDrunk(drinker)
    --print("drinked")
    if self.onDrunkFn ~= nil then
        self.onDrunkFn(drinker, self.inst)
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