local assets =
{
    Asset("ANIM", "anim/flint.zip"),
}

local function Check(item)
    return item 
        and item.replica.equippable
        and item.replica.equippable:EquipSlot() == EQUIPSLOTS.HANDS
        and not item.replica.stackable
		and not item:HasTag("projectile")
end

local function Enhance(item)
    print(("item %s enhanced!"):format(tostring(item)))
    return true
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetRayTestOnBB(true)
    inst.AnimState:SetBank("flint")
    inst.AnimState:SetBuild("flint")
    inst.AnimState:PlayAnimation("idle")

    inst:AddComponent("gfitemenhancer")
    inst.components.gfitemenhancer.checkfn = Check
    inst.components.gfitemenhancer.enchancefn = Enhance
    --inst.components.gfitemenhancer.removeOnUse = true

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "flint"

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(5)
    inst.components.finiteuses:SetUses(5)
    inst.components.finiteuses:SetOnFinished(inst.Remove)

    MakeHauntableLaunchAndSmash(inst)

    return inst
end

return  Prefab("gf_hone", fn, assets)
