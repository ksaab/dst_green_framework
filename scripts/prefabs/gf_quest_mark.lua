local assets =
{
    Asset("ANIM", "anim/gf_quest_mark.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()

    inst.AnimState:SetBank("gf_quest_mark")
    inst.AnimState:SetBuild("gf_quest_mark")
    inst.AnimState:PlayAnimation("none", true)
    --inst.AnimState:SetScale(3, 3, 3)

    inst.persists = false

    return inst
end

return Prefab("gf_quest_mark", fn, assets)
