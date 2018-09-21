local function lightningdummyfn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    inst:AddComponent("gflightningdrawer")
    inst:AddTag("NOCLICK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false
    inst:DoTaskInTime(10, inst.Remove)

    return inst
end

local function crackledummyfn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()
    
    inst:AddComponent("gfcrackledrawer")
    inst:AddTag("NOCLICK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false
    inst:DoTaskInTime(20, inst.Remove)

    return inst
end

local function localdummyfn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()

    inst:AddTag("NOCLICK")
    inst.persists = false

    return inst
end

local function netdummyfn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    inst:AddTag("NOCLICK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end


return Prefab( "gf_local_dummy", localdummyfn),
    Prefab( "gf_net_dummy", netdummyfn),
    Prefab( "gf_lightning_dummy", lightningdummyfn),
    Prefab( "gf_crackle_dummy", crackledummyfn)
    
