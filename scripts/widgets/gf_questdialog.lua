local Widget = require "widgets/widget"
local TEMPLATES = require "widgets/redux/templates"

local allQuests = GFQuestList
local INVALID_TITLE = STRINGS.GF.QSTRINGS.INVALID_TITLE
local INVALID_TEXT = STRINGS.GF.QSTRINGS.INVALID_TEXT

local QuestDialog = Class(Widget, function(self, owner)
	self.owner = owner
    Widget._ctor(self, "QuestDialog")

    local ismaster = GFGetIsMasterSim()

    --click functions
    local function OnAcceptButton()
        if not ismaster then
            SendModRPCToServer(MOD_RPC["GreenFramework"]["GFOFFERQUESTRESULT"], true, self._qName)
        else
            owner.components.gfquestdoer:AcceptQuest(self._qName)
        end

        self:HideDialog()
        --print("CLIENT: you've accepted the quest.")
    end
    
    local function OnDeclineButton()
        if not ismaster then
            SendModRPCToServer(MOD_RPC["GreenFramework"]["GFOFFERQUESTRESULT"], false, self._qName)
        else
            owner.components.gfquestdoer:StopTrackGiver()
        end

        self:HideDialog()
        --print("CLIENT: you've refused the quest.")
    end
    
    local function OnCompleteButton()
        self:HideDialog()
        --print("CLIENT: you've completed the quest.")
    end

    --widget itself
    self._qName = nil
    self.proot = self:AddChild(Widget("ROOT"))
    self.proot:SetHAnchor(ANCHOR_LEFT)
    self.proot:SetVAnchor(ANCHOR_MIDDLE)
    self.proot:SetPosition(330, 0)
    self.proot.background = self.proot:AddChild(TEMPLATES.CurlyWindow(250, 350, "", {}, 0, ""))
    local bg = self.proot.background

    bg.body:EnableWordWrap(true)
    bg.body:SetVAlign(ANCHOR_TOP)
    --bg.buttons = self.proot:AddChild(Widget("ROOT"))
    bg.accept = bg:AddChild(TEMPLATES.StandardButton(OnAcceptButton, STRINGS.GF.QSTRINGS.BUTTON_ACCEPT, {100, 50}))
    bg.decline = bg:AddChild(TEMPLATES.StandardButton(OnDeclineButton, STRINGS.GF.QSTRINGS.BUTTON_DECLINE, {100, 50}))
    bg.complete = bg:AddChild(TEMPLATES.StandardButton(OnCompleteButton, STRINGS.GF.QSTRINGS.BUTTON_COMPLETE, {100, 50}))
    bg.accept:SetPosition(60, -150)
    bg.decline:SetPosition(-60, -150)
    bg.complete:SetPosition(0, -150)

    self:Hide()
    bg.accept:Hide()
    bg.decline:Hide()
    bg.complete:Hide()

    owner:ListenForEvent("qsquestoffered", function(player, data) self:ShowAcceptDialog(data) end)
    owner:ListenForEvent("qsquestcompleted", function(player, data) self:ShowCompleteDialog(data) end)
    owner:ListenForEvent("qsforceclosedialog", function(player, data) self:HideDialog(data) end)

    print("Quest dialog was added to ", owner)
end)

function QuestDialog:ShowAcceptDialog(data)
    self:Show()

    local bg = self.proot.background
    local qName = data.qName
    local qData = allQuests[qName] or {}

    self._qName = qName

    bg.accept:Show()
    bg.decline:Show()
    bg.title:SetString(qData.title or INVALID_TITLE)
    bg.body:SetString(qData.description or INVALID_TEXT)
end

function QuestDialog:ShowCompleteDialog(data)
    self:Show()

    local bg = self.proot.background
    local qName = data.qName
    local qData = allQuests[qName] or {}

    bg.complete:Show()
    bg.title:SetString(qData.title or INVALID_TITLE)
    bg.body:SetString(qData.completion or INVALID_TEXT)
end

function QuestDialog:HideDialog(data)
    self:Hide()

    local bg = self.proot.background

    self._qName = nil

    bg.accept:Hide()
    bg.decline:Hide()
    bg.complete:Hide()

    self.proot.background.title:SetString()
    self.proot.background.body:SetString()
end

return QuestDialog