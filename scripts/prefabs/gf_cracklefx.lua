local assets =
{
    Asset("ANIM", "anim/gfcracklefx.zip"),
}

local prefabs = {}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    inst.entity:SetCanSleep(false)

    inst.AnimState:SetBank("gfcracklefx")
    inst.AnimState:SetBuild("gfcracklefx")
    inst.AnimState:PlayAnimation("idle", false)
    inst.AnimState:SetDeltaTimeMultiplier(0.1)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
	inst.AnimState:SetSortOrder(3)

    inst.scaley = math.random(6, 8) * 0.1
    inst.Transform:SetScale(1, inst.scaley, 1)
    
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst:AddComponent("bloomer")

    inst.persists = false

    return inst
end

return  Prefab("gf_cracklefx", fn, assets, prefabs)
