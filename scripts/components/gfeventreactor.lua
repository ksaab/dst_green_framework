--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

local Reaction = require("gf_reaction")

local function ForceEquipReaction(inst, react)
    if inst.components.equippable and inst.components.equippable:IsEquipped() then
        react:React(inst, inst.components.inventoryitem.owner)
    end
end

local function DoReact(inst, event, data)
    for k, v in pairs(inst.components.gfeventreactor.reactions[event]) do
        if v.target == "self" then
            v:React(inst, inst, data)
        elseif data[v.target] ~= nil then
            v:React(inst, data[v.target], data)
        else
            GFDebugPrint(("GFEventReactor: can't react on %s, target %s is not valid"):format(event, v.target))
        end
    end
end

local GFEventReactor = Class(function(self, inst)
    self.inst = inst
    self.reactions = {}
    self.callbacks = {}
end)

function GFEventReactor:AddReaction(name, data)
    if data == nil or name == nil then 
        GFDebugPrint("GFEventReactor: failed to attach reaction, name or data is invalid")
        return
    end

    local react = Reaction(name, data)
    if react.fail then
        GFDebugPrint("GFEventReactor: reaction isn't valid")
        react = nil
        return
    end

    local event = react.event

    if self.reactions[event] == nil then
        self.reactions[event] = {}
        self.callbacks[event] = function(inst, data)
            DoReact(inst, event, data)
        end
        self.inst:ListenForEvent(event, self.callbacks[event])
    end

    if event == "equipped" then
        ForceEquipReaction(self.inst, react)
    end

    self.reactions[event][name] = react

    self.inst:PushEvent("scnewreaction", {name = name, event = event})
    --GFDebugPrint(("GFEventReactor: reaction %s added on event %s"):format(name, event))
end

function GFEventReactor:GetReactionCount(type)
    local count = 0

    if type ~= nil then
        if self.reactions[type] ~= nil then
            for _, _ in pairs(self.reactions[type]) do
                count = count + 1
            end
        end
    else
        for _, reactGroup in pairs(self.reactions) do
            for _, _ in pairs(reactGroup) do
                count = count + 1
            end
        end
    end

    return count
end

function GFEventReactor:RemoveCallback(type)
    --GFDebugPrint("GFEventReactor: remove callback", type)
    if type then
        self.inst:RemoveEventCallback(type, self.callbacks[type])
        self.callbacks[type] = nil
        self.reactions[type] = nil
    end
end

function GFEventReactor:RemoveReaction(name, type)
    --GFDebugPrint("GFEventReactor: remove reaction", name)
    if type then
        if self.reactions[type] ~= nil and self.reactions[type][name] ~= nil then
            if type == "unequipped" then
                ForceEquipReaction(self.inst, self.reactions[type][name])
            end
            self.reactions[type][name] = nil
            if self:GetReactionCount(type) == 0 then
                self:RemoveCallback(type)
            end

            self.inst:PushEvent("screactionremoved", {name = name, type = type})
        end
    else
        for type, group in pairs(self.reactions) do
            if group[name] ~= nil then
                if type == "unequipped" then
                    ForceEquipReaction(self.inst, group[name])
                end
                group[name] = nil
                if self:GetReactionCount(type) == 0 then
                    self:RemoveCallback(type)
                end

                self.inst:PushEvent("screactionremoved", {name = name, type = type})
            end
        end
    end
end

function GFEventReactor:OnRemoveFromEntity()
    for type, group in pairs(self.reactions) do
        group = nil
        self:RemoveCallback(type)
    end
end

--DEBUG-----------------
------------------------
function GFEventReactor:GetDebugString()
    local str = {}
    for k, type in pairs(self.reactions) do
        for name, v2 in pairs(type) do 
           table.insert(str, string.format("[%s: %s]", k, name))
       end
    end
    return table.concat(str, ", ")
end

return GFEventReactor