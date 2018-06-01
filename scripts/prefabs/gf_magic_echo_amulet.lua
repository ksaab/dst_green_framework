local assets =
{
    Asset("ANIM", "anim/swap_gf_amulet_echo.zip"),
}

local function ReplicateCast(inst, data)
    local owner = data.owner
    if owner 
        and owner:IsValid() 
        and not owner:HasTag("playerghost") 
        and not (data.target and not data.target:IsValid())
        and not (inst.components.gfspellitem:GetSpellRecharge("amulet_magic_echo") > 0)
    then
        owner.components.gfspellcaster:CastSpell("amulet_magic_echo", owner, nil, inst)
        owner.components.gfspellcaster:CastSpell(data.spell.name, data.target, data.pos, nil, true)
    end
    inst._task = nil
end

local function OnOwnerCast(owner, data)
    local inst = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
    if inst._task == nil and data.spell:HasSpellTag("replicateable") then
        data.owner = owner
        inst._task = inst:DoTaskInTime(2, ReplicateCast, data)
    end
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "swap_gf_amulet_echo", "swap_gf_amulet_echo")
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

    inst.AnimState:SetBank("swap_gf_amulet_echo")
    inst.AnimState:SetBuild("swap_gf_amulet_echo")
    inst.AnimState:PlayAnimation("idle")

    GFMakeInventoryCastingItem(inst, "amulet_magic_echo", "amulet_magic_echo")

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/gfinventory.xml"

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst._readyIn = GetTime()

    return inst
end

return  Prefab("gf_magic_echo_amulet", fn, assets, prefabs)
