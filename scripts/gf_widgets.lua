local require = GLOBAL.require
local TheInput = GLOBAL.TheInput
local ACTIONS = GLOBAL.ACTIONS
local spellList = GLOBAL.GFSpellList
local STRINGS = GLOBAL.STRINGS

local defaultLMBAction = STRINGS.GF.DEFAULTACTIONACTION
local defaultRMBAction = STRINGS.GF.DEFAULTALTACTIONACTION

--icons for effects
AddClassPostConstruct( "widgets/controls", function(self)
	GLOBAL.TheWorld:ListenForEvent( "playerentered", function( inst, ownr )
        if ownr == nil or ownr ~= GLOBAL.GFGetPlayer() then return end
        --positive effects panel
		local BuffPanel = require "widgets/gf_buffpanel"
		self.gf_buffPanel = self.bottom_root:AddChild( BuffPanel(ownr) )
        self.gf_buffPanel:SetPosition(-450, 150, 0)
        --negative effects panel
        local DebuffPanel = require "widgets/gf_debuffpanel"
		self.gf_debuffPanel = self.bottom_root:AddChild( DebuffPanel(ownr) )
		self.gf_debuffPanel:SetPosition(450, 150, 0)
		--spellbuttons
		local SpellPanel = require "widgets/gf_spellpanel"
		self.gf_spellPanel = self.bottom_root:AddChild( SpellPanel(ownr) )
		--need to update all effect-hud functions
		if ownr.replica.gfeffectable then
			for k, v in pairs(ownr.replica.gfeffectable.effects) do
				if v.hudonapplyfn then
					v:hudonapplyfn(ownr)
				end
			end
		end

		local _oldShowCraftingAndInventory = self.ShowCraftingAndInventory
		function self:ShowCraftingAndInventory()
			_oldShowCraftingAndInventory(self)
			if self.gf_spellPanel ~= nil and self.gf_spellPanel.spellCount > 0 then
				self.gf_spellPanel:Show()
			end
		end

		local _oldHideCraftingAndInventory = self.HideCraftingAndInventory
		function self:HideCraftingAndInventory()
			_oldHideCraftingAndInventory(self)
			if self.gf_spellPanel ~= nil then
				self.gf_spellPanel:Hide()
			end
		end
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

local function PostControls(self)
	local _oldOnUpdate = self.OnUpdate
	
	function self:OnUpdate(dt)
		_oldOnUpdate(self, dt)
		if TheInput:ControllerAttached() 
			and self.owner.components.gfspellpointer 
			and not (self.inv.open or self.crafttabs.controllercraftingopen) 
			and self.owner:IsActionsVisible()
		then
			local controller_id = TheInput:GetControllerID()
			if self.owner.components.playercontroller 
				and self.owner.components.playercontroller.gfSpellPointerEnabled
			then
				local pointer = self.owner.components.gfspellpointer.pointer
				if pointer == nil then 
					self.groundactionhint:Hide()
					self.playeractionhint:Hide()
					return 
				end
				local actTarget = self.owner
				local offset = -40

				if not pointer.isArrow then
					if pointer.pointer then
						actTarget = pointer.pointer
					elseif pointer.targetEntity ~= nil then
						actTarget = pointer.targetEntity
						offset = 0
					end
				end

				local lmb = self.owner.components.playeractionpicker:GetLeftClickActions(pointer.entity, pointer.position)[1]
				local rmb = self.owner.components.playeractionpicker:GetRightClickActions(pointer.entity, pointer.position)[1]
				if lmb and lmb.action == ACTIONS.GFCASTSPELL then
					self.playeractionhint:Show()
					self.playeractionhint:SetTarget(actTarget)
					self.playeractionhint:SetScreenOffset(0, offset)
					self.playeractionhint.text:SetString(TheInput:GetLocalizedControl(controller_id, GLOBAL.CONTROL_CONTROLLER_ACTION) 
						.. " "
						.. (lmb and lmb:GetActionString() or defaultLMBAction))
				end

				if rmb and rmb.action == ACTIONS.GFSTOPSPELLTARGETING then
					self.groundactionhint:Show()
					self.groundactionhint:SetTarget(self.owner)
					self.groundactionhint.text:SetString(TheInput:GetLocalizedControl(controller_id, GLOBAL.CONTROL_CONTROLLER_ALTACTION) 
						.. " "
						.. (rmb and rmb:GetActionString() or defaultRMBAction))
				end
				
			end
		end
	end
end

AddClassPostConstruct("widgets/controls", PostControls)