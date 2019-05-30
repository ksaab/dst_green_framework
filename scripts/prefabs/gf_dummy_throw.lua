local assets = 
{
    Asset("ANIM", "anim/gf_throw_dummy.zip"),
}

--[[LOGIC]]-----------------------------
----------------------------------------
local HSPEED = 15
local DELTA_SPEED = 0.5

local function MakeFlyingProjectile(inst)
    inst._tail:set(true)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:PlayAnimation("fly", true)
end

local function MakeReverceProjectile(inst)
    inst._tail:set(true)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:PlayAnimation("rfly", true)
end

local function MakeHorizontalProjectile(inst)
    inst._tail:set(true)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:PlayAnimation("hspin", true)
end

local function MakeVerticalProjectile(inst)
    inst._tail:set(true)
    inst.Transform:SetSixFaced()
    inst.AnimState:PlayAnimation("vspin", true)
end

local function OnLand(inst)
    if inst._tail:value() then
        inst._tail:set(false)
    end

    if not inst:IsOnValidGround() then
        local splash = SpawnPrefab("splash_ocean")
        if splash ~= nil then
            splash.Transform:SetPosition(inst.Transform:GetWorldPosition())
        end
    else
        inst.Physics:SetCollisionCallback(nil)
        inst.Physics:Stop()
        if inst._equipped ~= nil and inst._equipped:IsValid() then
            local weap = inst._equipped
            inst.components.inventory:Unequip(EQUIPSLOTS.HANDS)
            inst.components.inventory:DropItem(weap)
            if weap ~= nil then 
                weap.Transform:SetPosition(inst.Transform:GetWorldPosition()) 
                weap.Transform:SetRotation(inst.Transform:GetRotation()) 
            end
            if weap.components.finiteuses ~= nil then weap.components.finiteuses:Use(2) end
        end
        --if weap.Physics ~= nil then 
        --    angle = angle * DEGREES -- 1.57
        --    weap.Physics:SetVel(math.cos(angle) * 2, 0, -math.sin(angle) * 2)
        --end
    end

    inst:Remove()
end

local function OnHit(inst, victim)
    if inst._tail:value() then
        inst._tail:set(false)
    end
    inst.Physics:Stop()
    inst.Physics:SetCollisionCallback(nil)
    inst.Transform:SetTwoFaced()
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.BillBoard)
    inst.AnimState:PlayAnimation("bounce", false)
    inst:ListenForEvent("animover", OnLand)
end

local function Collide(inst, other)
    if other.components.combat ~= nil then
        if GFGetPVPEnabled() or not other:HasTag("player") then
            if inst._thrower ~= nil then
                local damage = (inst._equipped ~= nil) and inst._equipped.components.weapon.damage or 35
                local type = (inst._equipped ~= nil) and inst._equipped.components.weapon.stimuli or nil
                inst._thrower.components.combat:AttackWithMods(other, damage, inst, type)
                if inst._equipped.components.finiteuses ~= nil then inst._equipped.components.finiteuses:Use(1) end
            end
        end
    elseif other.components.workable ~= nil and inst._equipped ~= nil and inst._equipped.components.tool then
        local action = other.components.workable:GetWorkAction()
        local cmp = inst._equipped.components.tool
        if cmp:CanDoAction(action) then
            other.components.workable:WorkedBy(inst._thrower, cmp:GetEffectiveness(action))
            if inst._equipped.components.finiteuses ~= nil then inst._equipped.components.finiteuses:Use(1) end
        end
    end

    if inst._ptask ~= nil then
        inst._ptask:Cancel()
        inst._ptask = nil
    end

    OnHit(inst, other)
end

local function Projectile(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    if y <= 0.25 then
        if inst._ptask ~= nil then
            inst._ptask:Cancel()
            inst._ptask = nil
        end
        OnLand(inst)
    else
        local resume = true
        local cTime = GetTime()
        if cTime - inst._lastCheck >= 0.1 then
            inst._lastCheck = cTime
            local x, y, z = inst.Transform:GetWorldPosition()
            for k, v in pairs (TheSim:FindEntities(x, y, z, 3, {}, { "playerghost", "shadow", "INLIMBO", "FX", "NOCLICK" })) do
                if v.components.combat ~= nil 
                    and v ~= inst._thrower
                    and inst:GetDistanceSqToInst(v) <= v:GetPhysicsRadius(0) * v:GetPhysicsRadius(0) + 1
                    and not (v:HasTag("player") and not TheNet:GetPVPEnabled())
                then
                    Collide(inst, v)
                    resume = false
                    break
                end
            end
        end
        if resume then
            --local x, y, z = inst.Transform:GetWorldPosition()
            --print(y)
            local tDiff = cTime - inst._startTime
            inst._ySpeed = inst._ySpeed - DELTA_SPEED
            inst.Physics:SetMotorVel(HSPEED, inst._ySpeed, 0)
            --local ySpeed = 20 * (0.5 - tDiff)
            --inst.Physics:SetMotorVel(15, ySpeed, 0)
        end
    end
end

local function Launch(inst, pos, thrower, item)
    if thrower == nil or pos == nil or item == nil then 
        inst:Remove()
    end

    local x, y, z = thrower.Transform:GetWorldPosition()
    local angle = math.atan2(pos.x - x, pos.z - z) - 1.5707
    local cos = math.cos(angle)
    local sin = math.sin(angle)

    local sqdistance = distsq(x, z, pos.x, pos.z)
    local mult = thrower.components.combat:GetDamageMods()
    local distance = math.max(5, math.min(math.min(1.5, mult) * 15, math.sqrt(sqdistance)))
    local maxmult = math.min(1.5, mult)
    local minmult = 0.33 --math.max(0.5, mult)

    --local ttf = distance / HSPEED -- how many time a projectile needs to reach the destination point
    --local vtotal = (ttf / FRAMES) * DELTA_SPEED --total vertical distance
    --local highest = math.max(0, vtotal - 2.5) --the highest vertical point
    --local strength = math.max(0, vtotal - 2.5) / (1 / DELTA_SPEED)

    local ttf = distance / HSPEED -- how many time a projectile needs to reach the destination point
    local vdiff = (ttf / FRAMES) * DELTA_SPEED--v speed delta
    local strength = vdiff / 2

    --print(distance, ttf, vdiff, strength)

    --local strength = math.max(math.min(maxmult, distance / (15 * 15)), minmult)
    --print(strength, distance / (15 * 15), distance)
    
    --local target = Vector3(x + cos * 15, 0, z - sin * 15)

    inst.Transform:SetPosition(x, 1.5, z)
    inst:ForceFacePoint(pos.x, 0, pos.z)
    inst.Physics:SetCollisionCallback(Collide)

    inst.components.inventory:GiveItem(item)
    inst.components.inventory:Equip(item)

    inst._equipped = item
    inst._thrower = thrower
    inst._startTime = GetTime()
    inst._lastCheck = GetTime()
    inst._ySpeed = strength--15 * strength - 5
    inst._ptask = inst:DoPeriodicTask(0, Projectile)
end

--[[VISUALS]]---------------------------
----------------------------------------
local tails =
{
    ["tail_5_2"] = .15,
    ["tail_5_3"] = .15,
    ["tail_5_4"] = .2,
    ["tail_5_5"] = .8,
    ["tail_5_6"] = 1,
    ["tail_5_7"] = 1,
}

local thintails =
{
    ["tail_5_8"] = 1,
    ["tail_5_9"] = .5,
}

local function CreateTail(thintail)
    local inst = CreateEntity()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.AnimState:SetBank("lavaarena_blowdart_attacks")
    inst.AnimState:SetBuild("lavaarena_blowdart_attacks")
    inst.AnimState:PlayAnimation(weighted_random_choice(thintail and thintails or tails))
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetAddColour(0.75, 0.75, 0.75, 0.8)

    inst:ListenForEvent("animover", inst.Remove)

    return inst
end

local function OnUpdateProjectileTail(inst)
    local c = math.random()
    local tail = CreateTail(inst.thintailcount > 0)
    tail.Transform:SetPosition(inst.Transform:GetWorldPosition())
    tail.Transform:SetRotation(inst.Transform:GetRotation())
    tail.AnimState:SetTime(c * tail.AnimState:GetCurrentAnimationLength())
    inst.thintailcount = inst.thintailcount - 1
end

local function EnableTail(inst)
    if inst._tail:value() then
        inst.thintailcount = math.random(1, 2)
        inst._ttask = inst:DoPeriodicTask(FRAMES * 4, OnUpdateProjectileTail)
    else
        if inst._ttask ~= nil then
            inst._ttask:Cancel()
            inst._ttask = nil
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()
    inst.entity:AddAnimState()
    local phys = inst.entity:AddPhysics()

    inst.AnimState:SetBank("gf_throw_dummy")
    inst.AnimState:SetBuild("gf_throw_dummy")
    inst.AnimState:PlayAnimation("fly", true)
    --inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)

    phys:SetMass(1)
	phys:SetFriction(.1)
	phys:SetDamping(0)
	phys:SetRestitution(.5)
	phys:SetCollisionGroup(COLLISION.ITEMS)
	phys:ClearCollisionMask()
	--phys:CollidesWith(COLLISION.WORLD)
	phys:CollidesWith(COLLISION.OBSTACLES)
    --phys:CollidesWith(COLLISION.ITEMS)
    --phys:CollidesWith(COLLISION.CHARACTERS)
    --phys:CollidesWith(COLLISION.GIANTS)
    --phys:CollidesWith(COLLISION.FLYERS)
	phys:SetCapsule(1, 5)
    
    inst:AddTag("NOCLICK")
    inst:AddTag("scarytoprey")

    inst._tail = net_bool(inst.GUID, "gf_throw_dummy.tail", "enabletail")
    --inst._tail:set_local(false)

    if not TheNet:IsDedicated() then
        inst:ListenForEvent("enabletail", EnableTail)
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventory")

    inst.persists = false

    inst.Launch = Launch
    inst.MakeFlyingProjectile = MakeFlyingProjectile
    inst.MakeReverceProjectile = MakeReverceProjectile
    inst.MakeHorizontalProjectile = MakeHorizontalProjectile
    inst.MakeVerticalProjectile = MakeVerticalProjectile

    return inst
end

return Prefab( "gf_throw_dummy", fn, assets)