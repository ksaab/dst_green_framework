local GFSpell = require("gf_spell")

local function DoCast(self, doer, target, pos, spellData)
    if doer == nil or target == nil then return false end

    local params = self.spellParams
    local visuals = self.spellVisuals

    if target.components.gfeffectable ~= nil then
        target.components.gfeffectable:ApplyEffect(params.effect,
        {
            applier = doer,
            stacks = params.stacks,
            duration = params.duration,
        }
    )
    end

    if target.SoundEmitter and visuals.castSound then target.SoundEmitter:PlaySound(visuals.castSound) end

    return true
end

local function AiCheck(self, inst)
    if math.random() <= 0.15 then return false end --this prevents casts from different sources to one target... almost prevents

    local target
    local aiparams = self.aiParams
    if self.spellParams.isPositive then
        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, self.range, {"_combat", "_health"}, {"FX", "NOCLICK", "shadow", "playerghost", "INLIMBO"})
        for k, ent in pairs(ents) do
            if inst.components.gfspellcaster:IsTargetFriendly(ent) then
                if aiparams.customCheck ~= nil then
                    if aiparams:customCheck(inst, ent) then
                        target = ent
                        break
                    end
                else
                    target = ent
                    break
                end
            end
        end
    else
        local combatTarget = inst.components.combat.target
        if combatTarget and not inst:IsNear(combatTarget, aiparams.minDist) and combatTarget:IsValid() then
            target = combatTarget
        end
    end

    if target then
        local res = 
        {
            target = target,
            distance = aiparams.maxDist,
        }

        return res
    end

    return false
end

local Spell = Class(GFSpell, function(self, name)
    GFSpell._ctor(self, name) --inheritance

    self.pointer = nil
    self.needTarget = true

    self.tags = {
        magic = true,
    }

    if not GFGetIsMasterSim() then 
        return 
    end
    
    --spell cooldowns
    self.itemRecharge = 0
    self.doerRecharge = 20

    --spell params
    self.spellParams = 
    {
        isPositive = true,
        effect = nil,
        stacks = nil,
        duration = nil,
    }

    self.spellVisuals =
    {
        castSound = nil,
    }

    --spell fns
    self.spellfn = DoCast 

    --AI--
    self.aicheckfn = AiCheck
    self.aiParams = 
    {
        customCheck = nil,
        minDist = 3,
        maxDist = self.range,
    }
end)

return Spell