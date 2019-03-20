local Widget = require "widgets/widget"
local Text = require "widgets/text"
local TEMPLATES = require "widgets/redux/templates"
local NineSlice = require "widgets/nineslice"
local CONV_BUTTON = require "widgets/gf_conversation_button"

local ALL_QUESTS = GF.GetQuests()
local INVALID_TITLE = STRINGS.GF.HUD.INVALID_LINES.INVALID_TITLE
local INVALID_TEXT = STRINGS.GF.HUD.INVALID_LINES.INVALID_TEXT

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
            "%s / %s - select", 
            TheInput:GetLocalizedControl(controller_id, CONTROL_INVENTORY_UP), 
            TheInput:GetLocalizedControl(controller_id, CONTROL_INVENTORY_DOWN))
        or ""
end

--[[ OFFER = 
    {
        MIDDLE_BUTTON = 
        {
            TEXT = "Middle",
        },
        LEFT_BUTTON = 
        {
            TEXT = "Left",
        },
        RIGHT_BUTTON = 
        {
            TEXT = "Right",
        },
        TITLE = true,
        BODY = true,
        GOAL = true,
    }, ]]
local TYPES =
{
    OFFER = 
    {
        MIDDLE_BUTTON = 
        {
            TEXT = "Close",
        },
        TITLE = "Pick a quest"
    },
    ACCEPT = 
    {
        LEFT_BUTTON = 
        {
            TEXT = "Decline",
        },
        RIGHT_BUTTON = 
        {
            TEXT = "Accept",
        },
    },
    COMPLETE = 
    {
        LEFT_BUTTON = 
        {
            TEXT = "Close",
        },
        RIGHT_BUTTON = 
        {
            TEXT = "Complete",
        },
    }
}

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
    GFDebugPrint("CLIENT: you've accepted the quest.", qName)
end

local function Complete(owner, qName)
    --owner.components.gfplayerdialog:HandleQuestButton(3, qName)
    owner:PushEvent("gfDialogButton", {event = 3, name = qName})
    owner:PushEvent("gfPDCloseDialog")
    GFDebugPrint("CLIENT: you've trying to complete the quest.", qName)
end

local ConversationDialog = Class(Widget, function(self, owner)
	self.owner = owner
    Widget._ctor(self, "ConversationDialog")

    self.activeLine = 0
    self.onControllerAccept = nil
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
    window.hint:SetPosition(0, -250)

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

function ConversationDialog:CloseDialog(data)
    if self.shopDialog ~= nil then self.shopDialog:Close() end
    if self.owner.HUD ~= nil then self.owner.HUD:SetInConversation(false) end
    
    self.activeLine = 0
    self.onControllerAccept = nil

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

    for k, v in pairs(window.questLines) do v:Kill() end
    window.questLines = {}
end

function ConversationDialog:ShowChoiseDialog(data)
    if self.owner.HUD ~= nil then self.owner.HUD:SetInConversation(true) end

    self:StartUpdating()

    local TYPE = TYPES.OFFER

    local window = self.window
    local lines = window.questLines
    local gQuests = data.gQuests
    local cQuests = data.cQuests
    local events = data.events
    local offset = 75

    for k, v in pairs(window.questLines) do v:Kill() end

    local i = 0
    for j = 1, #cQuests do
        i = i + 1
        local _q = ALL_QUESTS[cQuests[i]]
        if _q ~= nil then
            lines[i] = window:AddChild(CONV_BUTTON(
                function() 
                    self:CloseDialog()
                    self.owner:PushEvent("gfPDCompleteDialog", {qName = cQuests[j]}) 
                end, 
                GetQuestString(self.owner, cQuests[j], "title"),  
                {200, 40}
            ))
            offset = offset - 35
            lines[i]:SetPosition(0, offset)
            lines[i]:MakeCompleteButton()
            --[[lines[i] = window:AddChild(TEMPLATES.StandardButton(
                function() 
                    self:CloseDialog()
                    self.owner:PushEvent("gfPDCompleteDialog", {qName = cQuests[i]}) 
                end, 
                GetQuestString(self.owner, cQuests[i], "title"), 
                {200, 40}
            ))
            offset = offset - 35
            lines[i]:SetPosition(0, offset)
            lines[i].image:SetTint(0.3, 1, 0.6, 1)]]
        end
    end

    --offset = offset - 10
    for j = 1, #gQuests do
        i = i + 1
        local _q = ALL_QUESTS[gQuests[j]]
        if _q ~= nil then
            lines[i] = window:AddChild(CONV_BUTTON(
                function() 
                    self:CloseDialog()
                    self.owner:PushEvent("gfPDAcceptDialog", {qName = gQuests[j]}) 
                end, 
                GetQuestString(self.owner, gQuests[j], "title"),  
                {200, 40}
            ))
            offset = offset - 35
            lines[i]:SetPosition(0, offset)
            lines[i]:MakeAcceptButton()
            --[[lines[i] = window:AddChild(TEMPLATES.StandardButton(
                function() 
                    self:CloseDialog()
                    self.owner:PushEvent("gfPDAcceptDialog", {qName = gQuests[j]}) 
                end, 
                GetQuestString(self.owner, gQuests[j], "title"),  
                {200, 40}
            ))
            offset = offset - 35
            lines[i]:SetPosition(0, offset)]]
        end
    end

    --offset = offset - 10
    for j = 1, #events do
        i = i + 1
        local event = events[j]
        lines[i] = window:AddChild(CONV_BUTTON(
            function() 
                Node(self.owner, event)
            end, 
            GetConversationString(self.owner, event, "line"),  
            {200, 40}
        ))
        offset = offset - 35
        lines[i]:SetPosition(0, offset)
        --[[lines[i] = window:AddChild(TEMPLATES.StandardButton(
            function() 
                --self:CloseDialog()
                Node(self.owner, event)
                --self.owner.components.gfplayerdialog:HandleEventButton(event)
            end, 
            GetConversationString(self.owner, event, "line"),  
            {200, 40}
        ))
        offset = offset - 35
        lines[i]:SetPosition(0, offset)
        lines[i].image:SetTint(0.3, 0.3, 0.9, 1)]]
    end

    for k, v in pairs(lines) do print(k, v) end
    if #lines > 0 then
        self.activeLine = 1
        self.onControllerAccept = lines[1].button.onclick
        if TheInput:ControllerAttached() then
            lines[1].button:OnGainFocus()
        end
    end

    self:Show()
    window.middleButton:Show()
    window.middleButton:SetText(GetCancelText(TYPE.MIDDLE_BUTTON.TEXT))
    window.middleButton:SetOnClick(function() Close(self.owner) end)

    window.title:Show()
    window.body:Show()
    window.title:SetString(GetConversationString(self.owner, data.dString or "DEFAULT", "title"))
    window.body:SetString(GetConversationString(self.owner, data.dString or "DEFAULT", "text"))

    window.hint:SetString(GetHintText())
end

function ConversationDialog:ShowAcceptDialog(data)
    if self.owner.HUD ~= nil then self.owner.HUD:SetInConversation(true) end

    self:StartUpdating()

    local TYPE = TYPES.ACCEPT

    local window = self.window
    local qName = data.qName

    if ALL_QUESTS[qName] == nil then
        return
    end

    local qData = ALL_QUESTS[qName] 

    self:Show()
    window.leftButton:Show()
    window.leftButton:SetText(GetCancelText(TYPE.LEFT_BUTTON.TEXT))
    window.leftButton:SetOnClick(function() Close(self.owner, qName) end)

    window.rightButton:Show()
    window.rightButton:SetText(GetAcceptText(TYPE.RIGHT_BUTTON.TEXT))
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

    window.hint:SetString(GetHintText())
end

function ConversationDialog:ShowCompleteDialog(data)
    if self.owner.HUD ~= nil then self.owner.HUD:SetInConversation(true) end

    self:StartUpdating()

    local TYPE = TYPES.COMPLETE

    local window = self.window
    local qName = data.qName

    if ALL_QUESTS[qName] == nil then
        return
    end

    local qData = ALL_QUESTS[qName] 

    self:Show()
    window.leftButton:Show()
    window.leftButton:SetText(GetCancelText(TYPE.LEFT_BUTTON.TEXT))
    window.leftButton:SetOnClick(function() Close(self.owner, qName) end)

    window.rightButton:Show()
    window.rightButton:SetText(GetAcceptText(TYPE.RIGHT_BUTTON.TEXT))
    window.rightButton:SetOnClick(function() Complete(self.owner, qName) end)

    self.onControllerAccept = window.rightButton.onclick

    window.title:Show()
    window.body:Show()
    window.title:SetString(GetQuestString(self.owner, qName, "title"))
    window.body:SetString(GetQuestString(self.owner, qName, "completion"))

    window.hint:SetString(GetHintText())
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
    local lines = self.window.questLines
    if #lines > 0 then
        local target = down == true and self.activeLine + 1 or self.activeLine - 1
        if target > 0 and target <= #lines then
            self.lastSelect = GetTime() + 0.15
            if TheInput:ControllerAttached() then 
                lines[self.activeLine].button:OnLoseFocus() 
                lines[target].button:OnGainFocus()
            end
            self.activeLine = target
            self.onControllerAccept = lines[target].button.onclick
            print("active line", self.activeLine)
        end
    end
end

function ConversationDialog:ControllerCloseButton()
    self:StopUpdating()
    Close(self.owner)
end

function ConversationDialog:ControllerAcceptButton()
    print("ControllerAcceptButton")
    if self.onControllerAccept ~= nil then self.onControllerAccept() end
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