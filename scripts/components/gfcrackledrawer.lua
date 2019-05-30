--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

local colours = 
{
    {0, 0, 0}, --black
    {1, 1, 1}, --white
    {205/255, 0, 0}, -- red
    {124/255, 252/255, 0}, -- green
    {70/255, 130/255, 180/255}, --blue
    {218/255, 165/255, 32/255}, -- yellow
    {147/255, 112/255, 219/255}, -- purple
    {130/255, 100/255, 50/255}, --brown
}

local function FloorToFirstDecimal(val)
    return math.floor(val * 100) * 0.01
end

--call draw on client
local function OnCracklesDirty(inst)
    --print("recieved", inst.components.gfcrackledrawer._docrackles:value())
    local strArr = inst.components.gfcrackledrawer._docrackles:value():split(';')
    local points = {}
    for k, po in pairs(strArr) do
        local splitted = po:split('&')
        --print("start, finish", splitted[1], splitted[2])
        local start, finish = splitted[1]:split(','), splitted[2]:split(',')

        table.insert(points,
            {
                start = { x = tonumber(start[1]), z = tonumber(start[2]) },
                finish = { x = tonumber(finish[1]), z = tonumber(finish[2]) }
            })
    end
    
    inst.components.gfcrackledrawer:DrowCrackles(points)
end

local GFCrackleDrawer = Class(function(self, inst)
    self.inst = inst
    self.fxs = {}
    self._docrackles = net_string(inst.GUID, "GFCrackleDrawer._docrackles", "gfdocrackles")
    self._cracklesColour = net_tinybyte(inst.GUID, "GFCrackleDrawer._cracklesColour")
    self._cracklesBloom = net_bool(inst.GUID, "GFCrackleDrawer._cracklesBloom")

    self._cracklesColour:set_local(0)
    self._cracklesBloom:set_local(false)

    if not TheWorld.ismastersim then
        inst:ListenForEvent("gfdocrackles", OnCracklesDirty)
    end
end)

function GFCrackleDrawer:SetBloom(enabled)
    self._cracklesBloom:set(enabled or false)
end

function GFCrackleDrawer:SetColour(type)
    self._cracklesColour:set(type or 0)
end

--call draw on server
function GFCrackleDrawer:DoCrackles(points)
    if TheWorld.ismastersim then
        self._docrackles:set_local("")
        --self._docrackles:set(string.format("%.2f;%.2f&%.2f;%.2f", start.x, start.z, finish.x, finish.z))
        local draw = {}

        for _, po in pairs(points) do
            table.insert(draw, string.format("%.2f,%.2f&%.2f,%.2f", po.start.x, po.start.z, po.finish.x, po.finish.z))
        end

        self._docrackles:set_local(table.concat(draw, ';'))
        self:DrowCrackles(points)
    end
end

function GFCrackleDrawer:DrowCrackles(points)
    --print(string.format("Drowing lightning from (%.2f, %.2f) to (%.2f, %.2f)",
    --    start.x, start.z, finish.x, finish.z))

    --deidcated server doesn't need to draw lightnings
    if TheNet:IsDedicated() then return end

    --print("number of lightning:", #points)

    for _, lgtn in pairs(points) do
        local dx, dz = lgtn.finish.x - lgtn.start.x, lgtn.finish.z - lgtn.start.z
        local cx, cz = lgtn.finish.x + lgtn.start.x, lgtn.finish.z + lgtn.start.z
        local dist = math.ceil(math.sqrt(dx * dx + dz * dz))
        --print("dist", dist)
        --local sourceAngle = math.atan2(dx, dz) - 1.57

        local pointsToDraw = {{x = lgtn.start.x, z = lgtn.start.z}, {x = lgtn.finish.x, z = lgtn.finish.z}}
        local needPoints = dist * 1.5
        local angleOffset = 1

        while #pointsToDraw <= needPoints do
            --print("--------------------------")
            --if  then break end
            local j = 1
            while j < #pointsToDraw do
                --print(string.format("j is %i, num of poinst is %i", j, #pointsToDraw))
                if pointsToDraw[j + 1] ~= nil then
                    local vstart = pointsToDraw[j]
                    local vend = pointsToDraw[j + 1]
                    --print(string.format("start %i (%.2f, %.2f), end %i (%.2f, %.2f)", j, pointsToDraw[j].x, pointsToDraw[j].z,
                        --j + 1, pointsToDraw[j + 1].x, pointsToDraw[j + 1].z))
                    local dx, dz = vend.x - vstart.x, vend.z - vstart.z
                    local angle = math.atan2(dx, dz) + angleOffset * math.random(15) * DEGREES - 1.57
                    local lenght = math.sqrt(dx * dx + dz * dz) / 2
                    --print("angle, lenght", angle / DEGREES, lenght)
                    --print("inserting pt in pos", j + 1)
                    table.insert(pointsToDraw, j + 1, {x = vstart.x + math.cos(angle) * lenght, z = vstart.z - math.sin(angle) * lenght})
                else
                    --print(string.format("%i (%.2f, %.2f) is last element", j, pointsToDraw[j].x, pointsToDraw[j].z))
                end
                j = j + 2
                angleOffset = angleOffset * -1
            end
        end

        --print("Number of points:", #pointsToDraw)

        local colour = colours[self._cracklesColour:value() + 1]
        local bloom = self._cracklesBloom:value()

        for i = 1, #pointsToDraw - 1 do
            if not TheWorld.Map:IsPassableAtPoint(pointsToDraw[i + 1].x, 0, pointsToDraw[i + 1].z) then break end
            local dx, dz = pointsToDraw[i + 1].x - pointsToDraw[i].x, pointsToDraw[i + 1].z - pointsToDraw[i].z
            local angle = math.atan2(dx, dz) - 1.57
            local obj = SpawnPrefab("gf_cracklefx")
            obj.AnimState:SetMultColour(colour[1], colour[2], colour[3], 0.8)
            --obj:Hide()
            local scale = math.sqrt(dx * dx + dz * dz)--+ 0.45
            scale = FloorToFirstDecimal(scale *  (1.9 - scale))
            obj.Transform:SetScale(scale, 1, scale)
            obj.Transform:SetRotation(angle/DEGREES)
            obj.Transform:SetPosition(pointsToDraw[i].x, 0, pointsToDraw[i].z)
            if bloom then
                obj.components.bloomer:PushBloom("fx", "shaders/anim.ksh", -2)
            end
            table.insert(self.fxs, {obj = obj, scale = scale})
        end
    end

    self.inst.tick = 0
    self.inst:DoTaskInTime(8, function(inst) 
        for k, v in pairs(inst.components.gfcrackledrawer.fxs) do
            v.obj:Remove()
        end
    end)
end

return GFCrackleDrawer