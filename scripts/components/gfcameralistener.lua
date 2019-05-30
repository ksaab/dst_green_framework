local GFCameraListener = Class(function(self, inst)
    self.inst = inst
    self.target = nil
    self.positionfn = nil
    self.offset = nil --Vector3(0, 0, 0)

    self.removeOnTargetRemoved = false

    self._ontargetremoved = function()
        TheCamera:RemoveListener(self, self._oncameraupdate)
        self.inst:Remove()
    end

    self._oncameraupdate = function(dt) self:OnCameraUpdate(dt) end
end)

function GFCameraListener:GenerateSymbolPositionFn(offset, symbol)
    offset = offset or Vector3(0, 0, 0)

    return function(target, inst)
        local _, sy, _ = Vector3(target.entity:GetParent().AnimState:GetSymbolPosition())
        return offset + Vector3(0, sy, z)
    end
end

function GFCameraListener:SetOffset(x, y, z)
    self.offset = Vector3(x, y, z)
end

function GFCameraListener:SetPositionFn(fn)
    self.positionfn = fn
end 

function GFCameraListener:Bind(target, notRemove)
    self:Unbind()

    if target ~= nil and target:IsValid() then
        self.target = target
        TheCamera:AddListener(self, self._oncameraupdate)

        if notRemove ~= true then
            self.inst:ListenForEvent("onremove", self._ontargetremoved, target)
        end
    end
end

function GFCameraListener:Unbind()
    if self.target == nil then return end

    self.inst:RemoveEventCallback("onremove", self._ontargetremoved, self.target)
    TheCamera:RemoveListener(self, self._oncameraupdate)
    self.target = nil
end

function GFCameraListener:OnCameraUpdate(dt)
    if self.target == nil then return end

    if self.positionfn ~= nil then
        self.inst.Transform:SetPosition(self.positionfn(self.target, self.inst))
    elseif offset ~= nil then
        local pos = Vector3(self.target.Transform:GetWorldPosition())
        self.inst.Transform:SetPosition((pos + self.offset):Get())
    else
        self.inst.Transform:SetPosition(self.target.Transform:GetWorldPosition())
    end
end


return GFCameraListener