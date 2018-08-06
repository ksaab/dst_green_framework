--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

local spellList = GFSpellList
local spellIDToNames = GFSpellIDToName
local spellNamesToID = GFSpellNameToID

local function DisablePointerOnUnequipped(inst)
    local self = inst.components.gfspellpointer
    if self:IsEnabled() then
        self:Disable()
    end
end

local function OnDirty(inst)
    if inst ~= ThePlayer then return end

    local self = inst.components.gfspellpointer
    local spellID = self._currentSpell:value()
    --GFDebugPrint(string.format("GFSpellPointer: dirty (client/host) for %s, spell id %s", tostring(self.inst), spellID))
    if spellID ~= 0 then
        self:StartTargeting(spellIDToNames[spellID])
    else
        self:StopTargeting()
    end
end

local function OverrideLeftMouseActions(inst, target, position)
    local self = inst.components.gfspellpointer
    --clents and host get the data directly from the Pointer
    --server get data from ActionPicker, because the Pointer is a local-only thing
    local pointer = self.pointer or 
    {
        targetEntity = target, 
        targetPosition = position, 
        positionValid = self.map:IsPassableAtPoint(position:Get()) 
            and not self.map:IsGroundTargetBlocked(position)
    }

    local spellName = self.currentSpell

    --we cant cast on non-valid ground or if the spell isn't setted
    if spellName == nil 
        or not pointer.positionValid 
    then 
        return {} --nil, true
    end

    --this part is pretty wierd, but I can't find the better way to deal with item/non-item casts
    ----------------------------------------
    --[[ local equipitem = self.inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

    local item = (equipitem 
        and equipitem.components.gfspellitem 
        and equipitem.components.gfspellitem.spells[spellName] ~= nil)
    and equipitem
    or nil ]]
    ----------------------------------------
    ----------------------------------------

    local item = self.withItem and self.inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or nil

    --check  for recharges, may be it should be removed (can't start targeting while spell is recharging,
    --the action also will check it to prevent any abuses
    if not inst.replica.gfspellcaster:CanCastSpell(spellName) 
        or (item and not item.replica.gfspellitem:CanCastSpell(spellName))
    then 
        self:Disable()
        return {} --nil, true
    end
       
    if pointer.targetEntity then
        return inst.components.playeractionpicker:SortActionList({ ACTIONS.GFCASTSPELL }, pointer.targetEntity, item)
    elseif not spellList[spellName].needTarget then -- can't cast spell that requires target on the ground
        return inst.components.playeractionpicker:SortActionList({ ACTIONS.GFCASTSPELL }, pointer.targetPosition, item)
    end 
end

local function OverrideRightMouseActions(inst, target, position)
    --print("OverrideRightMouseActions")
    return inst.components.playeractionpicker:SortActionList({ ACTIONS.GFSTOPSPELLTARGETING }, position, nil)
end

--[[ local function OverrideActionButton(inst, target)
    --print(target, position)
    local self = inst.components.gfspellpointer
    local spellName = self.currentSpell

    if spellName == nil then return end

    local spell = spellList[spellName]
    local item
    local equipitem = self.inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    
    if equipitem 
        and equipitem.components.gfspellitem 
        and equipitem.components.gfspellitem.spells[spellName] ~= nil
    then
        item = equipitem
    end

    if inst.replica.gfspellcaster:CanCastSpell(spellName)
        and not (item and not item.replica.gfspellitem:CanCastSpell(spellName)) 
    then
        if spell.needTarget then
            local x, y, z = inst.Transform:GetWorldPosition()
            local ents = TheSim:FindEntities(x, y, z, math.min(spell.range, 20), nil, {"plyerghost", "corpse", "FX", "NOCLICK", "shadow"})
            local nonCombat = {}
            for i, v in pairs(ents) do
                if v ~= inst and v.entity:IsVisible() and CanEntitySeeTarget(inst, v) then
                    if v.components.combat then
                        return BufferedAction(inst, v, ACTIONS.GFCASTSPELL, item)
                    end
                    table.insert(nonCombat, v)
                end
            end
            if #nonCombat > 0 then
                return BufferedAction(inst, nonCombat[1], ACTIONS.GFCASTSPELL, item)
            end
        elseif self.pointer ~= nil then
            print("OverrideActionButton")
            local pos = self.pointer.targetPosition
            return BufferedAction(inst, nil, ACTIONS.GFCASTSPELL, item, pos)
        end 
    end
end ]]

local function EnableSpellTargetingActions(inst)
    --[[ if inst.components.playeractionpicker then
        inst.components.playeractionpicker.leftclickoverride = OverrideLeftMouseActions
        inst.components.playeractionpicker.rightclickoverride = OverrideRightMouseActions
    end ]]
    --if inst.components.playercontroller then
        --inst.components.playercontroller.actionbuttonoverride = OverrideActionButton
    --end
end

local function DisableSpellTargetingActions(inst)
    --[[ if inst.components.playeractionpicker then
        inst.components.playeractionpicker.leftclickoverride = nil
        inst.components.playeractionpicker.rightclickoverride = nil
    end ]]
    --if inst.components.playercontroller then
        --inst.components.playercontroller.actionbuttonoverride = nil
    --end
end

local DisablePointerOnDeath = DisableSpellTargetingActions

local GFSpellPointer = Class(function(self, inst)
    self.inst = inst
    self.map = TheWorld.Map
    self.currentSpell = nil
    self.pointer = nil
    self.withItem = false

    self._currentSpell = net_int(inst.GUID, "GFSpellPointer._currentSpell", "gfspellpointerdirty")
    self._currentSpell:set_local(0)

    if GFGetIsMasterSim() then
        inst:ListenForEvent("unequip", DisablePointerOnUnequipped)
        inst:ListenForEvent("death", DisablePointerOnDeath)
    end
    --[[ if inst.components.gfpointer then
        self.pointer = self.inst.components.gfpointer
        inst:ListenForEvent("gfspellpointerdirty", OnDirty)
    end ]]
    if not GFGetIsDedicatedNet() and inst == ThePlayer then
        inst:ListenForEvent("gfspellpointerdirty", OnDirty)
        inst:AddComponent("gfpointer")
        self.pointer = self.inst.components.gfpointer
    end
end)

function GFSpellPointer:SetOnClient()
    self.inst:ListenForEvent("gfspellpointerdirty", OnDirty)
    self.inst:AddComponent("gfpointer")
    self.pointer = self.inst.components.gfpointer
end

function GFSpellPointer:IsEnabled()
    return self.currentSpell ~= nil
end

function GFSpellPointer:Enable(spellName)
    local pc = self.inst.components.playercontroller
    if spellName ~= nil 
        and spellList[spellName] ~= nil --spell isn't exists
        --and self.currentSpell ~= spellName -- current spell is the same
        and GFGetIsMasterSim()
        and pc and pc:IsEnabled() --check controller, we don't need to target if it's not valid
    then 
        --GFDebugPrint(string.format("GFSpellPointer: ENABLE pointer (server) for %s, spell %s", tostring(self.inst), spellName))
        self._currentSpell:set(spellNamesToID[spellName])
        self.currentSpell = spellName
        --EnableSpellTargetingActions(self.inst)
        pc.gfSpellPointerEnabled = true
    end 
end

function GFSpellPointer:Disable()
    if GFGetIsMasterSim() then
        --GFDebugPrint(string.format("GFSpellPointer: DISABLE pointer (server) for %s", tostring(self.inst)))
        self._currentSpell:set(0)
        self.currentSpell = nil
        self.withItem = false
        --DisableSpellTargetingActions(self.inst)
        if self.inst.components.playercontroller then
            self.inst.components.playercontroller.gfSpellPointerEnabled = false
        end
    else
        SendModRPCToServer(MOD_RPC["Green Framework"]["GFDISABLEPOINTER"])
    end
end

function GFSpellPointer:StartTargeting(spellName)
    --check controller, we don't need to target if it's not valid
    local pc = self.inst.components.playercontroller
    if not (pc and pc:IsEnabled()) then 
        self:Disable()
        return 
    end

    --GFDebugPrint(string.format("GFSpellPointer: Start Targeting (client/host) for %s, spell %s", tostring(self.inst), spellName))
    if not GFGetIsMasterSim() then
        --the host toggled these params when ran the Enable function
        --EnableSpellTargetingActions(self.inst)
        self.currentSpell = spellName
        pc.gfSpellPointerEnabled = true
    end
    
    if self.inst.components.gfpointer then
        self.pointer:Destroy()
        --self.inst:RemoveComponent("gfpointer")
        --self.pointer = nil
        --GFDebugPrint(string.format("GFSpellPointer: Dummy — disable pointer for %s, reason: spell changed",  tostring(self.inst)))
    end

    self.pointer:Create(spellList[spellName].pointer)
    --GFDebugPrint(string.format("GFSpellPointer: Dummy — enable pointer for %s",  tostring(self.inst)))
end

function GFSpellPointer:StopTargeting()
    --GFDebugPrint(string.format("GFSpellPointer: Stop Targeting (client/host) for %s", tostring(self.inst)))
    if not GFGetIsMasterSim() then
        --DisableSpellTargetingActions(self.inst)
        self.currentSpell = nil
        if self.inst.components.playercontroller then
            self.inst.components.playercontroller.gfSpellPointerEnabled = false
        end
    end

    if self.pointer ~= nil then
        self.pointer:Destroy()
        --self.pointer = nil
        --self.inst:RemoveComponent("gfpointer")
    end

    --print(string.format("GFSpellPointer: Dummy — disable pointer for %s, reason: canceled",  tostring(self.inst)))
end

function GFSpellPointer:GetControllerPointActions(position)
    local left = OverrideLeftMouseActions(self.inst, nil, position)[1]
    local right = OverrideRightMouseActions(self.inst, nil, position)[1]
    return left, right
end

function GFSpellPointer:CollectLeftActions(position, target)
    return OverrideLeftMouseActions(self.inst, target, position)
end

function GFSpellPointer:CollectRightActions(position, target)
    return OverrideRightMouseActions(self.inst, target, position)
end

function GFSpellPointer:OnRemoveFromEntity()
    if self.inst.components.playercontroller then
        self.inst.components.playercontroller.gfSpellPointerEnabled = false
    end
    self:Disable()
    if GFGetIsMasterSim() then
        self.inst:RemoveEventCallback("unequipped", DisablePointerOnUnequipped)
    end

    if not GFGetIsDedicatedNet() then
        self.inst:RemoveEventCallback("gfspellpointerdirty", OnDirty)
    end
end

function GFSpellPointer:GetDebugString()
    return string.format("enabled: %s, pointer %s, spell: %s", 
        tostring(self:IsEnabled()), tostring(self.pointer or "none"), self.currentSpell or "none")
end

return GFSpellPointer
