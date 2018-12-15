local Screen = require "widgets/screen"
local Text = require "widgets/text"
local Widget = require "widgets/widget"
local Image = require "widgets/image"
local TEMPLATES = require "widgets/redux/templates"
local ImageButton = require "widgets/imagebutton"
local ALL_QUESTS = GF.GetQuests()

local INVALID_TITLE = STRINGS.GF.HUD.INVALID_LINES.INVALID_TITLE
local INVALID_TEXT = STRINGS.GF.HUD.INVALID_LINES.INVALID_TEXT

local DONE_COLOUR = {0, 128/255, 0, 1}
local FAILED_COLOUR = {128/255, 0, 0, 1}
local QCOLOUS = 
{
    WHITE,
    DONE_COLOUR,
    FAILED_COLOUR,
}

local function CancelQuest(owner, qName, hash)
    if qName and owner and owner.components.gfplayerdialog then
        owner.components.gfplayerdialog:HandleQuestButton(2, qName, hash)
    end
end

local QuestJournalScreen = Class(Screen, function(self, owner)
    Screen._ctor(self, "QuestJournalScreen")
    self.owner = owner

    self.proot = self:AddChild(Widget("ROOT"))
    self.proot:SetVAnchor(ANCHOR_MIDDLE)
    self.proot:SetHAnchor(ANCHOR_MIDDLE)
    self.proot:SetPosition(0, 0)
    self.proot:SetScaleMode(SCALEMODE_PROPORTIONAL)

    self.proot:SetPosition(0, 20)

    local artSize = 170
    local artXOffset = 230
    local artYOffset = 230

    self.bg = self.proot:AddChild(Image("images/fepanel_fills.xml", "panel_fill_tiny.tex"))
    self.bg:SetSize(600, 600)

    self.bg.topline = self.bg:AddChild(Image("images/gfquestjournal.xml", "edgetop.tex"))
    self.bg.topline:SetPosition(0, 185)

    self.bg.bottomline = self.bg:AddChild(Image("images/gfquestjournal.xml", "edgebottom.tex"))
    self.bg.bottomline:SetPosition(0, -185)

    self.bg.topleft = self.bg:AddChild(Image("images/gfquestjournal.xml", "topleft.tex"))
    self.bg.topleft:SetPosition(-artXOffset, artYOffset)
    self.bg.topleft:SetSize(artSize, artSize)

    self.bg.topright = self.bg:AddChild(Image("images/gfquestjournal.xml", "topright.tex"))
    self.bg.topright:SetPosition(artXOffset, artYOffset)
    self.bg.topright:SetSize(artSize, artSize)

    self.bg.bottomleft = self.bg:AddChild(Image("images/gfquestjournal.xml", "bottomleft.tex"))
    self.bg.bottomleft:SetPosition(-artXOffset, -artYOffset)
    self.bg.bottomleft:SetSize(artSize, artSize)

    self.bg.bottomright = self.bg:AddChild(Image("images/gfquestjournal.xml", "bottomright.tex"))
    self.bg.bottomright:SetPosition(artXOffset, -artYOffset)
    self.bg.bottomright:SetSize(artSize, artSize)

    self.header = self.proot:AddChild(Text(UIFONT, 45, STRINGS.GF.HUD.JOURNAL.TITLE))
    self.header:SetPosition(0, 245)

    self.closeButton = self.proot:AddChild(TEMPLATES.StandardButton(function() self:Close() end, STRINGS.GF.HUD.JOURNAL.BUTTONS.CLOSE, {180, 60}))
    self.closeButton:SetPosition(0, -250)
    
    if self.owner.replica.gfquestdoer == nil then print("QuestJournalScreen: gfquestdoer component isn't valid!") return end
    
    self.strings = {}
    
    local hasQuests = false
    local i = 1
    for qKey, qData in pairs(self.owner.replica.gfquestdoer.currentQuests) do
        hasQuests = true
        local qName = qData.name
        if ALL_QUESTS[qName] ~= nil then
            self.strings[i] = 
            {
                GetQuestString(self.owner, qName, "title"),
                string.format(GetQuestString(self.owner, qName, "status"), 
                    unpack(ALL_QUESTS[qName]:GetStatusData(self.owner, qData))
                ),
                qData.status + 1,
                qName,
                qData.hash,
            }

            i = i + 1
        end
    end

    local function RowConstructor(context, index)
        local widget = Widget("QuestBlock")
        widget.index = index

        widget.title = widget:AddChild(Text(UIFONT, 25, ""))
        widget.title:SetHAlign(ANCHOR_LEFT)
        widget.title:SetPosition(35, 0)
        widget.title:SetRegionSize(400, 30)

        widget.goal = widget:AddChild(Text(UIFONT, 20, ""))
        widget.goal:SetHAlign(ANCHOR_LEFT)
        widget.goal:SetPosition(35, -25)
        widget.goal:SetRegionSize(400, 20)

        widget.cancelButton = widget:AddChild(ImageButton("images/gfquestjournal.xml", "cancelbutton.tex", "cancelbutton.tex", nil, nil, nil, {1,1}, {0,0}))
        widget.cancelButton:SetPosition(-210, -15)
        widget.cancelButton:SetScale(0.5)

        return widget
    end

    local function ApplyFn(context, widget, data, index) 
        if data and not data.empty then 
            widget.title:SetColour(QCOLOUS[data[3]] or WHITE)
            widget.title:SetString(data[1] or "epmty")
            widget.goal:SetString(data[2] or "epmty")
            if data[3] ~= 3 then
                widget.cancelButton:Show()
                widget.cancelButton:SetOnClick(function() 
                    data[1] = data[1] .. " - cancelled"
                    data[3] = 3
                    CancelQuest(self.owner, data[4], data[5]) 
                    self.scroll:RefreshView()
                end)
            else
                widget.cancelButton:Hide()
                widget.cancelButton:SetOnClick()
            end
        else
            widget.cancelButton:Hide()
        end
    end

    local opts = 
    {
        context = {},
        widget_width  = 460,
        widget_height = 60,
        num_visible_rows = 6,
        num_columns = 1,
        item_ctor_fn = RowConstructor,
        apply_fn = ApplyFn,
        scrollbar_offset = -10,
        scrollbar_height_offset = -100,
    }

    if hasQuests then
        self.scroll = self.proot:AddChild(TEMPLATES.ScrollingGrid(self.strings, opts))
    else
        self.noquests = self.proot:AddChild(Text(UIFONT, 35, STRINGS.GF.HUD.JOURNAL.NOQUESTS))
        self.noquests:SetPosition(0, 140)
    end
end)

function QuestJournalScreen:Close()
    TheFrontEnd:PopScreen(self)
end

return QuestJournalScreen