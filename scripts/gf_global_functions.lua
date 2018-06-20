local GFIsTogether = _G.TheNet ~= nil and true or false
rawset(_G, "GFIsTogether", GFIsTogether)
print(("Green Framework: is together: %s"):format(tostring(GFIsTogether)))

local function ReturnTrue()
    return true
end

local function ReturnFalse()
    return false
end

local GFGetIsMasterSim
local GFGetIsDedicatedNet
local GFGetPVPEnabled
local GFGetWorld
local GFGetPlayer

if not GFIsTogether then
    GFGetIsMasterSim = ReturnTrue
    GFGetIsDedicatedNet = ReturnTrue
    GFGetPVPEnabled = ReturnTrue
    GFGetWorld = GetWorld
    GFGetPlayer = GetPlayer
else
    GFGetIsMasterSim = function()
        return TheWorld.ismastersim
    end
    GFGetIsDedicatedNet = function()
        return TheNet:IsDedicated()
    end
    GFGetPVPEnabled = function()
        return TheNet:GetPVPEnabled()
    end
    GFGetWorld = function()
        return TheWorld
    end
    GFGetPlayer = function()
        return ThePlayer
    end
end


rawset(_G, "GFGetIsMasterSim", GFGetIsMasterSim)
rawset(_G, "GFGetIsDedicatedNet", GFGetIsDedicatedNet)
rawset(_G, "GFGetPVPEnabled", GFGetPVPEnabled)
rawset(_G, "GFGetWorld", GFGetWorld)
rawset(_G, "GFGetPlayer", GFGetPlayer)

function GFDebugPrint(...)
    if GFDev then
        print(...)
    end
end

function GFAddCustomSpell(name, route, id)
    id = (id and type(id) == "number") and id or #GFSpellIDToName + 1
    if GFSpellIDToName[id] ~= nil then
        error(("Spell with id %i already exists"):format(id), 3)
    end
    GFSpellList[name] = require(route .. name)
    GFSpellList[name].name = name
    GFSpellList[name].id = id
    GFSpellNameToID[name] = id
    GFSpellIDToName[id] = name
end

function GFAddCustomEffect(name, route, id)
    id = (id and type(id) == "number") and id or #GFEffectIDToName + 1
    if GFEffectIDToName[id] ~= nil then
        error(("Effect with id %i already exists"):format(id), 3)
    end
    GFEffectList[name] = require(route .. name)
    GFEffectList[name].name = name
    GFEffectList[name].id = id
    GFEffectNameToID[name] = id
    GFEffectIDToName[id] = name
end

function GFAddBaseSpellsToEntity(prefab, ...)
    if GFEntitiesBaseSpells[prefab] == nil then
        GFEntitiesBaseSpells[prefab] = {}
    end
    for _, v in pairs(arg) do
        table.insert(GFEntitiesBaseSpells[prefab], v)
    end
end

function GFMakePlayerCaster(inst, spells)
    if not inst.gfmodified then
        inst.gfmodified = true
        inst:AddTag("gfscclientside")
        if GFGetIsMasterSim() then
            inst:AddComponent("gfspellcaster")
            if spells ~= nil then
                inst.components.gfspellcaster:AddSpell(spells)
            end
        end
    else
        GFDebugPrint(string.format("GF: %s was already initiated ", tostring(inst)))
    end
end

function GFMakeCaster(inst, spells)
    if not inst.gfmodified then
        inst.gfmodified = true
        if GFGetIsMasterSim() then
            inst:AddComponent("gfspellcaster")
            if spells ~= nil then
                inst.components.gfspellcaster:AddSpell(spells)
            end
        end
    else
        GFDebugPrint(string.format("GF: %s was already initiated ", tostring(inst)))
    end
end

function GFMakeInventoryCastingItem(inst, spells)
    if not inst.gfmodified then
        inst.gfmodified = true
        if GFGetIsMasterSim() then
            inst:AddComponent("gfspellitem")
            if spells ~= nil then
                inst.components.gfspellitem:AddSpell(spells)
                if type(spells) == "table" then
                    inst.components.gfspellitem:SetItemSpell(spells[1])
                else
                    inst.components.gfspellitem:SetItemSpell(spells)
                end
            end
        end
    else
        GFDebugPrint(string.format("GF: %s was already initiated ", tostring(inst)))
    end
end

function GFGetValidSpawnPosition(x, y, z, minradius, maxradius, ground, maxtries)
    local angle = math.random(360) * DEGREES
    maxtries = maxtries or 10
    minradius = minradius or 1
    maxradius = maxradius or (minradius or 10)
    local radius = minradius == maxradius and minradius or math.random(minradius, maxradius)
    local pt
    local try = 1
    repeat 
        pt = Vector3(x + math.cos(angle) * radius, y, z - math.sin(angle) * radius)
        if not ground or GetThisWorld().Map:IsPassableAtPoint(pt:Get()) then
            break
        end
        pt = nil
    until try < maxtries

    return pt
end

function GFListenForEventOnce(inst, event, fn, source) --not mine, author simplex
    -- Currently, inst2 is the source, but I don't want to make that assumption.
    function gn(inst2, data)
        inst:RemoveEventCallback(event, gn, source) --as you can see, it removes the event listener even before firing the function
        return fn(inst2, data)
    end
     
    return inst:ListenForEvent(event, gn, source)
end

function GFIsEntityOnLine(ent, pt1, pt2) -- not net, geometry
	local xe, _, ye = ent.Transform:GetWorldPosition() 
    local radius = ent:GetPhysicsRadius(0) or 0.5

    local p1, p2 = {}, {}
    p1.x = pt1.x - xe
    p1.y = pt1.y - ye
    p2.x = pt2.x - xe
    p2.y = pt2.y - ye
    local dx = (p2.x - p1.x)
    local dy = (p2.y - p1.y)
    local a = dx * dx + dy * dy;
    local b = 2 * ( p1.x * dx + p1.y * dy);
    local c = p1.x * p1.x + p1.y * p1.y - radius * radius;

    if -b < 0 then return c < 0 end
    if -b < 2 * a then return 4 * a * c - b * b < 0 end
    return ((a + b + c < 0))
end

function GFIsEntityInside(polygon, ent)
	local pt = {}
	pt.x, pt.o, pt.y = ent.Transform:GetWorldPosition() -- "_" does't work, let it be pt.o
	local radius = ent:GetPhysicsRadius(0) or 0.5
	local intersections = 0
	local prev = #polygon
	local prevUnder = polygon[prev].y < pt.y
	for i = 1, #polygon do
		local currUnder = polygon[i].y < pt.y
		local p1, p2 = {}, {}
		p1.x = polygon[prev].x - pt.x
		p1.y = polygon[prev].y - pt.y
        p2.x = polygon[i].x - pt.x
		p2.y = polygon[i].y - pt.y
		local dx = (p2.x - p1.x)
		local dy = (p2.y - p1.y)
		local t = (p1.x * dy - p1.y * dx)
		
		local a = dx * dx + dy * dy;
        local b = 2 * ( p1.x * dx + p1.y * dy);
        local c = p1.x * p1.x + p1.y * p1.y - radius * radius;

        if -b < 0 and c < 0 then return true end
        if -b < 2 * a and 4 * a * c - b * b < 0  then return true end
        if (a + b + c < 0) then return true end
		
		if currUnder and not prevUnder then
            if (t > 0) then
                intersections = intersections + 1
			end
		end
        
        if not currUnder and prevUnder then
            if (t < 0) then
                intersections = intersections + 1
			end
		end
		
		prev = i
        prevUnder = currUnder
	end
	return not IsNumberEven(intersections)
end

function GFSoftColorChange(inst, fc, sc, time, step)
    if sc == nil then sc = {1, 1, 1, 1} end
    if time == nil then time = 1 end
    if step == nil or step > 1 then step = 0.1 end
    local totalSteps = math.ceil (time / step)
    inst.AnimState:SetMultColour(sc[1], sc[2], sc[3], sc[4])
    local dRed      = (fc[1] - sc[1]) / totalSteps
    local dGreen    = (fc[2] - sc[2]) / totalSteps
    local dBlue     = (fc[3] - sc[3]) / totalSteps
    local dAlpha    = (fc[4] - sc[4]) / totalSteps
    local deltaColor = {dRed, dGreen, dBlue, dAlpha}
    local currStep = 0
    --local steps = 0
    if inst._softColorTask ~= nil then inst._softColorTask:Cancel() end

    --print(string.format([[starting soft color task: 
        --starting color's mults - red: %.2f, green: %.2f, blue: %.2f, alpha: %.2f 
        --finishcolors - red: %.2f, green: %.2f, blue: %.2f, alpha: %.2f
        --time for procssing: %.2f, step: %.2f
        --delta colors - red: %.2f, green: %.2f, blue: %.2f, alpha: %.2f]],
        --sc[1], sc[2], sc[3], sc[4], fc[1], fc[2], fc[3], fc[4], time, step, dRed, dGreen, dBlue, dAlpha ))

    inst._softColorTask = inst:DoPeriodicTask(step, function(inst)
        if currStep <= totalSteps then
            --print(time)
            inst.AnimState:SetMultColour(sc[1] + deltaColor[1] * currStep, 
                sc[2] + deltaColor[2] * currStep, 
                sc[3] + deltaColor[3] * currStep, 
                sc[4] + deltaColor[4] * currStep)
            currStep = currStep + 1
        else
            --print(string.format("soft color task complete: \nresult color's mults - red: %.2f, green: %.2f, blue: %.2f, alpha: %.2f", 
            --    sc[1] + deltaColor[1] * currStep, 
            --    sc[2] + deltaColor[2] * currStep, 
            --    sc[3] + deltaColor[3] * currStep, 
            --    sc[4] + deltaColor[4] * currStep))
            inst._softColorTask:Cancel() 
            inst._atask = nil
        end
    end, nil, deltaColor, totalSteps, currStep)
end

function GFPumpkinTest(entity)
    entity = entity or AllPlayers[1]
    local x, y, z = entity.Transform:GetWorldPosition()
    for i = 1, 12 do
        local pt = Vector3(x + math.cos(i * 30) * 10, y, z - math.sin(i * 30) * 10)
        SpawnPrefab("pumpkin_lantern").Transform:SetPosition(pt:Get())
    end
end

function GFTestGlobalFunctions()
    print("GFGetIsMasterSim", GFGetIsMasterSim())
    print("GFGetIsDedicatedNet", GFGetIsDedicatedNet())
    print("GFGetPVPEnabled", GFGetPVPEnabled())
    print("GFGetWorld", GFGetWorld())
    print("GFGetPlayer", GFGetPlayer())
end

--rawset(_G, "GFTestGlobalFunctions", GFTestGlobalFunctions)