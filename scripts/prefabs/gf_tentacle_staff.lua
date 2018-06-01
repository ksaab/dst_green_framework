local assets =
{
    Asset("ANIM", "anim/gf_tentacle_staff.zip"),
    Asset("ANIM", "anim/swap_gf_tentacle_staff.zip"),
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_gf_tentacle_staff", "swap_gf_tentacle_staff")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("gf_tentacle_staff")
    inst.AnimState:SetBuild("gf_tentacle_staff")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("staff")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
	inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(30)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(500)
    inst.components.finiteuses:SetUses(500)
    inst.components.finiteuses:SetOnFinished(inst.Remove)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/gfinventory.xml"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("gf_tentacle_staff", fn, assets)
