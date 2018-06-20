local assets =
{
    Asset("ANIM", "anim/gf_bee_shooter.zip"),
    Asset("ANIM", "anim/swap_gf_bee_shooter.zip"),
}

local assets_proj =
{
    Asset("ANIM", "anim/bee.zip"),
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_gf_bee_shooter", "swap_gf_bee_shooter")
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

    inst.Transform:SetScale(0.6, 0.6, 0.6)

    inst.AnimState:SetBank("gf_bee_shooter")
    inst.AnimState:SetBuild("gf_bee_shooter")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryPhysics(inst)

    --inst:AddTag("sharp")
    --inst:AddTag("pointy")
    --inst:AddTag("dart")
    --inst:AddTag("castingitem")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
	inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(30)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(20)
    inst.components.finiteuses:SetUses(20)
    inst.components.finiteuses:SetOnFinished(inst.Remove)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    --inst.components.inventoryitem.atlasname = "images/gfinventory.xml"
    inst.components.inventoryitem.imagename = "blowdart_lava2"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)

    return inst
end

local function projfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Transform:SetScale(0.9, 0.9, 0.9)

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("bee")
    inst.AnimState:SetBuild("bee_build")
    inst.AnimState:PlayAnimation("hit", true)
    --inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    --inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    --inst:AddTag("projectile")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    --[[ inst:Hide()

    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(40)
    inst.components.projectile:SetHoming(false)
    inst.components.projectile:SetHitDist(1.0)
    inst.components.projectile:SetOnHitFn(inst.Remove)
    inst.components.projectile:SetOnMissFn(inst.Remove)
    inst.components.projectile:SetOnThrownFn(function(inst) inst:Show() end)
    inst.components.projectile:SetLaunchOffset(Vector3(1.5, 1.4, 1.5)) ]]

    return inst
end

return Prefab("gf_bee_dart", fn, assets),
    Prefab("gf_bee_dart_proj", projfn, assets_proj)
