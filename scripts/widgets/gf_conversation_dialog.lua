local Widget = require "widgets/widget"
local Text = require "widgets/text"
local TEMPLATES = require "widgets/redux/templates"
local NineSlice = require "widgets/nineslice"

local ALL_QUESTS = GF.GetQuests()
local INVALID_TITLE = STRINGS.GF.HUD.INVALID_LINES.INVALID_TITLE
local INVALID_TEXT = STRINGS.GF.HUD.INVALID_LINES.INVALID_TEXT

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

    window.questLines = {}

    self:Hide()
    local allChilds = {"title", "body", "goal", "leftButton", "rightButton", "middleButton"}
    for k, v in pairs(allChilds) do window[v]:Hide() end

    self.inst:ListenForEvent("gfPDChoiseDialog", function(player, data) self:ShowChoiseDialog(data) end, owner)
    self.inst:ListenForEvent("gfPDAcceptDialog", function(player, data) self:ShowAcceptDialog(data) end, owner)
    self.inst:ListenForEvent("gfPDCloseDialog", function(player) self:CloseDialog() end, owner)
    self.inst:ListenForEvent("gfPDCompleteDialog", function(player, data) self:ShowCompleteDialog(data) end, owner)
    
    print("Quest dialog was added to ", owner)
end)

function ConversationDialog:CloseDialog(data)
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
    local TYPE = TYPES.OFFER

    local window = self.window
    local lines = window.questLines
    local gQuests = data.gQuests
    local cQuests = data.cQuests
    local events = data.events
    local offset = 75

    for k, v in pairs(window.questLines) do v:Kill() end

    local i = 1
    for i = 1, #cQuests do
        local _q = ALL_QUESTS[cQuests[i]]
        if _q ~= nil then
            lines[i] = window:AddChild(TEMPLATES.StandardButton(
                function() 
                    self:CloseDialog()
                    self.owner:PushEvent("gfPDCompleteDialog", {qName = cQuests[i]}) 
                end, 
                GetQuestString(self.owner, cQuests[i], "title"), 
                {200, 40}
            ))
            offset = offset - 30
            lines[i]:SetPosition(0, offset)
            lines[i].image:SetTint(0.3, 1, 0.6, 1)
        end
    end

    offset = offset - 10
    for j = 1, #gQuests do
        i = i + 1
        local _q = ALL_QUESTS[gQuests[j]]
        if _q ~= nil then
            lines[i] = window:AddChild(TEMPLATES.StandardButton(
                function() 
                    self:CloseDialog()
                    self.owner:PushEvent("gfPDAcceptDialog", {qName = gQuests[j]}) 
                end, 
                GetQuestString(self.owner, gQuests[j], "title"),  
                {200, 40}
            ))
            offset = offset - 30
            lines[i]:SetPosition(0, offset)
        end
    end

    offset = offset - 10
    for j = 1, #events do
        i = i + 1
        local event = events[j]
        lines[i] = window:AddChild(TEMPLATES.StandardButton(
            function() 
                --self:CloseDialog()
                Node(self.owner, event)
                --self.owner.components.gfplayerdialog:HandleEventButton(event)
            end, 
            GetConversationString(self.owner, event, "line"),  
            {200, 40}
        ))
        offset = offset - 30
        lines[i]:SetPosition(0, offset)
        lines[i].image:SetTint(0.3, 0.3, 0.9, 1)
    end

    self:Show()
    window.middleButton:Show()
    window.middleButton:SetText(TYPE.MIDDLE_BUTTON.TEXT)
    window.middleButton:SetOnClick(function() Close(self.owner) end)

    window.title:Show()
    window.body:Show()
    window.title:SetString(GetConversationString(self.owner, data.dString or "DEFAULT", "title"))
    window.body:SetString(GetConversationString(self.owner, data.dString or "DEFAULT", "text"))
end

function ConversationDialog:ShowAcceptDialog(data)
    local TYPE = TYPES.ACCEPT

    local window = self.window
    local qName = data.qName

    if ALL_QUESTS[qName] == nil then
        return
    end

    local qData = ALL_QUESTS[qName] 

    self:Show()
    window.leftButton:Show()
    window.leftButton:SetText(TYPE.LEFT_BUTTON.TEXT)
    window.leftButton:SetOnClick(function() Close(self.owner, qName) end)

    window.rightButton:Show()
    window.rightButton:SetText(TYPE.RIGHT_BUTTON.TEXT)
    window.rightButton:SetOnClick(function() Accept(self.owner, qName) end)

    window.title:Show()
    window.body:Show()
    window.goal:Show()
    window.title:SetString(GetQuestString(self.owner, qName, "title"))
    window.body:SetString(GetQuestString(self.owner, qName, "desc"))
    window.goal:SetString(GetQuestString(self.owner, qName, "goal"))
    --[[ window.title:SetString(qData:GetTitleString(self.owner))
    window.body:SetString(qData:GetDescriptionString(self.owner))
    window.goal:SetString(qData:GetGoalString(self.owner)) ]]
end

function ConversationDialog:ShowCompleteDialog(data)
    local TYPE = TYPES.COMPLETE

    local window = self.window
    local qName = data.qName

    if ALL_QUESTS[qName] == nil then
        return
    end

    local qData = ALL_QUESTS[qName] 

    self:Show()
    window.leftButton:Show()
    window.leftButton:SetText(TYPE.LEFT_BUTTON.TEXT)
    window.leftButton:SetOnClick(function() Close(self.owner, qName) end)

    window.rightButton:Show()
    window.rightButton:SetText(TYPE.RIGHT_BUTTON.TEXT)
    window.rightButton:SetOnClick(function() Complete(self.owner, qName) end)

    window.title:Show()
    window.body:Show()
    window.title:SetString(GetQuestString(self.owner, qName, "title"))
    window.body:SetString(GetQuestString(self.owner, qName, "completion"))
end


return ConversationDialog