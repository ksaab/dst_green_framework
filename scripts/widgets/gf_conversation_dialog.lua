local Widget = require "widgets/widget"
local Text = require "widgets/text"
local TEMPLATES = require "widgets/redux/templates"
local NineSlice = require "widgets/nineslice"
local CONV_BUTTON = require "widgets/gf_conversation_button"

local ALL_QUESTS = GF.GetQuests()
local ALL_DIALOGUE_NODES =  GF.GetDialogueNodes()
local INVALID_TITLE = STRINGS.GF.HUD.INVALID_LINES.INVALID_TITLE
local INVALID_TEXT = STRINGS.GF.HUD.INVALID_LINES.INVALID_TEXT

local ENUM_OFFER, ENUM_COMPLETE, ENUM_NODE = 0, 1, 2

local function GetAcceptText(text)
    local controller_id = TheInput:GetControllerID()
    return TheInput:ControllerAttached()
        and string.format("%s %s", TheInput:GetLocalizedControl(controller_id, CONTROL_CONTROLLER_ACTION), text)
        or text
end

local function GetCancelText(text)
    local controller_id = TheInput:GetControllerID()
    return TheInput:ControllerAttached()
        and string.format("%s %s", TheInput:GetLocalizedControl(controller_id, CONTROL_CONTROLLER_ALTACTION), text)
        or text
end

local function GetHintText()
    local controller_id = TheInput:GetControllerID()
    return TheInput:ControllerAttached()
        and string.format(
            "%s / %s — %s\n%s — %s", 
            TheInput:GetLocalizedControl(controller_id, CONTROL_INVENTORY_UP), 
            TheInput:GetLocalizedControl(controller_id, CONTROL_INVENTORY_DOWN),
            STRINGS.GF.HUD.CONVERSATION_DIALOG.HINTMOVE,
            TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT),
            STRINGS.GF.HUD.CONVERSATION_DIALOG.HINTSELECT)
        or ""
end

local function Close(owner)
    --owner.components.gfplayerdialog:HandleQuestButton(1)
    owner:PushEvent("gfDialogButton", {event = 0})
    owner:PushEvent("gfPDCloseDialog")
    --GFDebugPrint("CLIENT: you've refused the quest.", qName)
end

local function Node(owner, qName)
    --owner.components.gfplayerdialog:HandleQuestButton(1)
    owner:PushEvent("gfDialogButton", {event = 1, name = qName})
    --owner:PushEvent("gfPDCloseDialog")
    --GFDebugPrint("CLIENT: you've refused the quest.", qName)
end

local function Accept(owner, qName)
    --owner.components.gfplayerdialog:HandleQuestButton(0, qName)
    owner:PushEvent("gfDialogButton", {event = 2, name = qName})
    owner:PushEvent("gfPDCloseDialog")
    --GFDebugPrint("CLIENT: you've accepted the quest.", qName)
end

local function Complete(owner, qName)
    --owner.components.gfplayerdialog:HandleQuestButton(3, qName)
    owner:PushEvent("gfDialogButton", {event = 3, name = qName})
    owner:PushEvent("gfPDCloseDialog")
    --GFDebugPrint("CLIENT: you've trying to complete the quest.", qName)
end

local ConversationDialog = Class(Widget, function(self, owner)
	self.owner = owner
    Widget._ctor(self, "ConversationDialog")

    self.activeLine = 0
    --self.onControllerAccept = nil
    self.lastSelect = 0
    --widget itself
    self.root = self:AddChild(Widget("ROOT"))
    self.root:SetHAnchor(ANCHOR_LEFT)
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetPosition(330, 0)

    self.window = self.root:AddChild(NineSlice("images/dialogcurly_9slice.xml"))
    local window = self.window

    local crown
    crown = window:AddCrown("crown-top-fg.tex", ANCHOR_MIDDLE, ANCHOR_TOP, 0, 68)
    crown = window:AddCrown("crown-top.tex", ANCHOR_MIDDLE, ANCHOR_TOP, 0, 44)
    crown:MoveToBack()
    crown = window:AddCrown("crown-bottom-fg.tex", ANCHOR_MIDDLE, ANCHOR_BOTTOM, 0, -14)
    crown:MoveToFront()

    window:SetSize(250, 350)
    window:SetScale(0.7, 0.7)

    window.title = window:AddChild(Text(HEADERFONT, 40, "Title", UICOLOURS.GOLD_SELECTED))
    window.title:SetPosition(0, 200)
    window.title:SetRegionSize(300, 50)
    window.title:SetHAlign(ANCHOR_MIDDLE)

    window.body = window:AddChild(Text(CHATFONT, 24, "Body", UICOLOURS.WHITE))
    window.body:EnableWordWrap(true)
    window.body:SetPosition(0, 115)
    window.body:SetRegionSize(300, 100)
    window.body:SetVAlign(ANCHOR_MIDDLE)

    window.goal = window:AddChild(Text(UIFONT, 20, "Body", UICOLOURS.WHITE))
    window.goal:EnableWordWrap(true)
    window.goal:SetPosition(0, -100)
    window.goal:SetRegionSize(250, 40)
    window.goal:SetVAlign(ANCHOR_MIDDLE)

    window.leftButton   = window:AddChild(TEMPLATES.StandardButton(nil, "Left", {100, 50}))
    window.rightButton  = window:AddChild(TEMPLATES.StandardButton(nil, "Right", {100, 50}))
    window.middleButton = window:AddChild(TEMPLATES.StandardButton(nil, "Middle", {150, 50}))

    window.leftButton:SetPosition(-60, -150)
    window.rightButton:SetPosition(60, -150)
    window.middleButton:SetPosition(0, -150)

    window.hint = window:AddChild(Text(UIFONT, 36, "Body", UICOLOURS.WHITE))
    window.hint:SetPosition(0, -275)

    window.questLines = {}

    self:Hide()
    local allChilds = {"title", "body", "goal", "leftButton", "rightButton", "middleButton"}
    for k, v in pairs(allChilds) do window[v]:Hide() end

    self.inst:ListenForEvent("gfPDChoiseDialog", function(player, data) self:ShowChoiseDialog(data) end, owner)
    self.inst:ListenForEvent("gfPDAcceptDialog", function(player, data) self:ShowAcceptDialog(data) end, owner)
    self.inst:ListenForEvent("gfPDCloseDialog", function(player) self:CloseDialog() end, owner)
    self.inst:ListenForEvent("gfPDCompleteDialog", function(player, data) self:ShowCompleteDialog(data) end, owner)
    
    --self.inst:ListenForEvent("gfShopOpen", function(player, list) self:OpenShop(list) end, owner)
    --self.inst:ListenForEvent("gfShopClose", function(player) self:CloseShop() end, owner)
    
    print("Quest dialog was added to ", owner)
end)

function ConversationDialog:CleanUp()
    if self.shopDialog ~= nil then self.shopDialog:Close() end
    if self.scroll ~= nil then self.scroll:Kill() end
    --reset the controller selector
    self.activeLine = 0
    --self.onControllerAccept = nil
    
    self:StopUpdating()
    self:Hide()

    local window = self.window

    window.leftButton:Hide()
    window.rightButton:Hide()
    window.middleButton:Hide()

    window.leftButton:SetOnClick(function() end)
    window.rightButton:SetOnClick(function() end)
    window.middleButton:SetOnClick(function() end)

    window.title:Hide()
    window.body:Hide()
    window.goal:Hide()

    window.title:SetString()
    window.body:SetString()
    window.goal:SetString()
end

function ConversationDialog:CloseDialog()
    self:CleanUp()
    if self.owner.HUD ~= nil then self.owner.HUD:SetInConversation(false) end
end

function ConversationDialog:ShowChoiseDialog(data)
    if self.owner.HUD ~= nil then self.owner.HUD:SetInConversation(true) end

    self:CleanUp()
    self:StartUpdating()

    local window = self.window
    local lines = window.questLines
    local gQuests = data.gQuests
    local cQuests = data.cQuests
    local events = data.events
    local offset = 75

    local items = {}

    for j = 1, #cQuests do
        if ALL_QUESTS[cQuests[j]] ~= nil then
            local data = 
            {
                type = ENUM_COMPLETE,
                name = cQuests[j],
            }
            table.insert(items, data)
        end
    end

    for j = 1, #gQuests do
        if ALL_QUESTS[gQuests[j]] ~= nil then
            local data = 
            {
                type = ENUM_OFFER,
                name = gQuests[j],
            }
            table.insert(items, data)
        end
    end

    for j = 1, #events do
        if ALL_DIALOGUE_NODES[events[j]] ~= nil then
            local data = 
            {
                type = ENUM_NODE,
                name = events[j],
            }
            table.insert(items, data)
        end
    end

    local function RowConstructor(context, index)
        return CONV_BUTTON(self.owner, self)
    end

    local function ApplyFn(context, widget, data, index) 
        if data ~= nil then
            widget:Config(data.name, data.type)
            widget.index = index
        elseif widget ~= nil then
            widget:Hide()
        end
    end

    local opts = 
    {
        context = {},
        widget_width  = 300,
        widget_height = 35,
        num_visible_rows = math.min(4, #items),
        num_columns = 1,
        item_ctor_fn = RowConstructor,
        apply_fn = ApplyFn,
        scrollbar_offset = 25,
        scrollbar_height_offset = -35,
        peek_percent = 0,
        allow_bottom_empty_row = true,
        scroll_per_click = 1,
    }

    if #items > 0 then
        self.scroll = self.window:AddChild(TEMPLATES.ScrollingGrid(items, opts))
        self.scroll:SetPosition(0, -35)

        self.activeLine = 1
        if TheInput:ControllerAttached() then
            local visible = self.scroll:GetListWidgets()
            visible[1]:OnGainFocus()
        end
        --self.onControllerAccept = visible[1].button.onclick
    end

    self:Show()
    window.middleButton:Show()
    window.middleButton:SetText(GetCancelText(STRINGS.GF.HUD.CONVERSATION_DIALOG.BUTTONS.CLOSE))
    window.middleButton:SetOnClick(function() Close(self.owner) end)

    window.title:Show()
    window.body:Show()
    window.title:SetString(GetConversationString(self.owner, data.dString or "DEFAULT", "title"))
    window.body:SetString(GetConversationString(self.owner, data.dString or "DEFAULT", "text"))

    window.hint:SetString(GetHintText())
end

function ConversationDialog:ShowAcceptDialog(data)
    if self.owner.HUD ~= nil then self.owner.HUD:SetInConversation(true) end

    self:CleanUp()
    self:StartUpdating()

    local window = self.window
    local qName = data.qName

    if ALL_QUESTS[qName] == nil then
        return
    end

    local qData = ALL_QUESTS[qName] 

    self:Show()
    window.leftButton:Show()
    window.leftButton:SetText(GetCancelText(STRINGS.GF.HUD.CONVERSATION_DIALOG.BUTTONS.DECLINE))
    window.leftButton:SetOnClick(function() Close(self.owner, qName) end)

    window.rightButton:Show()
    window.rightButton:SetText(GetAcceptText(STRINGS.GF.HUD.CONVERSATION_DIALOG.BUTTONS.ACCEPT))
    window.rightButton:SetOnClick(function() Accept(self.owner, qName) end)

    self.onControllerAccept = window.rightButton.onclick

    window.title:Show()
    window.body:Show()
    window.goal:Show()
    window.title:SetString(GetQuestString(self.owner, qName, "title"))
    window.body:SetString(GetQuestString(self.owner, qName, "desc"))
    window.goal:SetString(GetQuestString(self.owner, qName, "goal"))
    --[[ window.title:SetString(qData:GetTitleString(self.owner))
    window.body:SetString(qData:GetDescriptionString(self.owner))
    window.goal:SetString(qData:GetGoalString(self.owner)) ]]

    window.hint:SetString("")
end

function ConversationDialog:ShowCompleteDialog(data)
    if self.owner.HUD ~= nil then self.owner.HUD:SetInConversation(true) end

    self:CleanUp()
    self:StartUpdating()

    local window = self.window
    local qName = data.qName

    if ALL_QUESTS[qName] == nil then
        return
    end

    local qData = ALL_QUESTS[qName] 

    self:Show()
    window.leftButton:Show()
    window.leftButton:SetText(GetCancelText(STRINGS.GF.HUD.CONVERSATION_DIALOG.BUTTONS.CLOSE))
    window.leftButton:SetOnClick(function() Close(self.owner, qName) end)

    window.rightButton:Show()
    window.rightButton:SetText(GetAcceptText(STRINGS.GF.HUD.CONVERSATION_DIALOG.BUTTONS.COMPLETE))
    window.rightButton:SetOnClick(function() Complete(self.owner, qName) end)

    self.onControllerAccept = window.rightButton.onclick

    window.title:Show()
    window.body:Show()
    window.title:SetString(GetQuestString(self.owner, qName, "title"))
    window.body:SetString(GetQuestString(self.owner, qName, "completion"))

    window.hint:SetString("")
end

function ConversationDialog:OpenShop(list)
    print(list, PrintTable(list))
    
    if self.shopDialog ~= nil then
        self.shopDialog:Open(list)
    end
end

function ConversationDialog:CloseShop()
    if self.shopDialog ~= nil then
        self.shopDialog:Close()
    end
end

function ConversationDialog:ControllerSelectLine(down)
    if not TheInput:ControllerAttached() or self.scroll == nil then return end

    local target = down == true and self.activeLine + 1 or self.activeLine - 1
    local itemNum = #(self.scroll.items)
    if target > 0 and target <= itemNum then
        self.lastSelect = GetTime() + 0.15
        local visible = self.scroll:GetListWidgets()
        if visible and #visible > 0 then
            local maxIndex, minIndex
            for k, v in pairs(visible) do 
                if v.index ~= nil then
                    maxIndex = v.index
                    if v.index == self.activeLine then 
                        visible[k]:OnLoseFocus()
                    end
                    if minIndex == nil then
                        minIndex = v.index
                    end
                end
            end

            if target > maxIndex - 1 then
                self.scroll:ScrollToWidgetIndex(math.max(1, math.min(itemNum - 3), target - 3))
                visible = self.scroll:GetListWidgets()
                --print("scroll to", math.max(1, math.min(itemNum - 3), target - 3))
            elseif target < minIndex + 1 then
                self.scroll:ScrollToWidgetIndex(math.max(1, target))
                visible = self.scroll:GetListWidgets()
                --print("scroll to", math.max(1, target))
            end

            local newFocus
            for k, v in pairs(visible) do 
                if v.index == target then 
                    newFocus = v
                    break
                end
            end

            if newFocus ~= nil then
                newFocus:OnGainFocus()
                self.activeLine = target
            end
        end
    end
end

function ConversationDialog:ControllerCloseButton()
    self:StopUpdating()
    Close(self.owner)
end

function ConversationDialog:ControllerAcceptButton()
    if self.onControllerAccept ~= nil then 
        self.onControllerAccept() 
        return
    end
    if self.activeLine ~= nil and self.scroll ~= nil then
        local visible = self.scroll:GetListWidgets()
        for k, v in pairs(visible) do
            if v.index == self.activeLine then
                v.onclick()
                break
            end
        end
    end
end

function ConversationDialog:OnUpdate(dt)
    if GetTime() - self.lastSelect > 0.3 then
        if TheInput:IsControlPressed(CONTROL_INVENTORY_UP) then
            self:ControllerSelectLine(false)
        elseif TheInput:IsControlPressed(CONTROL_INVENTORY_DOWN) then
            self:ControllerSelectLine(true)
        end
    end
end

return ConversationDialog