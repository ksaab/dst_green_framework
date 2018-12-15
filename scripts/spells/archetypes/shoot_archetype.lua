--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

local GFSpell = require("gf_class_spell")

--pointer params:
--[[-------------------------
pointerPrefab = "reticuleaoe", --prefab
isArrow = false, --if false follows the cursor, if true is bound to the caster and turns to the cursor
needTarget = false, --set to true if the spell that requires a target
prefersTarget = true, --if true targets entity under cursor (mouse) or search for a target in front of the player (gamepad)
range = 8, --range for a gamepad, do not change it without need
maxRange = 8, --range for a gamepad, do not change it without need
validColour = { 0, 1, 0.3, 0.3 },
invalidColour = { 1, 0, 0, 0.3 },
noTargetColour = { 1, 0, 0, 0.3 },
]]---------------------------

local function OnShotReachTarget(self, proj, victim)
    local params = self.spellParams
    if params.projOnDone ~= nil then
        params.projOnDone(proj, victim)
    end

    if proj._shotDone ~= nil then
        proj._shotDone:Cancel()
        proj._shotDone = nil
    end
    if proj._victimSearch ~= nil then
        proj._victimSearch:Cancel()
        proj._victimSearch = nil
    end
    proj:Remove()
end

local function DoCast(self, doer, target, position, item)
    if doer == nil or position == nil then return false end

    local params = self.spellParams
    if params.requiresAmmo then
        local ammo = params.ammoPrefab
        local amount = params.ammoPerShot

        local items = doer.components.inventory:ReferenceAllItems()

        for k, v in pairs(items) do
            if v.prefab == ammo then
                local stc = v.components.stackable
                if stc then
                    local stsz = stc.stacksize
                    if stsz > amount then
                        v = stc:Get(amount)
                    end
                    amount = amount - stsz
                else
                    amount = amount - 1
                end

                v:Remove()
                if amount <= 0 then break end
            end
        end
    end
    
    local proj = SpawnPrefab(params.projPrefab)
    if proj ~= nil then 
        local x, y, z = doer.Transform:GetWorldPosition()
        local angle = math.atan2(position.x - x, position.z - z) - 1.5707
        local cos = math.cos(angle)
        local sin = math.sin(angle)
        proj.Transform:SetPosition(x + cos * 2.5, 0, z - sin * 2.5)
        proj.Transform:SetRotation(angle / DEGREES)
        proj.Physics:SetMotorVel(25, 0, 0)
        proj.shooter = doer

        if params.projPenetrate then
            proj.victims = {}
            if params.projOnHit ~= nil then
                proj._victimSearch = proj:DoPeriodicTask(0.1, function()
                    local x, y, z = proj.Transform:GetWorldPosition()
                    for k, v in pairs (TheSim:FindEntities(x, y, z, 3, {"_combat"}, { "playerghost", "shadow", "INLIMBO", "FX", "NOCLICK" })) do
                        if v ~= proj.shooter
                            and v.components.combat ~= nil 
                            and not table.contains(proj.victims, v)
                            and proj:GetDistanceSqToInst(v) <= v:GetPhysicsRadius(0) * v:GetPhysicsRadius(0) + 0.8
                            and v:IsValid()
                        then
                            params.projOnHit(proj, v)
                            table.insert(proj.victims, v)
                        end
                    end
                end)
            end
        else
            proj._victimSearch = proj:DoPeriodicTask(0.1, function()
                local victim
                local x, y, z = proj.Transform:GetWorldPosition()
                for k, v in pairs (TheSim:FindEntities(x, y, z, 3, {"_combat"}, { "playerghost", "shadow", "INLIMBO", "FX", "NOCLICK" })) do
                    if v.components.combat ~= nil 
                        and v ~= proj.shooter
                        and proj:GetDistanceSqToInst(v) <= v:GetPhysicsRadius(0) * v:GetPhysicsRadius(0) + 0.8
                        and v:IsValid()
                    then
                        victim = v
                        break
                    end
                end
                if victim ~= nil then
                    OnShotReachTarget(self, proj, victim)
                end
            end)
        end

        proj._shotDone = proj:DoTaskInTime(params.projTTL, function() OnShotReachTarget(self, proj) end)
    end

    return true
end

local function CheckAmmo(self, inst)
    if not self.spellParams.requiresAmmo then return true end
    if inst.replica.inventory and inst.replica.inventory:Has(self.spellParams.ammoPrefab, self.spellParams.ammoPerShot) then 
        return true 
    else
        return "NOAMMO"
    end
end

local Spell = Class(GFSpell, function(self)
    GFSpell._ctor(self, "shoot_archetype")  --set the "phantom" name, which will be used ONLY in the gf_spell constuctor, 
                                            --real spell name will math the file name
    --both side
    self.title = STRINGS.GF.SPELLS.SHOOT.TITLE --a title for the hoverer widget
    self.actionFlag = "SHOOT"

    self.range = math.huge --cast range
    self.instant = false --can be casted by one click or not
    self.passive = false --if true, spell can not be casted by players or creatures, but can be casted with gfspellcaster:CastSpell()

    self.pointer = nil

    self.preCastCheckFn = CheckAmmo
    self.tags = {} --not sure should this be server only or not
    
    self.spellParams =
    {
        requiresAmmo = false,
        ammoPrefab = "stinger",
        ammoPerShot = 1,
        projPenetrate = false,
        projPrefab = "stinger",
        projTTL = 0.5,
        projOnHit = nil,
        projOnDone = nil,
    }
    self.playerState = "gftdartshoot"

    self.itemRecharge = 2 --can't cast the spell with item
    self.doerRecharge = 0 --caster can't cast the spell (even if he equips an another item with the same spell)

    self.getRechargefn = nil    --if recharge values are non-static (ex: shorter at the night). 
                                --It must return 2 values (doerRecharge, itemRecharge)

    self.spellfn = DoCast   --spell logic, the main thing here
                                --args (self, caster, target, pos)
    self.aicheckfn = nil    --AI call this fn from the brain
                            --args (self, caster)
end)

return Spell