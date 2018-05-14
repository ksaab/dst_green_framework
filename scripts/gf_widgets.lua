local require = GLOBAL.require

--icons for effects
AddClassPostConstruct( "widgets/controls", function(self)
	GLOBAL.TheWorld:ListenForEvent( "playerentered", function( inst, ownr )
        if ownr == nil or ownr ~= GLOBAL.ThePlayer then return end
        --positive effects panel
		local BuffPanel = require "widgets/buffpanel"
		self.buffPanel = self.bottom_root:AddChild( BuffPanel(ownr) )
        self.buffPanel:SetPosition(-450, 150, 0)
        --negative effects panel
        local DebuffPanel = require "widgets/debuffpanel"
		self.debuffPanel = self.bottom_root:AddChild( DebuffPanel(ownr) )
        self.debuffPanel:SetPosition(450, 150, 0)

		--need to update all effect-hud functions
		if ownr.replica.gfeffectable then
			for k, v in pairs(ownr.replica.gfeffectable.effects) do
				if v.hudonapplyfn then
					v:hudonapplyfn(ownr)
				end
			end
		end
		
	end)
end)

local function PostHoverer(self, anim, owner)
	require("constants")
	local Text = require "widgets/text"

	self._prevEntity = nil
	self.abilitiesString = self:AddChild(Text(GLOBAL.UIFONT, 18, nil, {105/255, 175/255, 234/255, 1}))
	self.spellString = self:AddChild(Text(GLOBAL.UIFONT, 15, nil, {229/255, 216/255, 105/255, 1}))
	self.positiveString = self:AddChild(Text(GLOBAL.UIFONT, 15, nil, {229/255, 216/255, 105/255, 1}))
	self.negativeString = self:AddChild(Text(GLOBAL.UIFONT, 15, nil, {104/255, 82/255, 128/255, 1}))

	self.abilitiesString:SetPosition(0, 65, 0)
	self.spellString:SetPosition(0, 5, 0)
	self.positiveString:SetPosition(0, 20, 0)
	self.negativeString:SetPosition(0, 5, 0)

	self.lasttimeinvUpdate = 0
	self.lasttimeEffectsUpdate = 0

	self._OnUpdate = self.OnUpdate
	self.OnUpdate = function(dt)
		self:_OnUpdate(dt)
		local obj = GLOBAL.TheInput:GetWorldEntityUnderMouse()
		local affoff = 0
		local sistring
		if obj == nil then
			--print(self.owner.components.playercontroller:GetCursorInventoryObject())
			if self.owner.HUD 
				and self.owner.HUD.controls.inv 
				and self.owner.HUD.controls.inv.focus 
			then 
				if self.owner.HUD.controls.inv.inv then
					for k, v in pairs(self.owner.HUD.controls.inv.inv) do
						if v.focus then
							if v.tile ~= nil then
								obj = v.tile.item
								affoff = affoff + 20
								sistring = obj.replica.gfspellitem and obj.replica.gfspellitem:GetItemSpell() or nil
							end

							break
						end
					end
				end

				if self.owner.HUD.controls.inv.equip and obj == nil then
					for k, v in pairs(self.owner.HUD.controls.inv.equip) do
						if v.focus then
							if v.tile ~= nil then
								obj = v.tile.item
								affoff = affoff + 20
								sistring = obj.replica.gfspellitem and obj.replica.gfspellitem:GetItemSpell() or nil
							end

							break
						end
					end
				end
			end
		end
		if obj ~= nil  --[[and obj ~= ThePlayer]] then
			--print(obj)
			if obj ~= self._prevEntity or GLOBAL.GetTime() - self.lasttimeEffectsUpdate > 1 then
				if sistring then
					self.spellString:SetString(sistring)
				else
					self.spellString:SetString("")
				end
				if obj.replica and obj.replica.gfeffectable then
					local scei = obj.replica.gfeffectable.hudInfo
                    local posstr = scei.positiveString
                    local negstr = scei.negativeString
                    local affstr = scei.affixString
					local encstr = scei.enchantString
					
					if posstr:len() > 0 then
						self.positiveString:SetString(posstr)
						self.negativeString:SetPosition(0, 5, 0)
					else
						self.negativeString:SetPosition(0, 20, 0)
						self.positiveString:SetString("")
					end
					if negstr:len() > 0 then
						self.negativeString:SetString(negstr)
					--else
						--self.positiveString:SetPosition(0, 10, 0)
					end
					--if scei:GetAbilitiesCount() > 0 then
					if affstr:len() > 0 or encstr:len() > 0 then
						self.abilitiesString:SetPosition(0, 65 + affoff, 0)
						self.abilitiesString:SetString(string.format("%s %s", affstr, encstr))
					end
					--else
						--self.positiveString:SetPosition(0, 10, 0)
					--end
					
					self.lasttimeEffectsUpdate = GLOBAL.GetTime()
					self._prevEntity = obj

					return
				end
			else
				return
			end
		end

		self._prevEntity = nil
		
		self.abilitiesString:SetString("")
		--self.spellString:SetString("")
		self.positiveString:SetString("")
		self.negativeString:SetString("")
	end
end

--titles for effects
AddClassPostConstruct("widgets/hoverer", PostHoverer)