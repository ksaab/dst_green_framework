local function RefreshReticule(self, inst)
    local owner = ThePlayer
    if owner ~= nil then
        if owner.components.playercontroller ~= nil then
            owner.components.playercontroller:RefreshReticule()
        end
    end
end

local function OnDirty(inst)
    local self = inst.components.gfspellpointer
    if inst.replica.inventoryitem and inst.replica.inventoryitem:IsHeldBy(ThePlayer) then
        if self:IsEnabled() then
            self:StartTargeting()
        else
            self:StopTargeting()
        end
    end
end

local GFSpellPointer = Class(function(self, inst)
    self.inst = inst
    self.pointer = nil

    self._enabled = net_bool(inst.GUID, "GFSpellPointer._enabled", "gfspellpointerdirty")
    self._enabled:set(false)

    self.RefreshReticule = RefreshReticule

    inst:ListenForEvent("gfspellpointerdirty", OnDirty)
end)

function GFSpellPointer:OnRemoveFromEntity()
    self:SetEnabled(false)
end

function GFSpellPointer:IsEnabled()
    return self._enabled:value()
end

function GFSpellPointer:SetEnabled(enabled)
    if TheWorld.ismastersim then
        self._enabled:set(enabled)
    else
        self._enabled:set_local(enabled)
        if self._enabled:value() then
            self:StartTargeting()
        else
            self:StopTargeting()
        end
    end
end

function GFSpellPointer:SetPointer(pointer)
    self.pointer = pointer
end

function GFSpellPointer:StartTargeting()
    if self.pointer ~= nil and self.inst.components.reticule == nil then
        self.inst:AddComponent("reticule")
        for k, v in pairs(self.pointer) do
            self.inst.components.reticule[k] = v
        end
        self:RefreshReticule(self.inst)
    end
end

function GFSpellPointer:StopTargeting()
    if self.pointer ~= nil and self.inst.components.reticule ~= nil then
        self.inst:RemoveComponent("reticule")
        self:RefreshReticule(self.inst)
    end
end

return GFSpellPointer
