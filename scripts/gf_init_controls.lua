--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

local _G = GLOBAL
local ALL_SPELLS = _G.GF.GetSpells()
local TheInput = _G.TheInput
local PopJournal = _G.require "screens/gf_questjournal"

AddComponentPostInit("playeractionpicker", function(self)
    --need to hook actions if the spell pointer is enabled
    --left click should be "cast current spell"
    local _oldGetLeftClickActions = self.GetLeftClickActions
    function self:GetLeftClickActions(position, target)
        if self.inst.components.playercontroller:IsSpellPointerEnabled() then
            local lmb = self.inst.components.gfspellpointer:CollectLeftActions(position, target)
            return lmb or {}
        end

        return _oldGetLeftClickActions(self, position, target)
    end

    --need to hook actions if the spell pointer is enabled
    --right click should be "cancel spell targeting"
    local _oldGetRightClickActions = self.GetRightClickActions
    function self:GetRightClickActions(position, target)
        if self.inst.components.playercontroller:IsSpellPointerEnabled() then
            local rmb = self.inst.components.gfspellpointer:CollectRightActions(position, target)
            return rmb or {}
        end

        return _oldGetRightClickActions(self, position, target)
    end
end)

AddComponentPostInit("playercontroller", function(self)
    local ACTIONS = GLOBAL.ACTIONS
    local RPC = GLOBAL.RPC
    local BufferedAction = GLOBAL.BufferedAction
    local SendRPCToServer = GLOBAL.SendRPCToServer
    local CanEntitySeePoint = GLOBAL.CanEntitySeePoint

    self.gfSpellPointerEnabled = false --spell pointer is enabled

    function self:SetSpellPointer(val)
        self.gfSpellPointerEnabled = val 
    end

    function self:IsSpellPointerEnabled()
        return self.gfSpellPointerEnabled
    end

    --hook the action collector for controller if the spell pointer is enabled
    --"A" should be "cast current spell"; "B"should be "cancel spell targeting"
    local _oldGetGroundUseAction = self.GetGroundUseAction
    function self:GetGroundUseAction(position)
        if self:IsSpellPointerEnabled()
            and self:IsEnabled()
            and position ~= nil
            and CanEntitySeePoint(self.inst, position:Get())
        then
            return self.inst.components.gfspellpointer:GetControllerPointActions(position)
        end

        return _oldGetGroundUseAction(self, position)
    end

    --"B" button on xbox controller
    local _oldDoControllerAltActionButton = self.DoControllerAltActionButton
    function self:DoControllerAltActionButton()
        if self:IsSpellPointerEnabled() and self:IsEnabled() and not self:UsingMouse() then
            --cancel the spell targeting
            --this was written a log time ago, I don't remember details
            --TODO - check out this code
            local position = self.inst.components.gfspellpointer.pointer.targetPosition or Vector3(0, 0, 0)
            local act = self.inst.components.playeractionpicker:SortActionList({ ACTIONS.GFSTOPSPELLTARGETING }, position, nil)[1]
            if act ~= nil then
                if not self.ismastersim then
                    if self.locomotor == nil then
                        self.remote_controls[_G.CONTROL_CONTROLLER_ALTACTION] = 0
                        local isreleased = not TheInput:IsControlPressed(_G.CONTROL_CONTROLLER_ALTACTION)
                        SendRPCToServer(RPC.ControllerAltActionButton, act.action.code, self.inst, isreleased, nil, act.action.mod_name)
                    else
                        act.preview_cb = function()
                            self.remote_controls[_G.CONTROL_CONTROLLER_ALTACTION] = 0
                            local isreleased = not TheInput:IsControlPressed(_G.CONTROL_CONTROLLER_ALTACTION)
                            SendRPCToServer(RPC.ControllerAltActionButton, act.action.code, self.inst, isreleased, nil, act.action.mod_name)
                        end
                    end
                end

                self:DoAction(act)
                return
            end
        end
        
        _oldDoControllerAltActionButton(self)
    end

    --"A" button on xbox controller
    local _oldDoControllerActionButton = self.DoControllerActionButton
    function self:DoControllerActionButton()
        --bad hax - we can't do anything if the button is locked by the HUD
        if self.inst.HUD ~= nil and self.inst.HUD.gfLockActionButton then return end
        if self:IsSpellPointerEnabled() 
            and self:IsEnabled() 
            and not self:UsingMouse() 
        then
            --cast the current spell
            local gfsp = self.inst.components.gfspellpointer
            local sName = gfsp:GetCurrentSpell()

            if sName ~= nil then
                local pointer = gfsp.pointer
                local position = pointer.targetPosition
                local target = pointer.targetEntity

                if position ~= nil or target ~= nil then 
                    local spell = ALL_SPELLS[sName]
                    local act
                    if spell.needTarget then
                        if spell:CheckTarget(target) then
                            act = self.inst.components.playeractionpicker:SortActionList({ ACTIONS.GFCASTSPELL }, target, gfsp.withItem)[1]
                        end
                    else
                        act = self.inst.components.playeractionpicker:SortActionList({ ACTIONS.GFCASTSPELL }, target or position, gfsp.withItem)[1]
                    end

                    --this was written a log time ago, I don't remember details
                    --TODO - check out this code
                    if act then
                        if not self.ismastersim then
                            --need to use custom data for default RPC (we get info about target from the spell pointer)
                            if self.locomotor == nil then
                                self.remote_controls[GLOBAL.CONTROL_CONTROLLER_ACTION] = 0
                                local isreleased = not TheInput:IsControlPressed(GLOBAL.CONTROL_CONTROLLER_ACTION)
                                if target then
                                    SendRPCToServer(RPC.ControllerActionButton, act.action.code, target, isreleased, nil, act.action.mod_name)
                                else
                                    SendRPCToServer(RPC.ControllerActionButtonPoint, act.action.code, position.x, position.z, isreleased, nil, act.action.mod_name)
                                end
                            else
                                act.preview_cb = function()
                                    self.remote_controls[GLOBAL.CONTROL_CONTROLLER_ACTION] = 0
                                    local isreleased = not TheInput:IsControlPressed(GLOBAL.CONTROL_CONTROLLER_ACTION)
                                    if target then
                                        SendRPCToServer(RPC.ControllerActionButton, act.action.code, target, isreleased, nil, act.action.mod_name)
                                    else
                                        SendRPCToServer(RPC.ControllerActionButtonPoint, act.action.code, position.x, position.z, isreleased, nil, act.action.mod_name)
                                    end
                                end
                            end
                        end

                        self:DoAction(act)
                        return
                    end
                end
            end
        end

        _oldDoControllerActionButton(self)
    end

    --"Y" button on xbox controller
    --[[local _oldDoInspectButton = self.DoInspectButton
    function self:DoInspectButton()
        _oldDoInspectButton(self)
    end]]
end)

AddClassPostConstruct("screens/playerhud", function (self)
    local _oldOnControl = self.OnControl

    self.gfJournalDelay = 0
    self.gfSpellSelection = false --player is selecting a spell from the spell panel 
    self.gfInConversation = false

    --kinda hax - "A" button in the HUD controls should be blocked until it will be released
    self.gfLockActionButton = false
    self.gfUnlockTime = nil
    self.gfLockLeftStick = false

    function self:_LockActionButton(val)
        self.gfLockActionButton = val
    end

    function self:SetSpellSelection(val)
        self.gfSpellSelection = val 
        if not val then self.gfLockActionButton = false end
    end

    function self:IsSpellSelectionEnabled()
        return self.gfSpellSelection
    end

    function self:SetInConversation(val)
        self.gfInConversation = val 
        if not val then self.gfLockActionButton = false end

        --disable the spell selector
        if self:IsSpellSelectionEnabled() then
            if self.controls.gfSpellPanel ~= nil then
                self.controls.gfSpellPanel:DisableSpellSelection()
            end
            self:SetSpellSelection(false)
        end
    end

    function self:IsInConversation()
        return self.gfInConversation
    end

    function self:OnControl(control, down)
        --print("hud control", control, down)
        if TheInput:ControllerAttached() then
            --controller only
            --there is an option to do that without a timer but there is no guaranty that 
            --CONTROL_ACCEPT or CONTROL_CONTROLLER_ALTACTION always work the way I think
            --[[if self.gfUnlockTime ~= nil and self.gfUnlockTime < _G.GetTime() then 
                --remove the key lock (need it to prevent instant casts or instant dialog choises)
                self:_LockActionButton(false)
                self.gfUnlockTime = nil
            end]]
            if control == _G.CONTROL_MENU_MISC_3 then
                --enable/disable the spell selector (left stick click)
                if not self.gfLockLeftStick then
                    if self:IsSpellSelectionEnabled() then
                        if self.controls.gfSpellPanel then
                            self.controls.gfSpellPanel:DisableSpellSelection()
                        end
                        self.gfLockLeftStick = true
                        self:SetSpellSelection(false)
                    elseif self.controls.gfSpellPanel ~= nil then
                        --don't start selection if the inventory or the conversation dialog is open
                        if not self:IsControllerInventoryOpen() and not self:IsInConversation() then
                            self.controls.gfSpellPanel:EnableSpellSelection()
                            self.gfLockLeftStick = true
                            self:SetSpellSelection(true)
                        end
                    end
                end
                
                if not down then self.gfLockLeftStick = false end
            elseif self:IsSpellSelectionEnabled() and self.controls.gfSpellPanel ~= nil then
                if control == _G.CONTROL_OPEN_INVENTORY then
                    --disable the spell selector if the player opens the inventory (right trigger)
                    self.controls.gfSpellPanel:DisableSpellSelection()
                    self:SetSpellSelection(false)
                elseif control == _G.CONTROL_ACCEPT then
                    --select a spell ("A" - button)
                    --control should be disabled after first run (need to ignore key holding) to prevent an instant cast
                    if not self.gfLockActionButton then
                        self.controls.gfSpellPanel:UseActiveSpell()
                        self:SetSpellSelection(false) --always need to remove the SpellSelect flag due the spell panel was removed or something else
                        self:_LockActionButton(true)
                        return true
                    end
                elseif control == _G.CONTROL_CONTROLLER_ACTION then
                    --need to hook this before it goes to the playercontroller
                    return true
                elseif control == _G.CONTROL_CANCEL or control == _G.CONTROL_CONTROLLER_ALTACTION then
                    --cancel spell selection ("B" - button)
                    self.controls.gfSpellPanel:DisableSpellSelection()
                    self:SetSpellSelection(false) --always need to remove the SpellSelect flag due the spell panel was removed or something else
                    return true
                --quick cast for controllers (d-pad)
                elseif control == _G.CONTROL_INVENTORY_EXAMINE then
                    self.controls.gfSpellPanel:UseSpell(1)
                    self:SetSpellSelection(false)
                    return true
                elseif control == _G.CONTROL_INVENTORY_USEONSELF then
                    self.controls.gfSpellPanel:UseSpell(2)
                    self:SetSpellSelection(false)
                    return true
                elseif control == _G.CONTROL_INVENTORY_DROP then
                    self.controls.gfSpellPanel:UseSpell(3)
                    self:SetSpellSelection(false)
                    return true
                elseif control == _G.CONTROL_INVENTORY_USEONSCENE then
                    self.controls.gfSpellPanel:UseSpell(4)
                    self:SetSpellSelection(false)
                    return true
                end
            elseif self:IsInConversation() then
                if control == _G.CONTROL_ACCEPT then
                    --select a row or accept/complete a quest ("A" - button)
                    --control should be disabled after first run (need to ignore key holding) to prevent an instant action
                    if not self.gfLockActionButton then
                        if self.controls.gfConversationDialog ~= nil then
                            self.controls.gfConversationDialog:ControllerAcceptButton()
                        end
                        self:_LockActionButton(true)
                        return true
                    end
                elseif control == _G.CONTROL_CONTROLLER_ACTION then
                    --need to hook this before it goes to the playercontroller
                    return true
                elseif control == _G.CONTROL_CANCEL or control == _G.CONTROL_CONTROLLER_ALTACTION then
                    --close the dialog window ("B" - button)
                    if self.controls.gfConversationDialog ~= nil then
                        self.controls.gfConversationDialog:ControllerCloseButton()
                    end
                    self:SetInConversation(false)
                    return true
                end
            end

            if self.gfLockActionButton then
                if control == _G.CONTROL_ACCEPT then
                    --remove the "A" lock if key is released
                    --if not down then self.gfLockActionButton = _G.GetTime() end
                    --if not down then self.gfUnlockTime = _G.GetTime() end
                    self:_LockActionButton(false)
                    return true
                elseif control == _G.CONTROL_CONTROLLER_ACTION then
                    --need to hook this before it goes to the playercontroller
                    return true
                end
            end
        else
            --keyboard only
            if TheInput:IsKeyDown(_G.KEY_ALT) and control >= _G.CONTROL_INV_1 and control <= _G.CONTROL_INV_10 then
                --cast spell with alt + inventory button
                self.controls.gfSpellPanel:UseSpell(control - _G.CONTROL_INV_1 + 1)
                return true
            end
        end

        --controller and keyboard
        if control == _G.CONTROL_MAP then
            --hold the minimap button to open the quest journal
            if down then 
                self.gfJournalDelay = _G.GetTime()
            elseif _G.GetTime() - self.gfJournalDelay >= 1 then
                _G.TheFrontEnd:PushScreen(PopJournal(self.owner))
                return true
            end
        end

        return _oldOnControl(self, control, down)
    end
end)