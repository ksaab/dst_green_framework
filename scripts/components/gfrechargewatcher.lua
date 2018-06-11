local function UpdateRechareable(inst)
    GFDebugPrint("GFRechargeWatcher updated")
    inst:DoTaskInTime(0, function(inst)
        local self = inst.components.gfrechargewatcher
        self:UpdateRechareableList()
    end)
end

local GFRechargeWatcher = Class(function(self, inst)
    self.inst = inst
    self.itemList = {}
    self.iconList = {}

    UpdateRechareable(inst)

    inst:StartUpdatingComponent(self)
    inst:ListenForEvent("itemget", UpdateRechareable)
    --inst:ListenForEvent("itemlose", UpdateRechareable)
    inst:ListenForEvent("gfsc_updaterechargesdirty", UpdateRechareable)
    inst:ListenForEvent("gfsc_updatespelllist", UpdateRechareable)
end)

function GFRechargeWatcher:UpdateRechareableList()
    local inst = self.inst
    self.itemList = {}
    self.iconList = {}
    local function CheckHUD()
        for k, icon in pairs(inst.HUD.controls.spellPanel.iconsPanel.icons) do
            if icon.spell ~= nil then
                local remain, total = inst.replica.gfspellcaster:GetSpellRecharge(icon.spell)
                if remain > 0 then
                    icon:RechargeStarted()
                    table.insert(self.iconList, {icon = icon, remain = remain, total = total})
                    GFDebugPrint(("GFRechargeWatcher: %s adding %s [%.2f/%.2f] to recharge list."):format(tostring(inst),
                        tostring(icon), remain, total))
                end
            end
        end
    end

    local function CheckItems(items)
        for _, item in pairs(items) do
            local scr = item.replica.gfspellitem
            if scr then
                item:PushEvent("rechargechange", { percent = 1 })
                --[[ local spell = item.replica.gfspellitem:GetItemSpellName()
                if spell
                    and (not item.replica.gfspellitem:CanCastSpell(spell)
                        or not self.inst.replica.gfspellcaster:CanCastSpell(spell))
                then
                    local remain, total = item.replica.gfspellitem:GetSpellRecharge(spell)
                    local oremain, ototal = inst.replica.gfspellcaster:GetSpellRecharge(spell)
                    remain = remain >= oremain and remain or oremain 
                    total = total >= ototal and total or ototal 
                    table.insert(self.itemList, {item = item, remain = remain, total = total})
                    GFDebugPrint(("GFRechargeWatcher: %s adding %s [%.2f/%.2f] to recharge list."):format(tostring(inst),
                        tostring(item), remain, total))
                end ]]
                local spell = item.replica.gfspellitem:GetItemSpellName()
                if spell then
                    local remain, total = item.replica.gfspellitem:GetSpellRecharge(spell)
                    local oremain, ototal = inst.replica.gfspellcaster:GetSpellRecharge(spell)
                    if remain > 0 or oremain > 0 then
                        remain = remain >= oremain and remain or oremain 
                        total = total >= ototal and total or ototal 
                        table.insert(self.itemList, {item = item, remain = remain, total = total})
                        GFDebugPrint(("GFRechargeWatcher: %s adding %s [%.2f/%.2f] to recharge list."):format(tostring(inst),
                            tostring(item), remain, total))
                    end
                end
            end
        end
    end

    local inv = self.inst.replica.inventory
    if inv then
        CheckItems(inv:GetItems())
        CheckItems(inv:GetEquips())
    end

    if inst.HUD and inst.HUD.controls and inst.HUD.controls.spellPanel and inst.HUD.controls.spellPanel.iconsPanel.icons then
        CheckHUD()
    end
end

function GFRechargeWatcher:OnUpdate(dt)
    local inst = self.inst
    if inst.replica.inventory then
        for k, line in pairs(self.itemList) do 
            if line.item and line.item:IsValid() then
                line.remain = math.max(0, line.remain - dt)
                local percent = 1 - math.min(1, math.max(line.remain / line.total, 0))
                --print(percent)
                line.item:PushEvent("rechargechange", { percent = percent })
                if percent >= 1 then
                    table.remove(self.itemList, k)
                    GFDebugPrint(("GFRechargeWatcher: removing %s from list."):format(tostring(line.item)))
                end
            else
                table.remove(self.itemList, k)
            end
        end
    end

    if inst.HUD and inst.HUD.controls then
        for k, line in pairs(self.iconList) do 
            line.remain = math.max(0, line.remain - dt)
            local percent = 1 - math.min(1, math.max(line.remain / line.total, 0))
            if percent < 1 then
                line.icon:RechargeTick(percent)
            else
                table.remove(self.iconList, k)
                line.icon:RechargeDone()
                GFDebugPrint(("GFRechargeWatcher: removing %s from list."):format(tostring(line.icon)))
            end
        end
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