local function StartFollowFX(inst)
    inst.AnimState:PlayAnimation(inst.applyAnim)
    inst.AnimState:PushAnimation(inst.loopAnim, true)
    if inst.sound then
        inst.SoundEmitter:PlaySound(inst.sound) 
    end
end

local function StopFollowFX(inst)
    inst.AnimState:PlayAnimation(inst.removeAnim)
    inst:ListenForEvent("animover", inst.Remove)
end

local function ApplyFX(inst)
    inst.AnimState:PlayAnimation(inst.applyAnim)
    inst.AnimState:PushAnimation(inst.removeAnim, false)
    if inst.sound then
        inst.SoundEmitter:PlaySound(inst.sound) 
    end
    inst:ListenForEvent("animqueueover", inst.Remove)
end

local fxdata = 
{
    effectsunderarmor = 
    {
        name = "effectsunderarmor",
        bank = "lavaarena_sunder_armor",
        build = "lavaarena_sunder_armor",
        offset = {0, 0, 0},
        scale = 0.7,
        colour = {1, 1, 1, 1},
        anims = {"pre", "loop", "pst"},
        asset = "lavaarena_sunder_armor",
        sound = "dontstarve/impacts/impact_mech_med_sharp"
    },
    effectbloodlust =
    {
        name = "effectbloodlust",
        bank = "lavaarena_attack_buff_effect",
        build = "lavaarena_attack_buff_effect",
        offset = {0, -180, 0},
        scale = 0.7,
        colour = {1, 1, 1, 1},
        anims = {"in", "idle", "out"},
        asset = "lavaarena_attack_buff_effect",
        sound = "dontstarve/common/lava_arena/spell/battle_cry",
    },
    effectevocation =
    {
        name = "effectevocation",
        bank = "effect_evocation",
        build = "effect_evocation",
        offset = {0, 0, 0},
        scale = 0.7,
        colour = {1, 1, 1, 1},
        anims = {"in", "idle", "out"},
        asset = "effect_evocation",
        sound = "dontstarve/common/gemplace",
    },
    effectcripple =
    {
        name = "effectcripple",
        bank = "effect_cripple",
        build = "effect_cripple",
        offset = {0, 0, 0},
        scale = 0.7,
        colour = {1, 1, 1, 1},
        anims = {"in", "loop", "out"},
        asset = "effect_cripple",
        sound = "dontstarve/impacts/impact_hive_lrg_sharp"
    },
    effecthaste =
    {
        name = "effecthaste",
        bank = "hasteeffect",
        build = "hasteeffect",
        offset = {0, 0, 0},
        scale = 0.7,
        colour = {1, 1, 1, 1},
        anims = {"in", "loop", "out"},
        asset = "hasteeffect",
        sound = "dontstarve/common/lava_arena/blow_dart_spread",
    },
    effecttaunt =
    {
        name = "effecttaunt",
        bank = "effect_taunt",
        build = "effect_taunt",
        offset = {0, 50, 0},
        scale = 0.2,
        colour = {1, 1, 1, 1},
        anims = {"in", "idle", "out"},
        asset = "effect_taunt",
        --sound = "dontstarve/common/lava_arena/blow_dart_spread",
    },
}

local function makefx(data)

    local assets =
    {
        Asset("ANIM", "anim/" .. data.asset .. ".zip"),
    }

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddFollower()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        inst.entity:AddSoundEmitter()

        inst:AddTag("FX")
        inst:AddTag("NOCLICK")

        inst.AnimState:SetBank(data.bank)
        inst.AnimState:SetBuild(data.build)
        inst.AnimState:SetMultColour(data.colour[1], data.colour[2], data.colour[3], data.colour[4])

        inst.Transform:SetScale(data.scale, data.scale, data.scale)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.applyAnim = data.anims[1]
        inst.loopAnim = data.anims[2] or data.anims[1]
        inst.removeAnim = data.anims[3] or  data.anims[1]
        inst.offset = data.offset
        inst.scale = data.scale
        inst.sound = data.sound

        inst.StartFollowFX = StartFollowFX
        inst.StopFollowFX = StopFollowFX
        inst.ApplyFX = ApplyFX

        return inst
    end

    --return Prefab("effectsunderarmor", fn, fxassets)
    return Prefab(data.name, fn, assets)
end

return makefx(fxdata["effectsunderarmor"]),
    makefx(fxdata["effectbloodlust"])--,
    --makefx(fxdata["effectevocation"]),
    --makefx(fxdata["effectcripple"]),
    --makefx(fxdata["effecthaste"]),
    --makefx(fxdata["effecttaunt"])