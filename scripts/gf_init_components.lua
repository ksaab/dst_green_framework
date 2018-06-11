local gfFunctions = GLOBAL.require "gf_global_functions"

AddReplicableComponent("gfspellcaster")
AddReplicableComponent("gfspellitem")
AddReplicableComponent("gfeffectable")

--drink potions, or something else...
AddComponentPostInit("eater", function(self)
    self.canDrink = false
    self.onDrink = nil

	function self:Drink(brew, feeder) 
        if brew.components.gfdrinkable ~= nil then
            brew.components.gfdrinkable:OnDrunk(self.inst)

            if self.onDrink ~= nil then
                self:onDrink(brew)
            end

            self.inst:PushEvent("ondrink", { brew = brew, feeder = feeder })
        else
            return false
        end

		return true
	end
end)

--Want to push the event to weapon on attacks
--it allows to trigger the enchant script on throwable items
AddComponentPostInit("combat", function(self)
    local _oldGetAttacked = self.GetAttacked
    function self:GetAttacked(attacker, damage, weapon, stimuli)
        local notBloked = _oldGetAttacked(self, attacker, damage, weapon, stimuli)
        if notBloked and weapon ~= nil then
            weapon:PushEvent("gfonweaponhit", {attacker = attacker, target = self.inst, damage = damage, stimuli = stimuli})
        end

        return isBloked
    end

    function self:GetAttackedWithMods(target, damage, weapon, damageType)
		if not (target and target.components.combat and damage) then return end

		--local playermultiplier = target ~= nil and target:HasTag("player")
    	--local pvpmultiplier = playermultiplier and self.inst:HasTag("player") and self.pvp_damagemod or 1

		local damage = damage * self:GetDamageMods()

		target.components.combat:GetAttacked(self.inst, damage, weapon, damageType)
	end

	function self:GetDamageMods()
		return self.externaldamagemultipliers:Get()	* (self.damagemultiplier or 1)
	end
end)