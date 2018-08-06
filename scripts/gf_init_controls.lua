--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

local _G = GLOBAL

AddComponentPostInit("playeractionpicker", function(self)
    local _oldGetLeftClickActions = self.GetLeftClickActions
    function self:GetLeftClickActions(position, target)
        if self.inst.components.playercontroller.gfSpellPointerEnabled then
            local lmb = self.inst.components.gfspellpointer:CollectLeftActions(position, target)
            return lmb or {}
        end

        return _oldGetLeftClickActions(self, position, target)
    end

    local _oldGetRightClickActions = self.GetRightClickActions
    function self:GetRightClickActions(position, target)
        if self.inst.components.playercontroller.gfSpellPointerEnabled then
            local rmb = self.inst.components.gfspellpointer:CollectRightActions(position, target)
            return rmb or {}
        end

        return _oldGetRightClickActions(self, position, target)
    end
end)

AddComponentPostInit("playercontroller", function(self)
    --variables
    local TheInput = GLOBAL.TheInput
    local ACTIONS = GLOBAL.ACTIONS
    local RPC = GLOBAL.RPC
    local BufferedAction = GLOBAL.BufferedAction
    local SendRPCToServer = GLOBAL.SendRPCToServer
    local CanEntitySeePoint = GLOBAL.CanEntitySeePoint
    self.gfSpellPointerEnabled = false

    --[[both side changes]]
    local _oldGetGroundUseAction = self.GetGroundUseAction
    function self:GetGroundUseAction(position)
        if self.gfSpellPointerEnabled 
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
        if self.gfSpellPointerEnabled 
            and self:IsEnabled()
            and not self:UsingMouse()
        then
            local position = self.inst.components.gfspellpointer.pointer.targetPosition or Vector3(0, 0, 0)
            local act = self.inst.components.playeractionpicker:SortActionList({ ACTIONS.GFSTOPSPELLTARGETING }, position, nil)[1]
            if act ~= nil then
                if not self.ismastersim then
                    act.preview_cb = function()
                        self.remote_controls[GLOBAL.CONTROL_CONTROLLER_ALTACTION] = 0
                        local isreleased = not TheInput:IsControlPressed(GLOBAL.CONTROL_CONTROLLER_ALTACTION)
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
        if self.gfSpellPointerEnabled 
            and self:IsEnabled()
            and not self:UsingMouse()
        then
            local pointer = self.inst.components.gfspellpointer.pointer
            local position = pointer.targetPosition or Vector3(0, 0, 0)
            local target = pointer.targetEntity

            local act = self.inst.components.playeractionpicker:SortActionList({ ACTIONS.GFCASTSPELL }, target or position, nil)[1]
            --local act 
            --for _, action in pairs(self.inst.components.playeractionpicker:SortActionList({ ACTIONS.GFCASTSPELL }, position, nil)) do
                --if act.action == ACTIONS.GFCASTSPELL then
                    --act = action
                    --break
                --end
            --end 
            if act then
                if not self.ismastersim then
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
        
        _oldDoControllerActionButton(self)
    end

    if _G.GFGetIsMasterSim() then return end
    --[[client only changes for the player controller]]
    --need to hook OnLeftClick, if we want to push the calculated position and target
    --host will work correctly without this
    --[[ local _oldOnLeftClick = self.OnLeftClick
    function self:OnLeftClick(down)
        if self.gfSpellPointerEnabled 
            and down
            and self:IsEnabled()
            and self:UsingMouse()
        then
            local act = self:GetLeftMouseAction()
            if  act and act.action == ACTIONS.GFCASTSPELL then
                local controlmods = self:EncodeControlMods()
                local pointer = self.inst.components.gfspellpointer.pointer
                local position = pointer.targetPosition
                local target = pointer.targetEntity

                act.preview_cb = function()
                    self.remote_controls[GLOBAL.CONTROL_PRIMARY] = 0
                    local isreleased = not TheInput:IsControlPressed(GLOBAL.CONTROL_PRIMARY)
                    SendRPCToServer(RPC.LeftClick, act.action.code, position.x, position.z, target, isreleased, controlmods, nil, act.action.mod_name)
                end

                self:DoAction(act)

                return
            end
        end

        _oldOnLeftClick(self, down)
    end ]]
end)
