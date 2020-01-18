local DEFAULT_TEXTURE = "fx/esquare.tex"
local DEFAULT_SHADER = "shaders/vfx_particle.ksh"

local defaultConfig = 
{
    --texture
    texture = "fx/smoke.tex",
    shader = "shaders/vfx_particle.ksh",
    frame = {x = 0.25, y = 1},
    --visual
    blendmode = BLENDMODE.Additive,
    bloom = true,
    maxParticles = 10,
    particlesPerSecond = 4,
    maxPerTick = math.huge,
    --behaviour
    follow = true,
    order = 0,
    orderOffset = 0,
    maxLifetime = 1,
    lifetimeFn = function() return 1 end,
    stopOnDeath = false,
    emitif = function() return true end,
    --envelope
    colourEnvelope = "gfdefaultcolourenvelope",
    scaleEnvelope = "gfdefaultscaleenvelope",
    --position
    positionFn = CreateSphereEmitter(0.2),
    velocityFn = function() return 0, 0.2, 0 end,
    yOffset = 0.1,
    acceleration = {0, 0, 0},
    drag = 0,
    inheritVelocity = false,
    --rotation
    rotation = false,
    angleFn = function() return UnitRand() * 180 end,
    angularVelocityFn = function() return UnitRand() * 0.5 end,
}

local cached = {}

local function Emit(effect, i, params, parentVelocity, parentRotation)
    local vx, vy, vz = params.velocityFn(parentVelocity, parentRotation)

    if (params.inheritVelocity and parentVelocity ~= nil) then
        vx, vy, vz = vx + parentVelocity[1] * 0.01, vy + parentVelocity[2] * 0.01, vz + parentVelocity[3] * 0.01
    end

    --print(vx, vy, vz)

    local px, py, pz = params.positionFn()
    if pz == nil then
        pz = py
        py = params.yOffset
    else
        py = py + params.yOffset
    end

    --print("emit", px, py, pz, vx, vy, vz)

    local uv_offset_x = params.frameSize[1] ~= 1 and math.random(0, params.frameSize[1] - 1) * params.frame[1] or 0
    local uv_offset_y = params.frameSize[2] ~= 1 and math.random(0, params.frameSize[2] - 1) * params.frame[2] or 0

    if params.rotation then
        effect:AddRotatingParticleUV(
            i,
            params.lifetimeFn(),       -- lifetime
            px, py, pz,                -- position
            vx, vy, vz,                -- velocity
            params.angleFn(),          -- angle
            params.angularVelocityFn(),-- angular_velocity
            uv_offset_x, uv_offset_y
        )
    else
        --print(uv_offset_x, uv_offset_y)

        effect:AddParticleUV(
            i,
            params.lifetimeFn(),	-- lifetime
            px, py, pz,			            -- position
            vx, vy, vz,			            -- velocity
            uv_offset_x, uv_offset_y		-- uv offset
        )
    end
end

local GFParticleEmitter = Class(function(self, inst)
    self.inst = inst
    if GFGetIsDedicatedNet() or inst.VFXEffect == nil then 
        self.Update = function() return false end
        return 
    end
    
    GF.InitParticleEmittersEnvelope()

    self.vfx = inst.VFXEffect
    self.params = {}
    self.parent = nil

    self.Update = function()
        --print("update")
        for i, v in pairs(self.params) do
            --print("need to emit", v.particlesToEmit)
            --local toemit = math.min(v.maxPerTick, v.particlesToEmit)
            local toemit = v.particlesToEmit
            local current = self.vfx:GetNumLiveParticles(i)

            if v.emitif(self.inst, self.parent) then
                local vfx = self.vfx

                local parentVelocity, parentRotation
                if (self.parent ~= nil) then
                    parentVelocity = (self.parent.Physics ~= nil) and {self.parent.Physics:GetVelocity()} or nil
                    parentRotation = (self.parent.Transform ~= nil) and self.parent.Transform:GetRotation() or nil
                end

                while v.particlesMax > current and toemit > 0 do
                    Emit(vfx, i, v, parentVelocity, parentRotation)
                    toemit = toemit - 1
                    current = current + 1
                end

                v.particlesToEmit = math.min(v.particlesMax, toemit + v.particlesPerTick)
                --print("now to emit", v.particlesToEmit)
            end
        end
    end
end)

function GFParticleEmitter:Config(...)
    if GFGetIsDedicatedNet() or self.vfx == nil then return end
    local effect = self.vfx

    effect:InitEmitters(arg.n)
    effect:SetRadius(0, 3)

    for i = 0, arg.n - 1 do
        local emitinfo = arg[i + 1]
        if cached[emitinfo] ~= nil then
            --print("reusing", cached[emitinfo])
            self.params[i] = cached[emitinfo]
        else
            self.params[i] = {}

            for property, value in pairs(defaultConfig) do
                if emitinfo[property] == nil then
                    --print("new value", value)
                    emitinfo[property] = value
                else
                    --print("old value", emitinfo[property])
                end
            end

            cached[emitinfo] = self.params[i]
            --print("caching", cached[emitinfo])
        end

        --print(PrintTable(emitinfo))

        local params = self.params[i]
        --texture
        effect:SetRenderResources(i, resolvefilepath(emitinfo["texture"]), resolvefilepath(emitinfo["shader"]))
        effect:SetUVFrameSize(i, emitinfo.frame.x, emitinfo.frame.y)
        params["frameSize"] = {1 / emitinfo.frame.x, 1 / emitinfo.frame.y}
        params["frame"] = {emitinfo.frame.x, emitinfo.frame.y}
        --visual
        effect:SetBlendMode(i, emitinfo.blendmode)
        effect:EnableBloomPass(i, emitinfo.bloom)
        effect:SetMaxNumParticles(i, emitinfo.maxParticles)
        params["particlesPerTick"] = emitinfo.particlesPerSecond * TheSim:GetTickTime()
        params["particlesToEmit"] = params["particlesPerTick"]
        params["particlesMax"] = emitinfo.maxParticles
        --params["maxPerTick"] = emitinfo.maxPerTick
        effect:SetDragCoefficient(0, emitinfo.drag)
        --behaviour
        effect:SetKillOnEntityDeath(i, emitinfo.stopOnDeath)
        effect:SetFollowEmitter(i, emitinfo.follow)
        effect:SetSortOrder(i, emitinfo.order)
        effect:SetSortOffset(i, emitinfo.orderOffset) --???
        effect:SetMaxLifetime(i, emitinfo.maxLifetime)
        params["lifetimeFn"] = emitinfo.lifetimeFn
        params["emitif"] = emitinfo.emitif
        --envelope
        effect:SetColourEnvelope(i, emitinfo.colourEnvelope)
        effect:SetScaleEnvelope(i, emitinfo.scaleEnvelope)
        --position
        effect:SetAcceleration(i, unpack(emitinfo.acceleration))
        params["positionFn"] = emitinfo.positionFn
        params["velocityFn"] = emitinfo.velocityFn
        params["yOffset"] = emitinfo.yOffset
        params["inheritVelocity"] = emitinfo.inheritVelocity
        --rotation
        effect:SetRotationStatus(i, emitinfo.rotation)
        params["rotation"] = emitinfo.rotation
        params["angleFn"] = emitinfo.angleFn
        params["angularVelocityFn"] = emitinfo.angularVelocityFn
    end
end

function GFParticleEmitter:Start()
    if GFGetIsDedicatedNet() or self.vfx == nil then return end
    EmitterManager:AddEmitter(self.inst, nil, self.Update)
end

function GFParticleEmitter:Stop()
    if GFGetIsDedicatedNet() or self.vfx == nil then return end
    EmitterManager:RemoveEmitter(self.inst)
end

function GFParticleEmitter:SetParent(ent)
    self.parent = ent
end

return GFParticleEmitter