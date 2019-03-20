local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"

local ENUM_OFFER, ENUM_COMPLETE, ENUM_NODE = 0, 1, 2

local ConversationButton = Class(Widget, function(self, owner, window)
    self.owner = owner
    self.window = window

    Widget._ctor(self, "ConversationButton")

    --[[self.button = self:AddChild(ImageButton("images/global_redux.xml", 
        "button_carny_xlong_normal.tex",
        "button_carny_xlong_hover.tex",
        "button_carny_xlong_disabled.tex",
        "button_carny_xlong_down.tex"))
    self.button:SetImageNormalColour(222/255, 184/255, 135/255, 1)
    self.button:SetNormalScale(0.7, 0.5, 1)
    self.button:SetFocusScale(0.9, 0.6, 1)]]
    --self.button:SetPosition(15, 0)

    self.clickoffset = Vector3(0,-3,0)

    self:Enable()
    self:SetClickable(true)

    self.image = self:AddChild(Image("images/global_redux.xml", "button_carny_xlong_normal.tex"))
    --self.image:SetMouseOverTexture("images/global_redux.xml", "button_carny_xlong_hover.tex")
    self.image:SetSize(290, 45)

    self.icon = self.image:AddChild(Image("images/gfquestjournal.xml", "markconversation.tex"))
    self.icon:SetSize(24, 24)
    self.icon:SetPosition(-120, 0)
    self.icon:SetTint(0, 0, 0, 1)

    self.text = self.image:AddChild(Text(CHATFONT, 18))
    self.text:SetHAlign(ANCHOR_LEFT)
    self.text:SetRegionSize(240, 30)
    self.text:SetColour(0, 0, 0, 1)
    self.text:SetPosition(20, 0)
end)

function ConversationButton:OnGainFocus()
    self.image:SetTexture("images/global_redux.xml", "button_carny_xlong_hover.tex")
    self.image:SetSize(290, 45)
    self:UpdateImage()
end

function ConversationButton:OnLoseFocus()
    self.image:SetTexture("images/global_redux.xml", "button_carny_xlong_normal.tex")
    self.image:SetSize(290, 45)

    if self.o_pos ~= nil then
        self:SetPosition(self.o_pos)
        self.o_pos = nil
    end
end

function ConversationButton:OnMouseButton(button, down, x, y)
    if not self.focus then return false end

    if button == MOUSEBUTTON_LEFT then
        if down then
            self.o_pos = self:GetLocalPosition()
            self:SetPosition(self.o_pos + self.clickoffset)
        else
            self:SetPosition(self.o_pos)
            self.o_pos = nil
            if self.onclick then
                self.onclick()
            end
        end
    end
end

function ConversationButton:SetOnClick(fn)
    self.onclick = fn
end

--sometimes the scroll widget shows wrong image, need to update it manually
--not the best option - sometimes images doesn't update
function ConversationButton:UpdateImage()
    if self.type == nil then return end

    if self.type == ENUM_COMPLETE then 
        self.icon:SetTexture("images/gfquestjournal.xml", "markquestion.tex")
        self.icon:SetSize(20, 20)
        self.icon:SetTint(0/255, 128/255, 0/255, 1)
    elseif self.type == ENUM_OFFER then 
        self.icon:SetTexture("images/gfquestjournal.xml", "markexclamation.tex")
        self.icon:SetSize(20, 20)
        self.icon:SetTint(147/255, 112/255, 219/255, 1)
    elseif self.type == ENUM_NODE then 
        self.icon:SetTexture("images/gfquestjournal.xml", "markconversation.tex")
        self.icon:SetSize(20, 20)
        self.icon:SetTint(0, 0, 0, 1)
    end
end

function ConversationButton:MakeConversationButton(name)
    self.text:SetString(GetConversationString(self.owner, name, "line"))

    self:SetOnClick(function()
        self.owner:PushEvent("gfDialogButton", {event = 1, name = name}) 
    end)
end

function ConversationButton:MakeCompleteButton(name)
    self.icon:SetTexture("images/gfquestjournal.xml", "markquestion.tex")
    self.icon:SetSize(20, 20)
    self.icon:SetTint(0/255, 128/255, 0/255, 1)

    self.text:SetString(GetQuestString(self.owner, name, "title"))

    self:SetOnClick(function() 
        self.owner:PushEvent("gfPDCompleteDialog", {qName = name}) 
    end)
end

function ConversationButton:MakeAcceptButton(name)
    self.icon:SetTexture("images/gfquestjournal.xml", "markexclamation.tex")
    self.icon:SetSize(20, 20)
    self.icon:SetTint(147/255, 112/255, 219/255, 1)

    self.text:SetString(GetQuestString(self.owner, name, "title"))

    self:SetOnClick(function() 
        self.owner:PushEvent("gfPDAcceptDialog", {qName = name}) 
    end)
end

function ConversationButton:Config(name, type)
    self.type = type
    if type == ENUM_COMPLETE then self:MakeCompleteButton(name)
    elseif type == ENUM_OFFER then self:MakeAcceptButton(name)
    elseif type == ENUM_NODE then self:MakeConversationButton(name)
    end
end

function ConversationButton:__tostring()
    return "dialog button " .. (self.text:GetString() or "empty")
end

return ConversationButton