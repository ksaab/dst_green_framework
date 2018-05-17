local GFSpell = require("gf_spell")

local function DoCast(self, doer, target, pos, spellData)
    if doer == nil or pos == nil then return false end
    spellData = spellData or {}
    local visuals = self.spellVisuals or {}
    local params = self.spellParams
    
    --caster position
    local x, y, z = doer.Transform:GetWorldPosition()
    --local doerAngle = doer.Transform:GetRotation() * DEGREES

    --impact position
    --local impactPt = Vector3(x + math.cos(doerAngle) , y, z - math.sin(doerAngle) )

    --math for spell
    local radius = self.range
    local sector = params.sector
    local angleDelta = params.sector * 0.5 * DEGREES
    local halfpi = PI * 0.5
    local trAngle = math.atan2(pos.x - x, pos.z - z) - halfpi
    local minAngle = trAngle - angleDelta
    local maxAngle = trAngle + angleDelta

    local damage = doer.components.gfspellcaster:GetSpellPower() * params.damage
    print("CR: Damage", damage)

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
                start = {x = x, z = z},
                finish = {x = x + math.cos(_a) * radius, z = z - math.sin(_a) * radius},
            })
    end

    local notags = { "shadow", "playerghost", "INLIMBO", "NOCLICK", "FX" } 

    local ents = TheSim:FindEntities(x, y, z, radius, nil, notags)
    if sector == 360 then
        for k, ent in pairs(ents) do
            local ex, ey, ez = ent.Transform:GetWorldPosition()
            --SpawnPrefab("shovel_dirt").Transform:SetPosition(ex, ey, ez)
            if ent.components.combat and not doer.components.gfspellcaster:IsTargetFriendly(ent) then
                ent.components.combat:GetAttacked(doer, damage, nil, "electric")
            --[[ elseif ent.components.cookable 
                and ent.components.cookable.product ~= nil 
                and type(ent.components.cookable.product) ~= "function" 
            then
                SpawnPrefab(ent.components.cookable.product).Transform:SetPosition(ex, ey, ez)
                ent:Remove() ]]
            end
        end
    else
        for k, ent in pairs(ents) do
            local ex, ey, ez = ent.Transform:GetWorldPosition()
            local eangle = math.atan2(ex - x, ez - z) - halfpi
            if eangle < maxAngle and eangle > minAngle then
                --SpawnPrefab("shovel_dirt").Transform:SetPosition(ex, ey, ez)
                if ent.components.combat and not doer.components.gfspellcaster:IsTargetFriendly(ent) then
                    ent.components.combat:GetAttacked(doer, damage, nil, "electric")
                    if visuals.impactFx ~= nil then SpawnPrefab(visuals.impactFx).Transform:SetPosition(ex, 0, ez) end
                --[[ elseif ent.components.cookable 
                    and ent.components.cookable.product ~= nil 
                    and type(ent.components.cookable.product) ~= "function" 
                then
                    SpawnPrefab(ent.components.cookable.product).Transform:SetPosition(ex, ey, ez)
                    ent:Remove() ]]
                end
            end
        end
    end

    local fxdummy = SpawnPrefab("gf_lightning_dummy")
    fxdummy.Transform:SetPosition(x, y, z)
    fxdummy.components.gflightningdrawer:SetColour(visuals.lightningDrawerColour)
    fxdummy.components.gflightningdrawer:DoLightning(lpos)
    if visuals.castSound then fxdummy.SoundEmitter:PlaySound(visuals.castSound) end

    return true
end

local function AiCheck(self, inst)
    local aiParams = self.aiParams
    local target = inst.components.combat.target
    if target and not inst:IsNear(target, aiParams.minDist) then
        local x, y, z = inst.Transform:GetWorldPosition()
        local pos = Vector3(target.Transform:GetWorldPosition())
        local res = 
        {
            target = target,
            distance = aiParams.maxDist,
            pos = pos,
        }

        return res
    end

    return false
end

local Spell = Class(GFSpell, function(self, name)
    GFSpell._ctor(self, name) --inheritance

    self.instant = false
    self.playerState = "gfcastwithstaff"
    self.pointer = nil

    self.tags = {
        magic = true,
        lightning = true,
        replicateable = true,
    }

    if not GFGetIsMasterSim() then 
        return 
    end

    --cooldowns
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
        lightningDrawerColour = nil, --lightning colour
        requiredEffects = 3, --num of lightnings 
        castSound = nil,
        impactFx = nil,
    }

    --AI--
    self.aicheckfn = AiCheck
    self.aiParams = 
    {
        minDist = 3,
        maxDist = 9,
    }
end)

return Spell