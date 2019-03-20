local _G = GLOBAL
local require = _G.require
local TheInput = _G.TheInput
local ACTIONS = _G.ACTIONS
local ALL_SPELLS = _G.GF.GetSpells()
local STRINGS = _G.STRINGS

local defaultLMBAction = STRINGS.GF.HUD.CONTROLLER_DEFAULTS.LMB
local defaultRMBAction = STRINGS.GF.HUD.CONTROLLER_DEFAULTS.RMB

require("constants")

--screens
local PopJournal = require "screens/gf_questjournal"
local PopShop = require "screens/gf_shop"

--widgets
local Widget = require "widgets/widget"
local EffectsPanel = require "widgets/gf_effects_panel"
local SpellPanel = require "widgets/gf_spellpanel"
local ConversationDialog = require "widgets/gf_conversation_dialog"
local ShopDialog = require "widgets/gf_shop_dialog"
local QuestInformer = require "widgets/gf_questinformer"
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text"

--[[NEW WIDGETS AND SCREENS]]-----------
----------------------------------------
AddClassPostConstruct( "widgets/controls", function(self)
	print("Init widgets for", self.owner)

	local owner = self.owner
	if owner == nil or owner ~= _G.GFGetPlayer() then return end --not sure about his check
	
	--buff and debuff panel - shows positive and negative status effects
	self.gfBuffPanel = self.bottom_root:AddChild(EffectsPanel(owner))
	self.gfBuffPanel:SetPanel(-450, 150, true, 65)
	self.gfDebuffPanel = self.bottom_root:AddChild(EffectsPanel(owner))
	self.gfDebuffPanel:SetPanel(450, 150, false, -65)

	--spell panel - allows to cast spell which are added to the player entity
	self.inv.gfSpellPanel = self.inv:AddChild(SpellPanel(owner))
	self.gfSpellPanel = self.inv.gfSpellPanel

	--conversation dialog
	self.gfConversationDialog = self:AddChild(ConversationDialog(owner))
	--self.gfConversationDialog.shopDialog = self:AddChild(ShopDialog(owner))

	--text string that shows any info about quests
	self.gfQuestInformer = self.top_root:AddChild(QuestInformer(owner)) 

	--journal button
	self.mapcontrols.gfJournalButton = self.mapcontrols:AddChild(ImageButton("images/gfquestjournal.xml", "journalbutton.tex", "journalbutton.tex", nil, nil, nil, {1,1}, {0,0}))
	self.mapcontrols.gfJournalButton:SetOnClick(function() _G.TheFrontEnd:PushScreen(PopJournal(self.owner)) end)
	self.mapcontrols.gfJournalButton:SetScale(0.8)
	self.mapcontrols.gfJournalButton:SetPosition(0, 80)
	self.mapcontrols.gfJournalButton:SetTooltip(STRINGS.GF.HUD.JOURNAL.BUTTONS.OPEN_JOURNAL)
end)

--[[HOVERER]]-------------------------------
--hints for spells and status effects-------
local function PostHoverer(self, anim, owner)
	--it's not good, but no idea how to make it better
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
				--select an item in the inventory (from the hovered item tile)
				--may there is a beeter way to do this, but I don't know it
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

		--defining strings
		--obj should be a correct entity
		if obj and (obj.replica.gfeffectable or obj.replica.gfspellitem) then
			--if object hasn't changed since the last frame don't need to update it often than one time per second
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

AddClassPostConstruct("widgets/hoverer", PostHoverer)

--[[CONTROLLER HINTS]]---------------------------------
--update hints for spell casting and spell panel-------
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
			if self.owner.HUD:IsSpellSelectionEnabled() or self.owner.HUD:IsInConversation() then
				--spell selection from the spell panel
				self.groundactionhint:Hide()
				self.playeractionhint:Hide()
				--hint will be shown in the spell panel widget
				--self.playeractionhint:Show()
				--self.playeractionhint:SetTarget(self.owner)
				--self.playeractionhint.text:SetString(TheInput:GetLocalizedControl(controller_id, _G.CONTROL_CONTROLLER_ACTION) .. " Choose spell") 

				--self.groundactionhint:Show()
				--self.groundactionhint:SetTarget(self.owner)
				--self.groundactionhint:SetScreenOffset(0, -40)
				--self.groundactionhint.text:SetString(TheInput:GetLocalizedControl(controller_id, _G.CONTROL_CONTROLLER_ALTACTION) .. " Cancel") 
			elseif self.owner.components.playercontroller ~= nil
				and self.owner.components.playercontroller:IsSpellPointerEnabled() 
			then
				--cast current spell
				local pointer = self.owner.components.gfspellpointer.pointer
				if pointer == nil then 
					self.groundactionhint:Hide()
					self.playeractionhint:Hide()
					return 
				end

				local actTarget = self.owner
				local offset = 0

				if not pointer.isArrow then
					offset = -40
					if pointer.pointer then
						actTarget = pointer.pointer
					elseif pointer.targetEntity ~= nil then
						actTarget = pointer.targetEntity
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

--[[INVENTORY BAR]]-------------------------
--spell panel position and navigation-------
local function PostInv(self)
	local _oldCursorRight = self.CursorRight
	local _oldCursorLeft = self.CursorLeft
	local _oldCursorUp = self.CursorUp
	local _oldCursorDown = self.CursorDown
	local _oldRebuild = self.Rebuild
	local _oldUpdateCursor = self.UpdateCursor

	function self:CursorRight(...)
		--block the inventory navigation if player is selecting a spell
		local hud = self.owner.HUD
		local pc = self.owner.components.playercontroller
		if (hud ~= nil and hud:IsControllerCraftingOpen())
			or not ((hud:IsSpellSelectionEnabled() or hud:IsInConversation())
				or (pc ~= nil and pc:IsSpellPointerEnabled()))
		then
			_oldCursorRight(self, ...)
		end
	end

	function self:CursorLeft(...)
		--block the inventory navigation if player is selecting a spell
		local hud = self.owner.HUD
		local pc = self.owner.components.playercontroller
		if (hud ~= nil and hud:IsControllerCraftingOpen())
			or not ((hud:IsSpellSelectionEnabled() or hud:IsInConversation())
				or (pc ~= nil and pc:IsSpellPointerEnabled()))
		then
			_oldCursorLeft(self, ...)
		end
	end

	function self:CursorUp(...)
		--block the inventory navigation if player is selecting a spell
		local hud = self.owner.HUD
		local pc = self.owner.components.playercontroller
		if (hud ~= nil and hud:IsControllerCraftingOpen())
			or not ((hud:IsSpellSelectionEnabled() or hud:IsInConversation())
				or (pc ~= nil and pc:IsSpellPointerEnabled()))
		then
			_oldCursorUp(self, ...)
		end
	end

	function self:CursorDown(...)
		--block the inventory navigation if player is selecting a spell
		local hud = self.owner.HUD
		local pc = self.owner.components.playercontroller
		if (hud ~= nil and hud:IsControllerCraftingOpen())
			or not ((hud:IsSpellSelectionEnabled() or hud:IsInConversation())
				or (pc ~= nil and pc:IsSpellPointerEnabled()))
		then
			_oldCursorDown(self, ...)
		end
	end

	function self:Rebuild(...)
		--spell panel is binded to the inventory bar
		--need to update its position if inventory was rebuilded
		--TODO - make this more flexible
		_oldRebuild(self, ...)
		if self.gfSpellPanel ~= nil and self.bg ~= nil then
			local x, y = self.bg:GetSize()
			local scale = self.bg:GetScale()
			local ypos = 245
			if self.toprow ~= nil then
				local bpos = self.toprow:GetPosition()
				if bpos.y ~= 0 then ypos = 350 end
			end
			local pos = self.bg:GetPosition()
			self.gfSpellPanel:SetPosition(-(170 * scale.x) - (x * scale.x) / 2, ypos * scale.y)
			self.gfSpellPanel:MoveToBack()
		end
	end

	function self:UpdateCursor()
		if self.owner.HUD == nil or not self.owner.HUD:IsSpellSelectionEnabled() then
			_oldUpdateCursor(self)
		else
			--need to hide the inventory hint during the spell selection
			--spell panel has its own hint
			self.actionstringbody:SetString("")
			self.actionstring:Hide()

			if self.cursor ~= nil then self.cursor:Hide() end
			if self.cursortile ~= nil then 
				self.cursortile:Kill() 
				self.cursortile = nil	
			end
		end
	end
end

AddClassPostConstruct("widgets/inventorybar", PostInv)