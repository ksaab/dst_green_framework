local assets =
{
    Asset("ANIM", "anim/swap_gf_cute_bottle.zip"),
    Asset("ANIM", "anim/gf_cute_bottle.zip"),
}

local function OnDrunk(inst, drinker)
    print(drinker, "drunk", inst)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("gf_cute_bottle")
    inst.AnimState:SetBuild("gf_cute_bottle")
    inst.AnimState:PlayAnimation("idle")

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/gfinventory.xml"

    inst:AddComponent("gfdrinkable")
    inst.components.gfdrinkable:SetOnDrunkFn(OnDrunk)

    return inst
end

return  Prefab("gf_potion_metabolism", fn, assets)
