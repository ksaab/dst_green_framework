--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

local Widget = require "widgets/widget"
local SpellButton = require "widgets/gf_spellbutton"
local Image = require "widgets/image"
local Text = require "widgets/text"
local SpellPanelBG = require "widgets/gf_spellpanel_bg"

local ALL_SPELLS = GF.GetSpells()

local SpellPanel = Class(Widget, function(self, owner)
	self.owner = owner
    Widget._ctor(self, "SpellPanel")

    self:SetPosition(-750, 170)
	self:MoveToBack()
    self:SetScale(0.9)
    self:Hide()

    self.lastSelect = 0 --delay for the spell selector
    self.active = false

    self.body = self:AddChild(SpellPanelBG(owner))
    
    self.hint = self:AddChild(Text(TALKINGFONT, 48))
    self.hint:SetHAlign(ANCHOR_LEFT)
    self.hint:SetRegionSize(2000, 50)
    
    --spell icons array
    self.body.icons = {}
    --controller hint
    self.spellString = self:AddChild(Widget("spellString"))
    self.spellString:Hide()
    --hint: spell name
    self.spellTitle = self.spellString:AddChild(Text(TALKINGFONT, 64))
    --hint: spell description
	self.spellDescription = self.spellString:AddChild(Text(TALKINGFONT, 64))
	self.spellDescription:SetPosition(0, -60)

    self.owner:ListenForEvent("gfSCPanelAdd", function(owner, data) self:AddSpell(data) end, self.owner)
    self.owner:ListenForEvent("gfSCPanelRemove", function(owner, data) self:RemoveSpell(data) end, self.owner)

    --need to update spells, event will be fired before this widget is ready
    if self.owner.replica.gfspellcaster ~= nil then
        for k, v in pairs(self.owner.replica.gfspellcaster.spells) do
            print(k, v)
            self:AddSpell({sName = k})
        end
    end
end)

function SpellPanel:AddSpell(data)
    if data == nil or data.sName == nil then return end
    --maybe we already have this spell on the panel
    for i, btn in ipairs(self.body.icons) do
        if btn.spell == data.sName then
            return
        end
    end

    --need to stop spell selection if panel is changed
    self:DisableSpellSelection()
    if self.owner.HUD ~= nil then self.owner.HUD:SetSpellSelection(false) end
    
    self:Show()

    local buttonsNum = #(self.body.icons)
    self.body:SetSize(buttonsNum + 1)

    local btn = self.body:AddChild(SpellButton(self.owner, self, data.sName, buttonsNum + 1))
    btn:SetPosition(78 * buttonsNum + 36, -12, 0)

    table.insert(self.body.icons, btn)
    self:SetHintPosition()
end

function SpellPanel:RemoveSpell(data)
    if data == nil or data.sName == nil then return end
    --maybe we don't have this spell on the panel
    local remove = false
    for i, btn in ipairs(self.body.icons) do
        if btn.spell == data.sName then
            btn:Kill()
            table.remove(self.body.icons, i)
            remove = true

            break
        end
    end

    if remove == false then return end --spell button not found
    
    --need to stop spell selection if panel is changed
    self:DisableSpellSelection()
    if self.owner.HUD ~= nil then self.owner.HUD:SetSpellSelection(false) end

    local buttonsNum = #(self.body.icons)
    self.body:SetSize(buttonsNum)

    --update icons position
    for i, btn in ipairs(self.body.icons) do
        btn:SetPosition(78 * (i - 1) + 36, -12, 0)
    end

    if buttonsNum == 0 then self:Hide() end
    self:SetHintPosition()
end

--rechrge watcher use this
function SpellPanel:GetIcons()
    return self.body.icons
end

function SpellPanel:IsActive()
    return self.active
end

function SpellPanel:EnableSpellSelection()
    if #(self.body.icons) == 0 or self.active then return false end

    self:SelectSpell()

    for i = 1, 4 do
        if self.body.icons[i] ~= nil then self.body.icons[i]:SetHint(true) end
    end

    self.active = true
    self.spellString:Show()
    self:StartUpdating()

    return true
end

function SpellPanel:DisableSpellSelection()
    if self.activeBtn ~= nil then
        self.activeBtn:DeHighlight()
        self.activeBtn = nil
        self.activeIcon = nil
    end

    for i = 1, 4 do
        if self.body.icons[i] ~= nil then self.body.icons[i]:SetHint(false) end
    end

    self.active = false
    self.spellString:Hide()
    self:StopUpdating()
end

--navigation, not "use the spell thing"
function SpellPanel:SelectSpell(prev)
    local nextIcon = (prev == true) and -1 or 1
    nextIcon = (self.activeIcon ~= nil) and self.activeIcon + nextIcon or 1
    nextIcon = math.min(#(self.body.icons), math.max(1, nextIcon))
    self.lastSelect = GetTime() + 0.3

    if nextIcon == self.activeIcon then return true end

    --print(self.body.icons[nextIcon].spell, self.body.icons[nextIcon].num)

    self.activeIcon = nextIcon
    if self.activeBtn ~= nil then self.activeBtn:DeHighlight() end
    self.activeBtn = self.body.icons[nextIcon]
    self.activeBtn:Highlight()
end

--"use the spell thing"
function SpellPanel:UseActiveSpell()
    if self.activeBtn ~= nil then  
        self.activeBtn:CastSpell() 
    end
    self:DisableSpellSelection()
end

function SpellPanel:UseSpell(n)
    if self.body.icons[n] ~= nil then  
        self.body.icons[n]:CastSpell() 
    end
    self:DisableSpellSelection()
end

function SpellPanel:SwapIcons(source, right)
    local target = (right == true) and source + 1 or source - 1
    local icons = self.body.icons
    if target > 0 and target <= #(icons) then
        --print(icons[source].spell, icons[source].num, "<->", icons[target].spell, icons[target].num)

        local tmp = icons[source]
        icons[source] = icons[target]
        icons[target] = tmp

        icons[source]:UpdatePosition(source)
        icons[target]:UpdatePosition(target)

        self.activeIcon = target
        self.activeBtn = icons[target]
        self.lastSelect = GetTime() + 0.3
    end
end

function SpellPanel:SetHintPosition()
    print(78 * (#(self.body.icons) - 1) - 86, -12, 0)
    self.hint:SetPosition(78 * (#(self.body.icons) - 1) + 1136, -12, 0)
end

function SpellPanel:SetHint(val)
    if not val then
        self.hint:Hide()
        self.hint:SetString("")
    else
        self.hint:Show()
        if TheInput:ControllerAttached() then
            local controller_id = TheInput:GetControllerID()
            if #(self.body.icons) == 1 then
                self.hint:SetString(string.format(
                    "%s - Use    %s - Cancel",
                    TheInput:GetLocalizedControl(controller_id, CONTROL_CONTROLLER_ACTION),
                    TheInput:GetLocalizedControl(controller_id, CONTROL_CONTROLLER_ALTACTION)
                ))
            else
                self.hint:SetString(string.format(
                    "%s - Use    %s - Cancel    %s %s - Select    %s %s - Swap",
                    TheInput:GetLocalizedControl(controller_id, CONTROL_CONTROLLER_ACTION),
                    TheInput:GetLocalizedControl(controller_id, CONTROL_CONTROLLER_ALTACTION),
                    TheInput:GetLocalizedControl(controller_id, CONTROL_INVENTORY_LEFT),
                    TheInput:GetLocalizedControl(controller_id, CONTROL_INVENTORY_RIGHT),
                    TheInput:GetLocalizedControl(controller_id, CONTROL_INVENTORY_UP),
                    TheInput:GetLocalizedControl(controller_id, CONTROL_INVENTORY_DOWN)
                ))
            end
        else
            self.hint:SetString(#(self.body.icons) == 1 and "LMB - Use" or "LMB - Use / RMB - Move Left")
        end
    end
end

function SpellPanel:ControllerSwapIcon(right)
    if self.activeIcon == nil or self.activeBtn == nil then return end
    self.activeBtn:DeHighlight()
    self:SwapIcons(self.activeIcon, right)
    if self.activeBtn ~= nil then self.activeBtn:Highlight() end
    for i = 1, #(self.body.icons) do
        self.body.icons[i]:SetHint(true)
    end
end

function SpellPanel:GetActiveIconPosition()
    if self.activeBtn ~= nil then 
        return self.activeBtn:GetPosition() 
    end
end

function SpellPanel:GetActiveIconText()
    if self.activeBtn ~= nil then 
        return self.activeBtn:GetTextLines()
    end
end

function SpellPanel:OnUpdate()
    if not TheInput:ControllerAttached() then 
        if self.owner.HUD ~= nil then self.owner.HUD:SetSpellSelection(false) end
        self:DisableSpellSelection()
    end

    local pos = self:GetActiveIconPosition()
    if pos == nil or not self.shown then return end

    pos.y = pos.y + 160
    self.spellString:SetPosition(pos)

    local controller_id = TheInput:GetControllerID()
    local title, desc = self:GetActiveIconText()

    if self._prevActive ~= self.activeBtn then
        self.spellTitle:SetString(title)
        self.spellDescription:SetString(desc)
        self._prevActive = self.activeBtn
    end

    if GetTime() > self.lastSelect then
        if TheInput:IsControlPressed(CONTROL_INVENTORY_LEFT) then
            self:SelectSpell(true)
        elseif TheInput:IsControlPressed(CONTROL_INVENTORY_RIGHT) then
            self:SelectSpell(false)
        elseif TheInput:IsControlPressed(CONTROL_INVENTORY_UP) then
            self:ControllerSwapIcon(true)
        elseif TheInput:IsControlPressed(CONTROL_INVENTORY_DOWN) then
            self:ControllerSwapIcon(false)
        end
    end
end

return SpellPanel