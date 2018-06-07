local function ReticuleTargetFn()
    local player = GFGetPlayer()
    local ground = TheWorld.Map
    local pos = Vector3()
    --Cast range is 8, leave room for error
    --4 is the aoe range
    for r = 7, 0, -.25 do
        pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
        if ground:IsPassableAtPoint(pos:Get()) and not ground:IsGroundTargetBlocked(pos) then
            return pos
        end
    end
    return pos
end

local function ReticuleMouseTargetFn(inst, mousepos)
    if mousepos ~= nil then
        local x, y, z = inst.Transform:GetWorldPosition()
        local underMouse = TheInput:GetWorldEntityUnderMouse()
        if underMouse ~= nil and underMouse:IsValid() then
            return Vector3(underMouse.Transform:GetWorldPosition())
        else
            return mousepos
        end
    end
end

local reticule = {
    reticuleprefab = "gf_reticule_nature_triangle",
    --pingprefab = "gf_reticule_nature_triangle_ping",
    targetfn = ReticuleTargetFn,
    mousetargetfn = ReticuleMouseTargetFn,
    validcolour = { 0, 1, 0.75, 1 },
    invalidcolour = { .5, 0, 0, 1 },
    ease = true,
    mouseenabled = true,
}

return reticule