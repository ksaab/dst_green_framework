local Widget = require "widgets/widget"
local Text = require "widgets/text"
local TEMPLATES = require "widgets/redux/templates"

local ALL_QUESTS = GF.GetQuests()
local MAX_LIFETIME = 5

local INVALID_TITLE = STRINGS.GF.HUD.INVALID_LINES.INVALID_TITLE

--TODO - rewrite this mess
local QEVENTS = 
{
    [1] = STRINGS.GF.HUD.QUEST_INFORMER.QUEST_UNDONE,
    [2] = STRINGS.GF.HUD.QUEST_INFORMER.QUEST_DONE,
    [3] = STRINGS.GF.HUD.QUEST_INFORMER.QUEST_FAILED,
    [4] = STRINGS.GF.HUD.QUEST_INFORMER.QUEST_STARTED,
    [5] = STRINGS.GF.HUD.QUEST_INFORMER.QUEST_ABANDONED,
}

local QuestInformer = Class(Widget, function(self, owner)
    self.owner = owner
    Widget._ctor(self, "QuestInformer")

    self:SetPosition(0, -100)

    self.lineCount = 3
    self.textLines = {}

    for i = 1, self.lineCount do
        self.textLines[i] = self:AddChild(Text(UIFONT, 25, ""))
        local line = self.textLines[i]
        line:SetString("string" .. tostring(i))
        line:SetPosition(0, -(i - 1) * 35)
        line.lifetime = 0
        line.showed = false
        line:Hide()
    end

    self.inst:ListenForEvent( "gfQSInformerPush", function(player, data) self:RefreshLines(data) end, self.owner)
    self:StartUpdating()

    print("Quest informer was added to ", owner)
end)

function QuestInformer:RefreshLines(data)
    if data == nil or self.owner.replica.gfquestdoer == nil then return end

    local qString = self.owner.replica.gfquestdoer:GetInformerLine(data.qEvent, data.qName, data.qKey)
    if qString ~= nil and qString ~= self.textLines[1]:GetString() then        --don't want to show repeated lines
        for i = self.lineCount, 2, -1 do                    --move old strings down
            local str = self.textLines[i - 1]:GetString()
            if str ~= "" then
                local line = self.textLines[i]
                line:SetString(str)
                line:Show()
                line.lifetime = self.textLines[i - 1].lifetime
                line.showed = true
            end
        end

        if self.textLines[1]:GetString() == "" then
            self:StartUpdating()
        end

        local line = self.textLines[1]
        line:SetString(qString)
        line:Show()
        line.lifetime = MAX_LIFETIME
        line.showed = true
    end
end

function QuestInformer:OnUpdate(dt)
    for i = self.lineCount, 1, -1 do
        local line = self.textLines[i]
        if line.showed then
            if line.lifetime > 0 then
                line:SetAlpha(math.min(1, line.lifetime))
                line.lifetime = line.lifetime - dt
            else
                if i == 1 then
                    self:StopUpdating()
                end
                line:Hide()
                line:SetString()
                line.showed = false
            end
        end
    end
end

return QuestInformer