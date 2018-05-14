local function ReticuleTargetFn()
    local player = ThePlayer
    local ground = TheWorld.Map
    local pos = Vector3()
    for r = 8, 0, -.25 do
        pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
        if ground:IsPassableAtPoint(pos:Get()) and not ground:IsGroundTargetBlocked(pos) then
            return pos
        end
    end
    return pos
end

local reticule = {
    reticuleprefab = "reticule_lightning",
    pingprefab = "reticule_lightning_ping",
    targetfn = ReticuleTargetFn,
    validcolour = { 0, 0.25, 0.5, 1 },
    invalidcolour = { .5, 0, 0, 1 },
    ease = true,
    mouseenabled = true,
}

return reticule