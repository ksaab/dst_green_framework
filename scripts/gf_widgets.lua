local _G = GLOBAL
local require = _G.require
local TheInput = _G.TheInput
local ACTIONS = _G.ACTIONS
local spellList = _G.GFSpellList
local STRINGS = _G.STRINGS

local defaultLMBAction = STRINGS.GF.HUD.CONTROLLER_DEFAULTS.LMB
local defaultRMBAction = STRINGS.GF.HUD.CONTROLLER_DEFAULTS.RMB

--icons for effects
AddClassPostConstruct( "widgets/controls", function(self)
	print("Init widgets for", self.owner)

	--[[init new widgets]]
	local owner = self.owner
	if owner == nil or owner ~= _G.GFGetPlayer() then return end
	local EffectsPanel = require "widgets/gf_effects_panel"
	self.gf_buffPanel = self.bottom_root:AddChild( EffectsPanel(owner) )
	self.gf_buffPanel:SetPanel(-450, 150, true, 65)

	self.gf_debuffPanel = self.bottom_root:AddChild( EffectsPanel(owner) )
	self.gf_debuffPanel:SetPanel(450, 150, false, -65)
	--positive effects panel
	--local BuffPanel = require "widgets/gf_buffpanel"
	--self.gf_buffPanel = self.bottom_root:AddChild( BuffPanel(owner) )
	--self.gf_buffPanel:SetPosition(-450, 150, 0)
	--negative effects panel
	--local DebuffPanel = require "widgets/gf_debuffpanel"
	--self.gf_debuffPanel = self.bottom_root:AddChild( DebuffPanel(owner) )
	--self.gf_debuffPanel:SetPosition(450, 150, 0)
	--spell panel
	local SpellPanel = require "widgets/gf_spellpanel"
	self.gf_spellPanel = self.bottom_root:AddChild( SpellPanel(owner) )
	--quest dialog
	local QuestDialog = require "widgets/gf_questdialog"
	self.gf_questDialog = self:AddChild( QuestDialog(owner) )
	--quest informer
	local QuestInformer = require "widgets/gf_questinformer"
	self.gf_questInformer = self.top_root:AddChild( QuestInformer(owner) ) 
	--journal button
	--local JournalButton = require "widgets/gf_journalbutton"
	--self.mapcontrols.gf_questInformer = self.mapcontrols:AddChild( JournalButton(owner) )

	local ImageButton = require "widgets/imagebutton"
	local PopJournal = require "screens/gf_questjournal"
	self.mapcontrols.gf_journalbutton = self.mapcontrols:AddChild(ImageButton("images/gfquestjournal.xml", "journalbutton.tex", "journalbutton.tex", nil, nil, nil, {1,1}, {0,0}))
	self.mapcontrols.gf_journalbutton:SetOnClick(function() _G.TheFrontEnd:PushScreen(PopJournal(self.owner)) end)
	self.mapcontrols.gf_journalbutton:SetScale(0.8)
	self.mapcontrols.gf_journalbutton:SetPosition(0, 80)
	self.mapcontrols.gf_journalbutton:SetTooltip(STRINGS.GF.HUD.JOURNAL.BUTTONS.OPEN_JOURNAL)
	--updating effects hud data
	--[[ if owner.replica.gfeffectable then
		print("Effectable replica exists, updating hud effects on", owner)
		for k, v in pairs(owner.replica.gfeffectable.effects) do
			if v.hudonapplyfn then
				v:hudonapplyfn(owner)
			end
		end
	else
		print(owner, "doesn't have the effectable relpica...")
	end ]]

	local PanelOne = require "widgets/gf_effects_panel"
	self.PanelOne = self.bottom_root:AddChild( PanelOne(owner) )
	self.PanelOne:SetPanel(-450, 150, true, 65)

	self.PanelTwo = self.bottom_root:AddChild( PanelOne(owner) )
	self.PanelTwo:SetPanel(450, 150, false, -65)

	--[[show/hide spell panel]]
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
--[[ 
	local PopJournal = require "screens/gf_questjournal"
	owner:ListenForEvent("gfpushjournal", function(owner)
		_G.TheFrontEnd:PushScreen(PopJournal(owner))
	end) ]]
end)

require("constants")
local Text = require "widgets/text"

--it's not good, but no idea how to make it better
local function PostHoverer(self, anim, owner)
	self._prevEntity = nil
	--text fields
	self.abilitiesString = self:AddChild(Text(_G.UIFONT, 18, nil, {105/255, 175/255, 234/255, 1}))
	self.enchantString = self:AddChild(Text(_G.UIFONT, 20, nil, {50/255, 205/255, 50/255, 1}))
	self.spellString = self:AddChild(Text(_G.UIFONT, 18, nil, {50/255, 205/255, 50/255, 1}))
	self.positiveString = self:AddChild(Text(_G.UIFONT, 15, nil, {229/255, 216/255, 105/255, 1}))
	self.negativeString = self:AddChild(Text(_G.UIFONT, 15, nil, {104/255, 82/255, 128/255, 1}))

	--text fields positions
	self.abilitiesString:SetPosition(0, 65, 0)
	self.enchantString:SetPosition(0, 65, 0)
	self.spellString:SetPosition(0, 18, 0)
	self.positiveString:SetPosition(0, 18, 0) -- -1
	self.negativeString:SetPosition(0, 3, 0) -- -16

	self.lasttimeinvUpdate = 0
	self.lasttimeEffectsUpdate = 0

	local _oldOnUpdate = self.OnUpdate
	self.OnUpdate  = function(dt)
		_oldOnUpdate(self, dt)
		if not self.shown and not self.owner:HasTag("playerghost") then return end

		local affoff = 0
		local buffoff = 0
		local invoff = 0
		local obj = _G.TheInput:GetWorldEntityUnderMouse()

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
			if obj ~= self._prevEntity or _G.GetTime() - self.lasttimeEffectsUpdate > 1 then
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
				if affstr then -- or encstr 
					self.abilitiesString:SetPosition(0, 65 + affoff, 0)
					self.abilitiesString:SetString(string.format("%s", affstr))
					affoff = affoff + 20
				else
					self.abilitiesString:SetString("")
				end
				if encstr then -- or encstr 
					self.enchantString:SetPosition(0, 65 + affoff, 0)
					self.enchantString:SetString(string.format("%s", encstr))
				else
					self.enchantString:SetString("")
				end
				
			end
		else
			self.abilitiesString:SetString("")
			self.enchantString:SetString("")
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
					self.playeractionhint.text:SetString(TheInput:GetLocalizedControl(controller_id, _G.CONTROL_CONTROLLER_ACTION) 
						.. " "
						.. (lmb and lmb:GetActionString() or defaultLMBAction))
				end

				if rmb and rmb.action == ACTIONS.GFSTOPSPELLTARGETING then
					self.groundactionhint:Show()
					self.groundactionhint:SetTarget(self.owner)
					self.groundactionhint.text:SetString(TheInput:GetLocalizedControl(controller_id, _G.CONTROL_CONTROLLER_ALTACTION) 
						.. " "
						.. (rmb and rmb:GetActionString() or defaultRMBAction))
				end
				
			end
		end
	end
end

AddClassPostConstruct("widgets/controls", PostControls)