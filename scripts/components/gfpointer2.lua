--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

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

    self.range = 8
    self.maxRange = 8
    
    self.needTarget = false
    self.isArrow = false 
    
    self.pointerPrefab = "reticuleaoe" --"gf_reticule_nature_triangle"
    self.validColour = { 204 / 255, 131 / 255, 57 / 255, .3 }
    self.invalidColour = { 1, 0, 0, .3 }
    self.noTargetColour = self.invalidColour

    self.smoothing = 6.66

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

    local pointer = spell.pointer
    if pointer ~= nil then
        --reset
        for k, v in pairs(defaults) do
            self[k] = v
        end
        for k, v in pairs(pointer) do
            self[k] = v
        end
    end

    self.pointer = SpawnPrefab(self.pointerPrefab)
    --print("creating a pointer", self.pointer)
    TheCamera:AddListener(self, self._oncameraupdate)

    if self.pointer == nil then
        return
    end

    self.pointer.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
    if self.isArrow then
        self.pointer.Transform:SetRotation(self.inst.Transform:GetRotation())
    end
    self.pointer.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    --self:UpdatePosition(0)
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
    local cursorPos = self.targetPosition
    if TheInput:ControllerAttached() then
        --controller pointer position start
        if self.isArrow then
            if cursorPos ~= nil and playerPos ~= nil then 
                local targRot = self.inst.Transform:GetRotation()
                local currRot = self.pointer.Transform:GetRotation()
                local deltaRot = targRot - currRot
                targRot = Lerp((deltaRot > 180 and currRot + 360) 
                        or (deltaRot < -180 and currRot - 360) 
                        or currRot, 
                        targRot, dt * self.smoothing)

                self.pointer.Transform:SetPosition(playerPos:Get())
                self.pointer.Transform:SetRotation(targRot)
            end
        else
            if cursorPos ~= nil then
                local x, y, z = self.pointer.Transform:GetWorldPosition()
                local x, z = Lerp(x, cursorPos.x, dt * self.smoothing), Lerp(z, cursorPos.z, dt * self.smoothing)
                self.pointer.Transform:SetPosition(x, y, z)
            end
        end
        --controller pointer position end
    else
        --mouse pointer position start
        if self.isArrow then
            if cursorPos ~= nil and playerPos ~= nil then 
                local rotation = (math.atan2(cursorPos.x - playerPos.x, cursorPos.z - playerPos.z) - 1.5708) / DEGREES
                self.pointer.Transform:SetPosition(playerPos:Get())
                self.pointer.Transform:SetRotation(rotation)
            end
        else
            if cursorPos ~= nil then
                self.pointer.Transform:SetPosition(cursorPos:Get())
            end
        end
        --mouse pointer position end
    end
end

function GFPointer:RecalculateTarget()
    local playerPos = Vector3(self.inst.Transform:GetWorldPosition())
    local cursorPos, cursorEntity
    self.targetEntity = nil

    if TheInput:ControllerAttached() then
        --controller
        if self.angle == nil then
            self.angle = self.inst.Transform:GetRotation() * DEGREES
        end
        local playerRot = self.angle --self.inst.Transform:GetRotation() * DEGREES
        local range = math.min(self.range, self.maxRange)
        local pos = Vector3()
        
        cursorPos = playerPos
        for i = range, 0, -1 do
            pos.x, pos.y, pos.z = self.inst.entity:LocalToWorldSpace(i, 0, 0)
            if self.map:IsPassableAtPoint(pos:Get()) and not self.map:IsGroundTargetBlocked(pos) then
                cursorPos = pos
                break
            end
        end
        if self.prefersTarget then
            local atan2 = math.atan2
            local pi2 = 2 * PI
            local rotation = math.atan2(cursorPos.x - playerPos.x, cursorPos.z - playerPos.z)
            local combat = {}
            local nonCombat = {}
            local min, max = rotation - 1.05, rotation + 1.05
            
            local ents = TheSim:FindEntities(playerPos.x, 0, playerPos.z, range, nil, {"FX", "NOCLICK", "shadow"})

            for i, ent in pairs(ents) do
                if ent ~= self.inst and ent.entity:IsVisible() and CanEntitySeeTarget(self.inst, ent) and self.spell:CheckTarget(self.inst, ent) then
                    local x, y, z = ent.Transform:GetWorldPosition()
                    local entRot = math.atan2(x - playerPos.x, z - playerPos.z)
                    if entRot > min and entRot < max then
                        if ent.components.combat then
                            table.insert(combat, ent)
                        else
                            table.insert(nonCombat, ent)
                        end
                    end
                end
            end

            if #combat > 0 then
                cursorEntity = combat[1]
            elseif #nonCombat > 0 then
                cursorEntity = nonCombat[1]
            end

            if cursorEntity then
                cursorPos = Vector3(cursorEntity.Transform:GetWorldPosition())
            end

            --[[ for i, v in pairs(ents) do
                if v ~= self.inst and v.entity:IsVisible() and CanEntitySeeTarget(self.inst, v) then
                    if v.components.combat then
                        cursorEntity = v
                        cursorPos = Vector3(cursorEntity.Transform:GetWorldPosition())
                        break
                    end
                    table.insert(nonCombat, v)
                end
            end ]]
            --[[ local ents = TheSim:FindEntities(cursorPos.x, 0, cursorPos.z, 3, nil, {"FX", "NOCLICK", "shadow"})
            local nonCombat = {}
            
            for i, v in pairs(ents) do
                if v ~= self.inst and v.entity:IsVisible() and CanEntitySeeTarget(self.inst, v) then
                    if v.components.combat then
                        cursorEntity = v
                        cursorPos = Vector3(cursorEntity.Transform:GetWorldPosition())
                        break
                    end
                    table.insert(nonCombat, v)
                end
            end

            if cursorEntity == nil and #nonCombat > 0 then
                cursorEntity = nonCombat[1]
                cursorPos = Vector3(cursorEntity.Transform:GetWorldPosition())
            end ]]
        end
    else
        --mouse
        cursorPos = TheInput:GetWorldPosition()
        if self.prefersTarget then
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

GFPointer.OnRemoveFromEntity = GFPointer.ForceDestroy
GFPointer.OnRemoveEntity = GFPointer.ForceDestroy

return GFPointer
