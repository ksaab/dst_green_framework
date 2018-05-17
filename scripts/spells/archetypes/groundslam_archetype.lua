local GFSpell = require("gf_spell")

local function DoCast(self, doer, target, pos, spellData)
    if doer == nil or pos == nil then return false end
    spellData = spellData or {}
    local visuals = self.spellVisuals or {}
    local params = self.spellParams
    
    --caster position
    local x, y, z = doer.Transform:GetWorldPosition()
    local doerAngle = doer.Transform:GetRotation() * DEGREES

    --impact position
    local impactPt = self.impactOnDoer 
        and Vector3(x, y, z)
        or Vector3(x + math.cos(doerAngle) , y, z - math.sin(doerAngle) )

    --math for spell
    local radius = self.range
    local sector = params.sector
    local angleDelta = sector * 0.5 * DEGREES
    local halfpi = PI * 0.5
    local trAngle = math.atan2(pos.x - x, pos.z - z) - halfpi
    local minAngle = trAngle - angleDelta
    local maxAngle = trAngle + angleDelta

    local damage = doer.components.gfspellcaster:GetSpellPower() * params.damage

    print("minAngle and maxAngle", minAngle / DEGREES, maxAngle / DEGREES)

    local dAngle = sector == 360 
        and math.floor(sector / visuals.requiredEffects)  * DEGREES
        or math.floor(sector / (visuals.requiredEffects - 1))  * DEGREES
        
    print(("GS: required effects: %i, angle between effects: %i"):format(visuals.requiredEffects, dAngle / DEGREES))

    local lpos = {}
    for i = 0, visuals.requiredEffects - 1 do
        local _a = i * dAngle + minAngle
        print(_a / DEGREES)
        table.insert(lpos,
            {
                start = {x = impactPt.x, z = impactPt.z},
                finish = {x = x + math.cos(_a) * radius, z = z - math.sin(_a) * radius},
            })
    end

    local notags = { "shadow", "playerghost", "INLIMBO", "NOCLICK", "FX" } 

    local ents = TheSim:FindEntities(x, y, z, radius, nil, notags)
    if sector == 360 then
        for k, ent in pairs(ents) do
            local ex, ey, ez = ent.Transform:GetWorldPosition()
            if visuals.impactFx then
                SpawnPrefab(visuals.impactFx).Transform:SetPosition(ex, ey, ez)--"shovel_dirt"
            end
            if ent.components.combat and not doer.components.gfspellcaster:IsTargetFriendly(ent) then
                ent.components.combat:GetAttacked(doer, damage)
            elseif ent.components.inventoryitem and ent.Physics then
                ent.Physics:Teleport(ex, ey + 0.5, ez)
                ent.Physics:SetVel(0, 3, 0)
            end
        end
    else
        for k, ent in pairs(ents) do
            local ex, ey, ez = ent.Transform:GetWorldPosition()
            local eangle = math.atan2(ex - x, ez - z) - halfpi
            --eangle = eangle >= 0 and eangle or 2 * PI - eangle
            --print("entity", ent, "angle", eangle / DEGREES)
            if eangle < maxAngle and eangle > minAngle then
                if visuals.impactFx then SpawnPrefab(visuals.impactFx).Transform:SetPosition(ex, ey, ez) end
                if ent.components.combat and not doer.components.gfspellcaster:IsTargetFriendly(ent) then
                    ent.components.combat:GetAttacked(doer, damage, nil)
                elseif ent.components.inventoryitem and ent.Physics then
                    ent.Physics:Teleport(ex, ey + 0.5, ez)
                    ent.Physics:SetVel(0, 12, 0)
                end
            end
        end
    end

    local fxdummy = SpawnPrefab("gf_crackle_dummy")
    fxdummy.Transform:SetPosition(x, y, z)
    if visuals.crackleDrawerBloom then fxdummy.components.gfcrackledrawer:SetBloom(true) end
    if visuals.crackleDrawerColour then fxdummy.components.gfcrackledrawer:SetColour(visuals.crackleDrawerColour) end

    ShakeAllCameras(CAMERASHAKE.VERTICAL, .7, .015, .8, doer, 20)
    fxdummy.components.gfcrackledrawer:DoCrackles(lpos)

    if visuals.castSound then fxdummy.SoundEmitter:PlaySound(visuals.castSound) end

    return true
end

local function AiCheck(self, inst)
    local target = inst.components.combat.target
    local aiParams = self.aiParams
    if target and not inst:IsNear(target, aiParams.minDist) then
        local x, y, z = inst.Transform:GetWorldPosition()
        local res = 
        {
            target = target,
            distance = aiParams.maxDist,
        }

        return res
    end

    return false
end

local Spell = Class(GFSpell, function(self, name)
    GFSpell._ctor(self, name) --inheritance

    self.instant = false
    self.playerState = "gfgroundslam"
    self.pointer = nil

    self.tags = {
        ability = true,
    }

    if not GFGetIsMasterSim() then 
        return 
    end
    
    --spell cooldowns
    self.itemRecharge = 0
    self.doerRecharge = 0

    --spell fns
    self.spellfn = DoCast 

    self.spellParams =
    {
        damage = 50,
        sector = 90,
    }
    
    --visual
    self.spellVisuals =
    {
        impactOnDoer = true,
        requiredEffects = 4,
        crackleDrawerBloom = nil,
        crackleDrawerColour = 7,
        castSound = nil,
        impactFx = nil,
    }

    --AI--
    self.aicheckfn = AiCheck
    self.aiParams = 
    {
        minDist = 3,
        maxDist = 12
    }

    --AI--
    self.aicheckfn = AiCheck
end)

return Spell