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
		--[[ if GLOBAL.GFGetIsMasterSim() then
			if ownr.components.gfspellcaster then
				ownr.components.gfspellcaster:ForceUpdateReplicaHUD()
			end
		end ]]
		
	end)
end)

--it's not good, but no idae how to make it better
local function PostHoverer(self, anim, owner)
	require("constants")
	local Text = require "widgets/text"

	self._prevEntity = nil
	--text fields
	self.abilitiesString = self:AddChild(Text(GLOBAL.UIFONT, 18, nil, {105/255, 175/255, 234/255, 1}))
	self.spellString = self:AddChild(Text(GLOBAL.UIFONT, 18, nil, {50/255, 205/255, 50/255, 1}))
	self.positiveString = self:AddChild(Text(GLOBAL.UIFONT, 15, nil, {229/255, 216/255, 105/255, 1}))
	self.negativeString = self:AddChild(Text(GLOBAL.UIFONT, 15, nil, {104/255, 82/255, 128/255, 1}))

	--text fields positions
	self.abilitiesString:SetPosition(0, 65, 0)
	self.spellString:SetPosition(0, 18, 0)
	self.positiveString:SetPosition(0, 18, 0) -- -1
	self.negativeString:SetPosition(0, 3, 0) -- -16

	self.lasttimeinvUpdate = 0
	self.lasttimeEffectsUpdate = 0

	self._OnUpdate = self.OnUpdate
	self.OnUpdate  = function(dt)
		self:_OnUpdate(dt)
		if not self.shown then return end

		local affoff = 0
		local buffoff = 0
		local invoff = 0
		local obj = GLOBAL.TheInput:GetWorldEntityUnderMouse()

		if obj == nil then
			if self.owner.HUD 
				and self.owner.HUD.controls.inv 
				and self.owner.HUD.controls.inv.focus 
			then 
				local hudTable = {self.owner.HUD.controls.inv.equip, self.owner.HUD.controls.inv.inv}
				for _, hudElem in pairs(hudTable) do
					if hudElem ~= nil then
						for k, v in pairs(hudElem) do
							if v.focus then
								if v.tile ~= nil then
									obj = v.tile.item
									affoff = affoff + 20
									invoff = -20
								end
	
								break
							end
						end
					end
				end
			end
		end

		if obj and (obj.replica.gfeffectable or obj.replica.gfspellitem) then
			if obj ~= self._prevEntity or GLOBAL.GetTime() - self.lasttimeEffectsUpdate > 1 then
				local posstr, negstr, affstr, encstr, ispellstr
				if obj.replica.gfeffectable then
					local scei = obj.replica.gfeffectable.hudInfo
					posstr = scei.positiveString
					negstr = scei.negativeString
					affstr = scei.affixString
					encstr = scei.enchantString
				end
				if obj.replica.gfspellitem then
					ispellstr = obj.replica.gfspellitem:GetItemSpellTitle()
				end
				if ispellstr then
					self.spellString:SetString(ispellstr)
					self.spellString:SetPosition(0, 18 + invoff, 0)
					invoff = -18 + invoff
				else
					self.spellString:SetString("")
				end
				if posstr then
					self.positiveString:SetString(posstr)
					self.positiveString:SetPosition(0, 18 + invoff, 0)
					self.negativeString:SetPosition(0, 3 + invoff, 0)
				else
					self.positiveString:SetString("")
					self.negativeString:SetPosition(0, 18 + invoff, 0)
				end
				self.negativeString:SetString(negstr or "")
				if affstr or encstr then
					self.abilitiesString:SetPosition(0, 65 + affoff, 0)
					self.abilitiesString:SetString(string.format("%s%s", affstr or "", encstr or ""))
				else
					self.abilitiesString:SetString("")
				end
				
			end
		else
			self.abilitiesString:SetString("")
			self.spellString:SetString("")
			self.positiveString:SetString("")
			self.negativeString:SetString("")
		end
	end
end

--titles for effects and spells
AddClassPostConstruct("widgets/hoverer", PostHoverer)