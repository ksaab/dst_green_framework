local ALL_DIALOGUE_NODES =  GF.GetDialogueNodes()
local DIALOGUE_NODES_IDS =  GF.GetDialogueNodesIDs()
local defaultNode = ALL_DIALOGUE_NODES["default_node"] --require "ALL_DIALOGUE_NODES/default_node"

local GFInterlocutor = Class(function(self, inst)
    self.inst = inst

    self.phrase = "DEFAULT"
    self.conversations = {}
    self.isBusy = false
    self.defaultNode = false

    self.mood = {}
    self.wantsToTalkFn = nil

    self._interruptedFn = function() 
        if self._interlocutor ~= nil and self._interlocutor.components.gfplayerdialog ~= nil then
            self._interlocutor.components.gfplayerdialog:TrackFail()
        end
        self:RemoveListeners() 
    end

    self._interlocutor = nil

    inst:AddTag("hasdialog")
end)

function GFInterlocutor:AddConversation(conv)
    if ALL_DIALOGUE_NODES[conv] ~= nil then
        if #(self.conversations) > 0 then
            local p = ALL_DIALOGUE_NODES[conv].priority
            for k, v in pairs(self.conversations) do
                if p > v.priority then
                    table.insert(self.conversations, k, ALL_DIALOGUE_NODES[conv])
                    return
                end
            end
        end

        table.insert(self.conversations, ALL_DIALOGUE_NODES[conv])
    end
end

function GFInterlocutor:RemoveConversation(conv)
    for i = #(self.conversations), 1, -1 do
        if self.conversations[i].name == conv then table.remove(self.conversations, i) end
    end
end

function GFInterlocutor:WantsToTalk(doer)
    local inst = self.inst
    return  inst:HasTag("hasdialog") 
            and not self.isBusy
            and (self.wantsToTalkFn == nil         or self.wantsToTalkFn(doer, inst))
            and (inst.components.combat == nil     or inst.components.combat.target == nil) 
            and (inst.components.burnable == nil   or not inst.components.burnable:IsBurning()) 
            and (inst.components.freezable == nil  or not inst.components.freezable:IsFrozen()) 
            and (inst.components.sleeper == nil    or not inst.components.sleeper:IsAsleep()) 
            and (inst.components.health == nil     or not inst.components.health:IsDead())
end

function GFInterlocutor:SetMoodUpdateFn(event, fn)
    if event == nil or fn == nil then return end
    self.inst:WatchWorldState(event or "cycle", fn)
end

function GFInterlocutor:SetMood(mood, val)
    self.mood[mood] = val
end

function GFInterlocutor:GetMood(mood)
    return self.mood[mood] == true
end

function GFInterlocutor:CheckMood(node)
    if node.moodReqs ~= nil then 
        for _, mood in pairs(node.moodReqs) do
            if not self:GetMood(mood) then return false end
        end
    end

    return true
end

function GFInterlocutor:StartConversation(doer)
    if doer == nil 
        or doer.components.gfplayerdialog == nil 
        or not doer:IsValid()
        or not self.inst:IsValid()
        or not self:WantsToTalk(doer)
    then 
        return false
    end

    for k, v in pairs(self.conversations) do
        if self:CheckMood(v) and v:PreCheck(doer, self.inst) then
            self.isBusy = true
            v:RunNode(doer, self.inst)
            return true
        end
    end

    if self.defaultNode then
        self.isBusy = true
        defaultNode:RunNode(doer, self.inst)
        return true
    end

    return false
end

function GFInterlocutor:RemoveListeners()
    self.inst:RemoveEventCallback("attacked",    self._interruptedFn)
    self.inst:RemoveEventCallback("death",       self._interruptedFn)
    self.inst:RemoveEventCallback("onremove",    self._interruptedFn)
    self.inst:RemoveEventCallback("newtarget",   self._interruptedFn)
    self.inst:RemoveEventCallback("stopconversation",   self._interruptedFn)

    self._interlocutor = nil
    self.isBusy = false
end

function GFInterlocutor:SetListeners(doer)
    self.isBusy = true
    self._interlocutor = doer

    self.inst:ListenForEvent("attacked",    self._interruptedFn)
    self.inst:ListenForEvent("death",       self._interruptedFn)
    self.inst:ListenForEvent("onremove",    self._interruptedFn)
    self.inst:ListenForEvent("newtarget",   self._interruptedFn)
    self.inst:ListenForEvent("stopconversation",   self._interruptedFn)
end

function GFInterlocutor:SetReactFn(fn)
    local function _fn(inst, data) 
        self.getAttentionFn(inst, data)
    end

    if fn ~= nil then
        self.getAttentionFn = fn
        self.inst:ListenForEvent("gfQGGetAttention", _fn)
    else
        self.inst:RemoveEventCallback("gfQGGetAttention", _fn)
    end
end

function GFInterlocutor:GetString()
    return self.phrase
end

function GFInterlocutor:GetDebugString()
    local moods = {}
    for mood, _ in pairs(self.mood) do
        table.insert(moods, mood)
    end

    local node = {}
    for _, cNode in pairs(self.conversations) do
        table.insert(node, cNode.name)
    end

    return string.format("%s mood: %s nodes: %s", tostring(self.inst:HasTag("hasdialog")), table.concat(moods, ", "), table.concat(node, ", "))
end

return GFInterlocutor