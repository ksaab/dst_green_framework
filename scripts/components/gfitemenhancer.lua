--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

local function check()
    return false
end 

local GFItemEnhancer = Class(function(self, inst)
    self.inst = inst
    self.checkfn = check
    self.enchancefn = nil

    self.removeOnUse = false
    self.decayPerUse = 1
end)

function GFItemEnhancer:CheckItem(item)
    return self.checkfn(item, self.inst)
end

function GFItemEnhancer:EnhanceItem(item)
    if self.enchancefn then
        return self.enchancefn(item, self.inst)
    end

    return false
end

function GFItemEnhancer:OnEnhanceDone()
    local inst = self.inst
    if self.removeOnUse then
        if inst.components.stackable then
            inst.components.stackable:Get():Remove()
        else
            inst:Remove()
        end
        return
    elseif inst.components.finiteuses and self.decayPerUse > 0 then
        inst.components.finiteuses:Use(self.decayPerUse or 1)
    end
end

return GFItemEnhancer