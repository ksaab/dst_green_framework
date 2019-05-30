local acid_cloud_emitter = 
{
    --texture
    texture = "fx/fxskull.tex",
    shader = "shaders/vfx_particle.ksh",
    frame = {x = 1, y = 1},
    --visual
    blendmode = _G.BLENDMODE.Additive,
    bloom = true,
    maxParticles = 40,
    particlesPerSecond = 15,
    --behaviour
    follow = true,
    order = 0,
    maxLifetime = 1.5,
    lifetimeFn = function() return 1.5 end,
    --envelope
    colourEnvelope = "gwdndparticleemittercolour",
    scaleEnvelope = "gwdndparticleemitterscale",
    --position
    positionFn = _G.CreateDiscEmitter(3.5),
    velocityFn = function() return 0, 0, 0 end,
    yOffset = 0.1,
    acceleration = {0, -0.02, 0},
    --rotation
    rotation = true,
    angleFn = function() return _G.UnitRand() * 180 end,
    angularVelocityFn = function() return _G.UnitRand() * 0.5 end,
}

local acid_cloud_emitter2 = 
{
    --texture
    texture = "fx/fxskull.tex",
    shader = "shaders/vfx_particle.ksh",
    frame = {x = 1, y = 1},
    --visual
    blendmode = _G.BLENDMODE.Additive,
    bloom = true,
    maxParticles = 80,
    particlesPerSecond = 25,
    --behaviour
    follow = true,
    order = 0,
    maxLifetime = 1,
    lifetimeFn = function() return 1 end,
    --envelope
    colourEnvelope = "gfgreencolourenvelope",
    scaleEnvelope = "gfdefaultscaleenvelope",
    --position
    positionFn = _G.CreateDiscEmitter(4),
    velocityFn = function() return 0, 0, 0 end,
    yOffset = 0.1,
    acceleration = {0, 0.03, 0},
    --rotation
    rotation = true,
    angleFn = function() return _G.UnitRand() * 180 end,
    angularVelocityFn = function() return _G.UnitRand() * 0.5 end,
}

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddVFXEffect()

    inst:AddTag("FX")

    inst:AddComponent("gfparticleemitter")
    inst.components.gfparticleemitter:Config({})

    return inst
end

return Prefab("gf_emitter_component", fn)