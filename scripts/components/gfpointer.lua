--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

local MIN_RSPEED = 0.25
local MAX_RSPEED = 1.25
local MIN_ASPEED = 2
local MAX_ASPEED = 5
local RSPEED_DELTA = 0.05
local ASPEED_DELTA = 0.25
local TWO_PI = PI * 2

local function DestroyPointer(self)
    local inst = self.pointer
    inst:DoPeriodicTask(0, function(inst, colour, scale, startTime)
        local dt = GetTime() - startTime
        local k = 1 - math.max(0, dt) / 0.3
        k = 1 - k * k
        local c = Lerp(1, 0, k)
        
        local sc = 1.5 + (1 - c) * 0.1
        inst.AnimState:SetScale(sc, sc, sc)
        inst.AnimState:SetMultColour(c * colour[1], c * colour[2], c * colour[3], c * colour[4])
    end, nil, self.validColour, 1.5, GetTime())
    inst:DoTaskInTime(0.3, inst.Remove)
end

local defaults = 
{
    pointerPrefab = "reticuleaoe",
    isArrow = false,
    needTarget = false,
    prefersTarget = true,
    range = 8,
    minRange = 0,
    maxRange = 8,
    validColour = { 204 / 255, 131 / 255, 57 / 255, .3 },
    invalidColour = { 1, 0, 0, .3 },
    noTargetColour = { 1, 0, 0, .3 },
}

local GFPointer = Class(function(self, inst)
    self.inst = inst
    self.map = TheWorld.Map
    self.pointer = nil
    self.pvpenabled = GFGetPVPEnabled()
    
    self.spell = nil
    self.targetPosition = nil
    self.targetEntity = nil
    self.positionValid = false
    self.prefersTarget = true

    self.angle = nil
    self.range = 8
    self.minRange = 0
    self.maxRange = 12
    
    self.needTarget = false
    self.isArrow = false 
    
    self.pointerPrefab = "reticuleaoe" --"gf_reticule_nature_triangle"
    self.validColour = { 204 / 255, 131 / 255, 57 / 255, .3 }
    self.invalidColour = { 1, 0, 0, .3 }
    self.noTargetColour = self.invalidColour

    self.smoothing = 6.66
    self.rangeSpeed = MIN_RSPEED
    self.angleSpeed = MIN_ASPEED

    self.targetfn = nil
    self.mousetargetfn = nil

    self._oncameraupdate = function(dt) self:OnCameraUpdate(dt) end
end)

function GFPointer:Create(spell)
    if self.pointer ~= nil then
        self.pointer:Remove()
        self.pointer = nil
    end

    self.spell = spell
    self.rangeSpeed = MIN_RSPEED
    self.angleSpeed = MIN_ASPEED

    local pointer = spell.pointer
    --reset the pointer
    for k, v in pairs(defaults) do
        self[k] = v
    end
    if pointer ~= nil then
        for k, v in pairs(pointer) do
            self[k] = pointer[k] or v
        end
    end

    --I hope somewhere I figure out why this code always makes prefersTarget = true
    --[[if pointer ~= nil then
        for k, v in pairs(defaults) do
            print("set", k, "as", pointer[k] or v)
            self[k] = pointer[k] or v
        end
    else
        for k, v in pairs(defaults) do
            self[k] = v
        end
    end]]

    if TheInput:ControllerAttached() then
        --get a point in frontt of the layer
        local ang = self.inst.Transform:GetRotation()
        local x, _, z = self.inst.Transform:GetWorldPosition()

        self.angle = ang
        ang = ang * DEGREES
        self.targetPosition = Vector3(x + math.cos(ang) * self.range, 0, z - math.sin(ang) * self.range)
    else
        --get a point under the cursor
        local x, _, z = self.inst.Transform:GetWorldPosition()
        local pt = TheInput:GetWorldPosition()

        self.targetPosition = pt
        self.angle = 0--math.atan2(pt.x - x, pt.z - z)
    end

    TheCamera:AddListener(self, self._oncameraupdate)
    self.inst:StartUpdatingComponent(self)

    self.pointer = SpawnPrefab(self.pointerPrefab)
    if self.pointer ~= nil then
        self.pointer.Transform:SetPosition(self.targetPosition:Get())
        if self.isArrow then 
            self.pointer.Transform:SetRotation(self.angle) 
        end
        self.pointer.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    end
end

function GFPointer:Destroy()
    if self.pointer ~= nil then
        --print("removing a pointer", self.pointer)
        DestroyPointer(self)
        --self.pointer:Remove()
        self.pointer = nil
    end
    self.targetPosition = nil
    self.targetEntity = nil
    --self.inst:StopUpdatingComponent(self)
    TheCamera:RemoveListener(self, self._oncameraupdate)
    self.inst:StopUpdatingComponent(self)
end

function GFPointer:ForceDestroy()
    if self.pointer ~= nil then
        self.pointer:Remove()
        self.pointer = nil
    end
    self.targetPosition = nil
    self.targetEntity = nil
    --self.inst:StopUpdatingComponent(self)
    TheCamera:RemoveListener(self, self._oncameraupdate)
end

function GFPointer:UpdateColour()
    if self.positionValid then
        local colour = (self.needTarget and not self.targetEntity) and self.noTargetColour or self.validColour 
        self.pointer.AnimState:SetMultColour(colour[1], colour[2], colour[3], colour[4])
    else
        local colour = self.invalidColour
        self.pointer.AnimState:SetMultColour(colour[1], colour[2], colour[3], colour[4])
    end
end

function GFPointer:UpdatePosition(dt)
    local playerPos = Vector3(self.inst.Transform:GetWorldPosition())
    local cursorPos = self.targetPosition or playerPos
    
    if TheInput:ControllerAttached() then
        --controller
        if self.isArrow then
            local targRot = self.angle
            local currRot = self.pointer.Transform:GetRotation()
            local deltaRot = targRot - currRot
            targRot = Lerp((deltaRot > 180 and currRot + 360) 
                    or (deltaRot < -180 and currRot - 360) 
                    or currRot, 
                    targRot, dt * self.smoothing)
            self.pointer.Transform:SetPosition(playerPos:Get())
            self.pointer.Transform:SetRotation(targRot)
        else
            local xp, yp, zp = self.pointer.Transform:GetWorldPosition()
            local xn, yn, zn 
            if self.targetEntity ~= nil then
                xn, yn, zn = self.targetEntity.Transform:GetWorldPosition()
            else
                xn, yn, zn = cursorPos:Get()
            end
            self.pointer.Transform:SetPosition(Lerp(xp, xn, dt * self.smoothing), yp, Lerp(zp, zn, dt * self.smoothing))
        end
    else
        --mouse
        if self.isArrow then
            local rotation = (math.atan2(cursorPos.x - playerPos.x, cursorPos.z - playerPos.z) - 1.5708) / DEGREES
            self.pointer.Transform:SetPosition(playerPos:Get())
            self.pointer.Transform:SetRotation(rotation)
        else
            local x, y, z
            if self.targetEntity ~= nil then
                x, y, z = self.targetEntity.Transform:GetWorldPosition()
            else
                x, y, z = cursorPos:Get()
            end
            self.pointer.Transform:SetPosition(x, y, z)
        end
    end
end

function GFPointer:RecalculateTarget()
    local playerPos = Vector3(self.inst.Transform:GetWorldPosition())
    local cursorPos, cursorEntity
    self.targetEntity = nil

    if TheInput:ControllerAttached() then
        --controller
        local ang = self.angle * DEGREES
        local x, y, z = playerPos:Get()
        local pos
        local cos, sin = math.cos(ang), math.sin(ang)

        --find a valid position
        for i = self.range, 0, -1 do
            pos = Vector3(x + cos * i, 0, z - sin * i)
            if self.map:IsPassableAtPoint(pos:Get()) and not self.map:IsGroundTargetBlocked(pos) then
                break
            end
        end

        cursorPos = pos

        if self.prefersTarget or self.spell.needTarget then
            local combat = {}
            local nonCombat = {}
            for _, ent in pairs(TheSim:FindEntities(cursorPos.x, 0, cursorPos.z, 3, nil, {"FX", "NOCLICK", "shadow"})) do
                if ent.entity:IsVisible() and CanEntitySeeTarget(self.inst, ent) and self.spell:CheckTarget(self.inst, ent) then
                    table.insert((ent.components.combat) ~= nil and combat or nonCombat, ent)
                end
            end

            cursorEntity = combat[1] or nonCombat[1]
        end
    else
        --mouse
        cursorPos = TheInput:GetWorldPosition()
        if self.prefersTarget or self.spell.needTarget then
            local ent = TheInput:GetWorldEntityUnderMouse()
            if ent ~= nil and ent:IsValid() and self.spell:CheckTarget(self.inst, ent) then
                cursorEntity = ent
                cursorPos = Vector3(cursorEntity.Transform:GetWorldPosition())
            end
        end
    end

    self.targetEntity = cursorEntity
    self.targetPosition = cursorPos or playerPos
    self.positionValid = self.map:IsPassableAtPoint(cursorPos:Get()) and not self.map:IsGroundTargetBlocked(cursorPos)
end

function GFPointer:OnCameraUpdate(dt)
    self:RecalculateTarget()
    if self.pointer ~= nil then 
        self:UpdatePosition(dt)
        self:UpdateColour()
    end
end

function GFPointer:OnUpdate(dt)
    if not TheInput:ControllerAttached()
        or (self.inst.HUD ~= nil 
            and (self.inst.HUD:IsInConversation() or self.inst.HUD:IsSpellSelectionEnabled())) 
    then 
        return 
    end

    local reduce_a = self.angleSpeed > MIN_ASPEED
    local reduce_r = self.rangeSpeed > MIN_RSPEED

    if TheInput:IsControlPressed(CONTROL_INVENTORY_LEFT) then
        local angle = self.angle + self.angleSpeed
        self.angle = angle - 360 * math.floor((angle + 180) / 360) --normalize the angle between pi and -pi
        self.angleSpeed = math.min(MAX_ASPEED, self.angleSpeed + ASPEED_DELTA)
        reduce_a = false
    elseif TheInput:IsControlPressed(CONTROL_INVENTORY_RIGHT) then
        local angle = self.angle - self.angleSpeed
        self.angle = angle - 360 * math.floor((angle + 180) / 360) --normalize the angle between pi and -pi
        self.angleSpeed = math.min(MAX_ASPEED, self.angleSpeed + ASPEED_DELTA)
        reduce_a = false
    end
    if TheInput:IsControlPressed(CONTROL_INVENTORY_UP) then
        self.range = math.min(self.maxRange, self.range + 0.25)
        self.rangeSpeed = math.min(MAX_RSPEED, self.rangeSpeed + RSPEED_DELTA)
        reduce_r = false
    elseif TheInput:IsControlPressed(CONTROL_INVENTORY_DOWN) then
        self.range = math.max(self.minRange, self.range - 0.25)
        self.rangeSpeed = math.min(MAX_RSPEED, self.rangeSpeed + RSPEED_DELTA)
        reduce_r = false
    end

    if reduce_a then self.angleSpeed = math.min(MIN_ASPEED, self.angleSpeed - ASPEED_DELTA) end
    if reduce_r then self.rangeSpeed = math.min(MIN_RSPEED, self.rangeSpeed - RSPEED_DELTA) end
end

GFPointer.OnRemoveFromEntity = GFPointer.ForceDestroy
GFPointer.OnRemoveEntity = GFPointer.ForceDestroy

return GFPointer
