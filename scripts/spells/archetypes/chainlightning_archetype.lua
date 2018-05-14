local GFSpell = require("gf_spell")

local function DoCast(self, doer, target, pos, spellData)
    if doer == nil or (target == nil and pos == nil) then return false end

    spellData = spellData or {}
    --the lightning can hit each entity only once
    --the lightning prefers entities with combat component 
    local function FindValidTarget(pos, range, affected)
        local noncombat = {}
        local notags = GFGetPVPEnabled()
            and { "shadow", "playerghost", "INLIMBO", "NOCLICK", "FX" } 
            or { "player", "shadow", "playerghost", "INLIMBO", "NOCLICK", "FX" }

        local ents = TheSim:FindEntities(pos.x, 0, pos.z, range, nil, notags)
        for k, v in pairs(ents) do
            if not (affected ~= nil and table.contains(affected, v)) then
                if v.components.combat ~= nil and not (v.components.health and v.components.health:IsDead()) then
                    if not (v:HasTag("bird") and v.sg and v.sg:HasStateTag("flight")) then
                        return v -- first valid entity with combat
                    end
                else
                    table.insert(noncombat, v) 
                end
            end
        end

        return noncombat[1] or nil --there aren't entities with combat
    end

    local function DoLightning(dummy, from, to)
        GFDebugPrint(string.format("Lightning from %s to %s", tostring(from), tostring(to)))
        local x, y, z = from.Transform:GetWorldPosition()
        local xt, yt, zt = to.Transform:GetWorldPosition()

        if to.components.burnable ~= nil and not to.components.burnable:IsBurning() then
            if to.components.fueled == nil and math.random() < self.burnChance then
                to.components.burnable:Ignite(true)
            end
        end

        if to.components.combat ~= nil 
            and dummy.doer ~= nil 
            and dummy.doer.components.combat ~= nil 
        then
            local spellpower =  dummy.sp or 1
            local cldamage = self.damage * spellpower
            --print("damage", cldamage)
            to.components.combat:GetAttacked(dummy.doer or dummy, cldamage, nil, "electric")
        end

        local fxdummy = SpawnPrefab("gf_lightning_dummy")
        fxdummy.Transform:SetPosition(x, y, z)
        if dummy.lightinigColour ~= nil then
            fxdummy.components.gflightningdrawer:SetColour(dummy.lightinigColour)
        end 

        local lpos = {}
        table.insert(lpos,
            {
                start = {x = x, z = z}, 
                finish = {x = xt, z = zt}
            })

        fxdummy.components.gflightningdrawer:DoLightning(lpos)
        --fxdummy.components.gflightningdrawer:DoLightning({x = x, z = z}, {x = xt, z = zt})
        fxdummy.SoundEmitter:PlaySound("dontstarve/common/whip_small") 
        SpawnPrefab("shock_fx").Transform:SetPosition(xt, yt, zt)
    end

    --if spell was casted on ground, then need to find a valid entity in small range
    if target == nil or not target:IsValid() then
        target = FindValidTarget(pos, 5)
    end

    local x, y, z = doer.Transform:GetWorldPosition()
    --local dummy = SpawnPrefab("gf_lightning_dummy")
    local dummy = SpawnPrefab("gf_local_dummy")
    dummy.Transform:SetPosition(x, y, z)
    --[[ if self.lightningDrawerColour ~= nil then
        dummy.components.gflightningdrawer:SetLightning(self.lightningDrawerColour)
    end ]]
    if self.lightningDrawerColour ~= nil then
        dummy.lightinigColour = self.lightningDrawerColour
    end

    --if target wasn't found, then just make a fx and return
    if target == nil then
        local fxdummy = SpawnPrefab("gf_lightning_dummy")
        fxdummy.Transform:SetPosition(x, y, z)
        if dummy.lightinigColour ~= nil then
            fxdummy.components.gflightningdrawer:SetColour(dummy.lightinigColour)
        end 

        --fxdummy.components.gflightningdrawer:DoLightning({x = x, z = z}, {x = pos.x, z = pos.z})
        local lpos = {}
        table.insert(lpos,
            {
                start = {x = x, z = z},
                finish = {x = pos.x, z = pos.z},
            })
        fxdummy.components.gflightningdrawer:DoLightning(lpos)
        fxdummy.SoundEmitter:PlaySound("dontstarve/common/whip_small") 
        SpawnPrefab("shock_fx").Transform:SetPosition(pos.x, 0, pos.z)

        return true
    end

    dummy.doer = doer
    dummy.sp = doer.components.gfspellcaster:GetSpellPower()
    DoLightning(dummy, doer, target)

    --the lightning can hit each entity only once and can't hit the caster
    local affected = {}
    table.insert(affected, doer)
    table.insert(affected, target)
    --Count of bounces
    local jumps = self.jumpCount
    --last pos for the lightning's bounce
    local lastpos = Vector3(target.Transform:GetWorldPosition())

    dummy._chltask = dummy:DoPeriodicTask(0.3, function(dummy, data)
        if data.jumps ~= 0 and dummy.doer and dummy.doer:IsValid() then
            local affected = data.affected
            --previous target is the last element
            local prev = affected[#affected]
            --but if it is not valid then we need to spawn a dummy
            --at the previous target's position
            if prev == nil or not prev:IsValid() then
                prev = SpawnPrefab("gf_local_dummy")
                prev.Transform:SetPosition(lastpos.x, 0, lastpos.z)
            end
            --looking for the next target for bounce
            local newtarget = FindValidTarget(lastpos, 20, affected)
            --stop the task, if there are no valid targets
            if newtarget == nil then 
                dummy._chltask:Cancel()
                return
            end

            DoLightning(dummy, prev, newtarget)
            --add new traget to affected
            table.insert(affected, newtarget)
            data.jumps = data.jumps - 1
            data.lastpos = Vector3(newtarget.Transform:GetWorldPosition())
        else
            dummy._chltask:Cancel()
        end
    end, nil, {affected = affected, jumps = jumps, lastpos = lastpos})

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

    self.playerState = "gfcastwithstaff"
    self.pointer = nil
    self.instant = false

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

    --spell functions
    self.spellfn = DoCast 

    --spell parameters
    self.burnChance = 0
    self.damage = 50
    self.jumpCount = 3

    --visual
    self.lightningDrawerColour = nil --lightning colour

    --AI--
    self.aicheckfn = AiCheck
    self.aiMinDist = 3
    self.aiMaxDist = 12
end)

return Spell