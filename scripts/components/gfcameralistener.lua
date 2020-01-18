local listeners = 0

local GFCameraListener = Class(function(self, inst)
    self.inst = inst
    self.target = nil
    self.positionfn = nil
    self.offset = nil --Vector3(0, 0, 0)
    self.symbol = nil

    self.isFollower = false

    self._ontargetremoved = function()
        listeners = listeners - 1
        --print("total listeners", listeners)
        --print(self.inst, "removed - follow target has died")
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
    self.offset = y ~= nil and Vector3(x, y, z) or x
end

function GFCameraListener:SetPositionFn(fn)
    self.positionfn = fn
end 

function GFCameraListener:Bind(target, notRemove)
    if GFGetIsDedicatedNet() then return end

    self:Unbind()

    if target ~= nil and target:IsValid() then
        self.target = target
        TheCamera:AddListener(self, self._oncameraupdate)

        if notRemove ~= true then
            self.inst:ListenForEvent("onremove", self._ontargetremoved, target)
        end
    end

    listeners = listeners + 1
    --print("total listeners", listeners)
end

function GFCameraListener:BindAsFollower(target, symbol, offset)
    if GFGetIsDedicatedNet() then return end

    self:Unbind()
    if self.inst.Follower == nil then return end

    if target ~= nil and target:IsValid() then
        self.isFollower = true
        self.target = target
        self.symbol = symbol or "body"
        self.offset = offset or Vector3(0, 0, 0)
        --print("GUID", target.GUID, self.symbol, unpack(self.offset))
        self.inst.Follower:FollowSymbol(target.GUID, self.symbol, self.offset:Get())

        TheCamera:AddListener(self, self._oncameraupdate)
        self.inst:ListenForEvent("onremove", self._ontargetremoved, target)
    end

    listeners = listeners + 1
    --print("total listeners", listeners)
end

function GFCameraListener:Unbind()
    if self.target == nil then return end

    self.inst:RemoveEventCallback("onremove", self._ontargetremoved, self.target)
    TheCamera:RemoveListener(self, self._oncameraupdate)
    self.target = nil
    self.isFollower = false
end

function GFCameraListener:SetUpdate(val)
    self.update = val
end

function GFCameraListener:OnCameraUpdate(dt)
    if self.target == nil or not self.inst:IsValid() then return end

    if self.isFollower then
        if self.positionfn ~= nil then
            --print(self.positionfn(dt, self.target, self.inst))
            self.inst.Follower:FollowSymbol(self.target.GUID, self.symbol, self.positionfn(dt, self.target, self.inst))
        end
    else
        if self.positionfn ~= nil then
            self.inst.Transform:SetPosition(self.positionfn(dt, self.target, self.inst))
        elseif self.offset ~= nil then
            local pos = Vector3(self.target.Transform:GetWorldPosition())
            self.inst.Transform:SetPosition((pos + self.offset):Get())
        else
            self.inst.Transform:SetPosition(self.target.Transform:GetWorldPosition())
        end
    end
end

function GFCameraListener:OnEntitySleep()
    if self.target ~= nil then
        TheCamera:RemoveListener(self, self._oncameraupdate)
    end
end

function GFCameraListener:OnEntityWake()
    if self.target ~= nil and self.target:IsValid() then
        TheCamera:AddListener(self, self._oncameraupdate)
    end
end


return GFCameraListener