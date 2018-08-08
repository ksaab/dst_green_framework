--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.
local function ReplicaReferenceAllItems(inst)
    local inv = inst.replica.inventory
    local items = {}
    if inv ~= nil then
        for _, v in pairs(inv:GetItems()) do
            table.insert(items, v)
        end
        for _, v in pairs(inv:GetEquips()) do
            table.insert(items, v)
        end
        for _, v in pairs(inv:GetOverflowContainer()) do
            table.insert(items, v)
        end
    end

    return items
end

local function UpdateRechareable(inst)
    inst:DoTaskInTime(0, function(inst)
        local self = inst.components.gfrechargewatcher
        self:UpdateRechareableList()
    end)
end

local function CheckItemBeforeUpdate(inst, data)
    if data and data.item and data.item.replica.gfspellitem then
        UpdateRechareable(inst)
    end
end

local GFRechargeWatcher = Class(function(self, inst)
    self.inst = inst
    self.itemList = {}
    self.iconList = {}

    inst:StartUpdatingComponent(self)
    inst:ListenForEvent("itemget", CheckItemBeforeUpdate)
    inst:ListenForEvent("gfupdaterechargesdirty", UpdateRechareable)
    inst:ListenForEvent("gfupdatespellshud", UpdateRechareable)

    UpdateRechareable(inst)
    --self.inst:DoTaskInTime(3, UpdateRechareable)
end)

function GFRechargeWatcher:UpdateRechareableList()
    local inst = self.inst
    self.itemList = {}
    self.iconList = {}
    local function CheckHUD()
        for k, icon in pairs(inst.HUD.controls.gf_spellPanel.iconsPanel.icons) do
            if icon.spell ~= nil then
                local remain, total = inst.replica.gfspellcaster:GetSpellRecharge(icon.spell)
                if remain > 0 then
                    icon:RechargeStarted()
                    table.insert(self.iconList, {icon = icon, remain = remain, total = total})
                    --GFDebugPrint(("GFRechargeWatcher: %s adding %s [%.2f/%.2f] to recharge list."):format(tostring(inst),
                        --tostring(icon), remain, total))
                end
            end
        end
    end

    local function CheckItems(items)
        for _, item in pairs(items) do
            local scr = item.replica.gfspellitem
            if scr then
                item:PushEvent("rechargechange", { percent = 1 })
                local spell = item.replica.gfspellitem:GetItemSpellName()
                if spell then
                    local remain, total = item.replica.gfspellitem:GetSpellRecharge(spell)
                    local oremain, ototal = inst.replica.gfspellcaster:GetSpellRecharge(spell)
                    if remain > 0 or oremain > 0 then
                        remain = remain >= oremain and remain or oremain 
                        total = total >= ototal and total or ototal 
                        table.insert(self.itemList, {item = item, remain = remain, total = total})
                        --GFDebugPrint(("GFRechargeWatcher: %s adding %s [%.2f/%.2f] to recharge list."):format(tostring(inst),
                            --tostring(item), remain, total))
                    end
                end
            end
        end
    end

    local inv = self.inst.replica.inventory
    if inv then
        CheckItems(inv:GetItems())
        CheckItems(inv:GetEquips())
        local cont = inv:GetOverflowContainer()
        if cont ~= nil then
            CheckItems(cont:GetItems())
        end
    end

    if inst.HUD and inst.HUD.controls and inst.HUD.controls.gf_spellPanel and inst.HUD.controls.gf_spellPanel.iconsPanel.icons then
        CheckHUD()
    end
end

function GFRechargeWatcher:OnUpdate(dt)
    local inst = self.inst
    --updating inventory items cooldowns
    if inst.replica.inventory then
        for k, line in pairs(self.itemList) do 
            if line.item and line.item:IsValid() then
                line.remain = math.max(0, line.remain - dt)
                local percent = 1 - math.min(1, math.max(line.remain / line.total, 0))
                line.item:PushEvent("rechargechange", { percent = percent })
                if percent >= 1 then
                    table.remove(self.itemList, k)
                    --GFDebugPrint(("GFRechargeWatcher: removing %s from list."):format(tostring(line.item)))
                end
            else
                table.remove(self.itemList, k)
            end
        end
    else
        self.itemList = {}
    end

    --updating spell panel cooldowns
    if inst.HUD and inst.HUD.controls then
        for k, line in pairs(self.iconList) do 
            line.remain = math.max(0, line.remain - dt)
            local percent = 1 - math.min(1, math.max(line.remain / line.total, 0))
            if percent < 1 then
                line.icon:RechargeTick(percent)
            else
                table.remove(self.iconList, k)
                line.icon:RechargeDone()
                --GFDebugPrint(("GFRechargeWatcher: removing %s from list."):format(tostring(line.icon)))
            end
        end
    else
        self.iconList = {}
    end
end

function GFRechargeWatcher:GetDebugString()
    local inst = self.inst
    local str = {}
    for k, item in pairs(self.itemList) do
        table.insert(str, ("[%s %.2f/%.2f]"):format(tostring(item.item), item.remain, item.total))
    end

    return #str > 0 and ("Watching for: %s"):format(table.concat(str, ", ")) or "none"
end


return GFRechargeWatcher