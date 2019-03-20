--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

local _G = GLOBAL
local ALL_SPELLS = _G.GF.GetSpells()
local TheInput = GLOBAL.TheInput

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
    self.gfSpellSelection = false --player is selecting a spell from the spell panel 
    self.gfInConversation = false --conversation window is opened
    self.gfLockContAction = false --player chose a spell and hit "A" button - need to lock "A" to avoid instant spell cast
    self.gfLockLeftTrigger = false --almost the previous one, but avoids instant disabling for the spell selection

    function self:SetSpellPointer(val)
        self.gfSpellPointerEnabled = val 
    end

    function self:IsSpellPointerEnabled()
        return self.gfSpellPointerEnabled
    end

    function self:SetSpellSelection(val)
        self.gfSpellSelection = val 
    end

    function self:IsSpellSelectionEnabled()
        return self.gfSpellSelection
    end

    function self:SetInConversation(val)
        self.gfInConversation = val 
    end

    function self:IsInConversation()
        return self.gfInConversation
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

    local _oldOnControl = self.OnControl
    function self:OnControl(control, down)
        --left stick button
        --used to select a spell from the spell panel with a controller
        --gesture whell mod use the same bind but the mods shouldn't conflict
        if control == _G.CONTROL_MENU_MISC_3 then
            --TODO - conditions should be a bit attractive
            if not self.gfLockLeftTrigger then
                if self:IsEnabled() 
                    and not self:UsingMouse() 
                    and self.inst.HUD
                    and self.inst.HUD.controls.gfSpellPanel ~= nil
                then
                    if self:IsSpellSelectionEnabled() then
                        --turn of the spell selection if it is enabled
                        self:SetSpellSelection(false)
                        self.inst.HUD.controls.gfSpellPanel:DisableSpellSelection()
                        self.gfLockLeftTrigger = true
                    elseif self.inst.HUD.controls.gfSpellPanel:EnableSpellSelection() then
                        self:SetSpellSelection(true)
                        self.gfLockLeftTrigger = true
                    end
                end
            end

            if not down then self.gfLockLeftTrigger = false end
        elseif self:IsSpellSelectionEnabled() 
            and self.inst.HUD ~= nil
            and self.inst.HUD.controls.gfSpellPanel ~= nil
        then
            if control == _G.CONTROL_INVENTORY_EXAMINE  then
                self.inst.HUD.controls.gfSpellPanel:UseSpell(1)
                self:SetSpellSelection(false)
                return
            elseif control == _G.CONTROL_INVENTORY_USEONSELF then
                self.inst.HUD.controls.gfSpellPanel:UseSpell(2)
                self:SetSpellSelection(false)
                return
            elseif control == _G.CONTROL_INVENTORY_DROP then
                self.inst.HUD.controls.gfSpellPanel:UseSpell(3)
                self:SetSpellSelection(false)
                return
            elseif control == _G.CONTROL_INVENTORY_USEONSCENE then
                self.inst.HUD.controls.gfSpellPanel:UseSpell(4)
                self:SetSpellSelection(false)
                return
            end
        end

        _oldOnControl(self, control, down)

        --unlock the CONTROL_CONTROLLER_ACTION key after all OnControls ran and if it was released on current frame
        --read about this lock in DoControllerActionButton function
        if self.gfLockContAction and control == _G.CONTROL_CONTROLLER_ACTION and not down then
            self.gfLockContAction = false
        end 
    end

    --"B" button on xbox controller
    local _oldDoControllerAltActionButton = self.DoControllerAltActionButton
    function self:DoControllerAltActionButton()
        if not self:IsEnabled() or self:UsingMouse() then
            _oldDoControllerAltActionButton(self)
        end
        if self:IsInConversation() then
            if self.inst.HUD.controls.gfConversationDialog ~= nil then
                self.inst.HUD.controls.gfConversationDialog:ControllerCloseButton()
            end
            --always need to remove the Conversation flag
            self:SetInConversation(false)
            return
        elseif self:IsSpellSelectionEnabled() then
            --cancel the spell selection
            --TODO - conditions should be a bit attractive
            if self.inst.HUD.controls.gfSpellPanel ~= nil then
                self.inst.HUD.controls.gfSpellPanel:DisableSpellSelection()
            end
            --always need to remove the SpellSelect flag due the spell panel was removed or something else
            self:SetSpellSelection(false)
            return
        elseif self:IsSpellPointerEnabled() then
            --cancel the spell targeting
            --this was written a log time ago, I don't remember details
            --TODO - check out this code
            local position = self.inst.components.gfspellpointer.pointer.targetPosition or Vector3(0, 0, 0)
            local act = self.inst.components.playeractionpicker:SortActionList({ ACTIONS.GFSTOPSPELLTARGETING }, position, nil)[1]
            if act ~= nil then
                if not self.ismastersim then
                    act.preview_cb = function()
                        self.remote_controls[_G.CONTROL_CONTROLLER_ALTACTION] = 0
                        local isreleased = not TheInput:IsControlPressed(_G.CONTROL_CONTROLLER_ALTACTION)
                        SendRPCToServer(RPC.ControllerAltActionButton, act.action.code, self.inst, isreleased, nil, act.action.mod_name)
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
        if not self:IsEnabled() or self:UsingMouse() then
            _oldDoControllerActionButton(self)
        end
        --need to lock the action key because on first tick (when player push the button) controller selects a spell 
        --and on the next tick (no one releases a key so fast) instantly cast it
        --so we lock any actions until the key will be released
        if self.gfLockContAction then return end
        if self:IsInConversation() then
            if self.inst.HUD.controls.gfConversationDialog ~= nil then
                self.inst.HUD.controls.gfConversationDialog:ControllerAcceptButton()
            else
                --remove the flag if the conversation window doesn'n exist (there is no another way to do this)
                self:SetInConversation(false)
            end

            self.gfLockContAction = true
            return
        elseif self:IsSpellSelectionEnabled() then
            --cast/target the chosen spell from the spell pannel 
            --TODO - conditions should be a bit attractive
            if self.inst.HUD.controls.gfSpellPanel ~= nil then
                self.inst.HUD.controls.gfSpellPanel:UseActiveSpell()
            end
            --always need to remove the SpellSelect flag due the spell panel was removed or something else
            self:SetSpellSelection(false)
            self.gfLockContAction = true
            return
        elseif self:IsSpellPointerEnabled() then
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

TheInput:AddKeyUpHandler(282, function()
    local player = _G.rawget(_G, "ThePlayer")
    if player ~= nil and player.HUD ~= nil and player.HUD.controls and player.HUD.controls.gfSpellPanel ~= nil then
        player.HUD.controls.gfSpellPanel:UseSpell(1)
    end
end)

TheInput:AddKeyUpHandler(283, function()
    local player = _G.rawget(_G, "ThePlayer")
    if player ~= nil and player.HUD ~= nil and player.HUD.controls and player.HUD.controls.gfSpellPanel ~= nil then
        player.HUD.controls.gfSpellPanel:UseSpell(2)
    end
end)

TheInput:AddKeyUpHandler(284, function()
    local player = _G.rawget(_G, "ThePlayer")
    if player ~= nil and player.HUD ~= nil and player.HUD.controls and player.HUD.controls.gfSpellPanel ~= nil then
        player.HUD.controls.gfSpellPanel:UseSpell(3)
    end
end)

TheInput:AddKeyUpHandler(285, function()
    local player = _G.rawget(_G, "ThePlayer")
    if player ~= nil and player.HUD ~= nil and player.HUD.controls and player.HUD.controls.gfSpellPanel ~= nil then
        player.HUD.controls.gfSpellPanel:UseSpell(4)
    end
end)
