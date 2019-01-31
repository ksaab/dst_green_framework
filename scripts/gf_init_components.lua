--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

local _G = GLOBAL
local SourceModifierList = _G.require("util/sourcemodifierlist")

AddReplicableComponent("gfspellcaster")
AddReplicableComponent("gfspellitem")
AddReplicableComponent("gfeffectable")
AddReplicableComponent("gfquestgiver")
AddReplicableComponent("gfquestdoer")

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

--Want to push an event to the weapon on attacks
--it allows to trigger an enchant script on throwable items
AddComponentPostInit("combat", function(self)
    local _oldGetAttacked = self.GetAttacked
    function self:GetAttacked(attacker, damage, weapon, stimuli)
        local notBloked = _oldGetAttacked(self, attacker, damage, weapon, stimuli)
        if notBloked and weapon ~= nil then
            weapon:PushEvent("gfonweaponhit", {attacker = attacker, target = self.inst, damage = damage, stimuli = stimuli})
        end

        return isBloked
    end

    function self:AttackWithMods(target, damage, weapon, damageType)
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

AddComponentPostInit( "health", function(self) 
    if not self.inst:HasTag("player") then return end

    self.healMultiplier = SourceModifierList(self.inst)
    local _oldDoDelta = self.DoDelta
    
    function self:DoDelta(amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
        if amount > 0 then
            amount = amount * self.healMultiplier:Get()
        end

        _oldDoDelta(self, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
    end
end)

local function tryconsume(self, v, amount)
    if v.components.stackable == nil then
        self:RemoveItem(v):Remove()
        return 1
    elseif v.components.stackable.stacksize > amount then
        v.components.stackable:SetStackSize(v.components.stackable.stacksize - amount)
        return amount
    else
        amount = v.components.stackable.stacksize
        self:RemoveItem(v, true):Remove()
        return amount
    end

    return 0
end

AddComponentPostInit("inventory", function(self) 
    function self:ConsumeItemsByFn(fn, amount)
        if amount == nil or amount <= 0 then
            return
        end

        for k = 1, self.maxslots do
            local v = self.itemslots[k]
            if v ~= nil and fn(v) then
                amount = amount - tryconsume(self, v, amount)
                if amount <= 0 then
                    return
                end
            end
        end

        if self.activeitem ~= nil and self.activeitem.prefab == item then
            amount = amount - tryconsume(self, self.activeitem, amount)
            if amount <= 0 then
                return
            end
        end
    
        local overflow = self:GetOverflowContainer()
        if overflow ~= nil then
            overflow:ConsumeItemsByFn(fn, amount)
        end
    end
end)

AddComponentPostInit("container", function(self) 
    function self:ConsumeItemsByFn(fn, amount)
        if amount <= 0 then
            return
        end

        for k, v in pairs(self.slots) do
            if fn(v) then
                amount = amount - tryconsume(self, v, amount)
                if amount <= 0 then
                    return
                end
            end
        end
    end
end)