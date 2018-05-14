local function ReticuleTargetFn()
    local player = ThePlayer
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

local reticule = {
    reticuleprefab = "reticuleaoe",
    pingprefab = "reticuleaoeping",
    targetfn = ReticuleTargetFn,
    validcolour = { 1, .75, 0, 1 },
    invalidcolour = { .5, 0, 0, 1 },
    ease = true,
    mouseenabled = true,
}

return reticule