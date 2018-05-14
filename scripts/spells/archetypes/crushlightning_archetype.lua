local GFSpell = require("gf_spell")

local function DoCast(self, doer, target, pos, spellData)
    if doer == nil or pos == nil then return false end
    spellData = spellData or {}
    
    --caster position
    local x, y, z = doer.Transform:GetWorldPosition()
    --local doerAngle = doer.Transform:GetRotation() * DEGREES

    --impact position
    --local impactPt = Vector3(x + math.cos(doerAngle) , y, z - math.sin(doerAngle) )

    --math for spell
    local radius = self.range
    local angleDelta = self.sector * 0.5 * DEGREES
    local halfpi = PI * 0.5
    local trAngle = math.atan2(pos.x - x, pos.z - z) - halfpi
    local minAngle = trAngle - angleDelta
    local maxAngle = trAngle + angleDelta

    local damage = doer.components.gfspellcaster:GetSpellPower() * self.damage
    print("CR: Damage", damage)

    print("minAngle and maxAngle", minAngle / DEGREES, maxAngle / DEGREES)

    local dAngle = self.sector == 360 
        and math.floor(self.sector / self.requiredEffects)  * DEGREES
        or math.floor(self.sector / (self.requiredEffects - 1))  * DEGREES
        
    print(("GS: required effects: %i, angle between effects: %i"):format(self.requiredEffects, dAngle / DEGREES))

    local lpos = {}
    for i = 0, self.requiredEffects - 1 do
        local _a = i * dAngle + minAngle
        print(_a / DEGREES)
        table.insert(lpos,
            {
                start = {x = x, z = z},
                finish = {x = x + math.cos(_a) * radius, z = z - math.sin(_a) * radius},
            })
    end

    local notags = GFGetPVPEnabled()
            and { "shadow", "playerghost", "INLIMBO", "NOCLICK", "FX" } 
            or { "player", "shadow", "playerghost", "INLIMBO", "NOCLICK", "FX" }

    local ents = TheSim:FindEntities(x, y, z, radius, nil, notags)
    if self.sector == 360 then
        for k, ent in pairs(ents) do
            local ex, ey, ez = ent.Transform:GetWorldPosition()
            --SpawnPrefab("shovel_dirt").Transform:SetPosition(ex, ey, ez)
            if ent.components.combat and doer.components.gfspellcaster:CheckFriendlyFire(ent) then
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
                if ent.components.combat and doer.components.gfspellcaster:CheckFriendlyFire(ent) then
                    ent.components.combat:GetAttacked(doer, damage, nil, "electric")
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
    --fxdummy.components.gfcrackledrawer:SetColour(self.lightningDrawerColour)
    
    fxdummy.components.gflightningdrawer:DoLightning(lpos)
    fxdummy.SoundEmitter:PlaySound("dontstarve/common/whip_small") 

    return true
end

local function AiCheck(self, inst)
    local target = inst.components.combat.target
    if target and not inst:IsNear(target, self.aiMinDist) then
        local x, y, z = inst.Transform:GetWorldPosition()
        local res = 
        {
            target = target,
            distance = self.aiMaxDist,
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

    --spell params
    self.damage = 50
    self.sector = 90

    --spell visual
    self.requiredEffects = 4
    self.lightningDrawerColour = nil

    --AI--
    self.aicheckfn = AiCheck
    self.aiMinDist = 3
    self.aiMaxDist = 12
end)

return Spell