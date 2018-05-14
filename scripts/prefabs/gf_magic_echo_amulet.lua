local assets =
{
    Asset("ANIM", "anim/amulets.zip"),
    Asset("ANIM", "anim/torso_amulets.zip"),
}

local function ReplicateCast(inst, data)
    if data.owner 
        and data.owner:IsValid() 
        and not data.owner:HasTag("playerghost") 
        and not (data.target and not data.target:IsValid())
    then
        data.owner.components.gfspellcaster:CastSpell(data.spell.name, data.target, data.pos, nil, true)
        inst._readyIn = GetTime() + 8
    end
    inst._task = nil
end

local function OnOwnerCast(owner, data)
    local inst = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
    if inst._task == nil 
        and inst._readyIn < GetTime() 
        and data.spell 
        and data.spell:HasSpellTag("replicateable") 
    then
        data.owner = owner
        inst._task = inst:DoTaskInTime(2, ReplicateCast, data)
    end
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "torso_amulets", "redamulet")
    inst:ListenForEvent("gfspellcastsuccess", OnOwnerCast, owner)
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    inst:RemoveEventCallback("gfspellcastsuccess", OnOwnerCast, owner)
    if inst._task ~= nil then
        inst._task:Cancel()
        inst._task = nil
    end
end

local prefabs = {}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("amulets")
    inst.AnimState:SetBuild("amulets")
    inst.AnimState:PlayAnimation("redamulet")

    GFMakeInventoryCastingItem(inst)

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst._readyIn = GetTime()

    return inst
end

return  Prefab("gf_magic_echo_amulet", fn, assets, prefabs)
