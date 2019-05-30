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
            self._interlocutor.components.gfplayerdialog:CloseDialog()
        end
        self:RemoveListeners() 
    end

    self._interlocutor = nil

    inst:AddTag("hasdialog")
end)

--safe method
--args: conv [dialogue node]
--return: nothing
--add a dialogue node to the entity
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

--safe method
--args: conv [dialogue node]
--return: nothing
--remove a dialogue node from the entity
function GFInterlocutor:RemoveConversation(conv)
    for i = #(self.conversations), 1, -1 do
        if self.conversations[i].name == conv then table.remove(self.conversations, i) end
    end
end

--safe
--args: converstion initiator [entity with the gfplayerdialog component]
--return: bool
--can the entity talk to the converstion initiator or not
function GFInterlocutor:WantsToTalk(doer)
    local inst = self.inst
    return  not inst:HasTag("gfnonspeaking") --inst:HasTag("hasdialog") 
            and not self.isBusy
            and (self.wantsToTalkFn == nil         or self.wantsToTalkFn(doer, inst))
            and (inst.components.combat == nil     or inst.components.combat.target == nil) 
            and (inst.components.burnable == nil   or not inst.components.burnable:IsBurning()) 
            and (inst.components.freezable == nil  or not inst.components.freezable:IsFrozen()) 
            and (inst.components.sleeper == nil    or not inst.components.sleeper:IsAsleep()) 
            and (inst.components.health == nil     or not inst.components.health:IsDead())
end

--safe
--args: world state event [string], update fn [function]
--return: nothing
--used to define entity's behaviors update
function GFInterlocutor:SetMoodUpdateFn(event, fn)
    if event == nil or fn == nil then return end
    self.inst:WatchWorldState(event or "cycle", fn)
end

--safe
--args: mood [string], val [bool]
--return: nothing
--used to define entity's behavior at the current momemt
function GFInterlocutor:SetMood(mood, val)
    self.mood[mood] = val
end

--safe
--args: mood [string]
--return: [boolean]
function GFInterlocutor:GetMood(mood)
    return self.mood[mood] == true
end

--safe
--args: node [dialogue node]
--return: [boolean], true if node's checks are successed
function GFInterlocutor:CheckMood(node)
    if node.moodReqs ~= nil then 
        for _, mood in pairs(node.moodReqs) do
            if not self:GetMood(mood) then return false end
        end
    end

    return true
end

--safe
--args: converstion initiator [entity with the gfplayerdialog component]
--return: bool, true if conversation was started
--start conversation with the initiator entity
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

--safe
--args: react [function] 
--return: nothing
--use to define custom reaction on the conversation started event
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

--safe
--args: none
--return: line [string]
--get a default line for a dialogue node (if your node doesn't have a text, but has choises)
function GFInterlocutor:GetString()
    return self.phrase
end

--unsafe
function GFInterlocutor:RemoveListeners()
    self.inst:RemoveEventCallback("attacked",    self._interruptedFn)
    self.inst:RemoveEventCallback("death",       self._interruptedFn)
    self.inst:RemoveEventCallback("onremove",    self._interruptedFn)
    self.inst:RemoveEventCallback("newtarget",   self._interruptedFn)
    self.inst:RemoveEventCallback("stopconversation",   self._interruptedFn)

    self._interlocutor = nil
    self.isBusy = false
end

--unsafe
function GFInterlocutor:SetListeners(doer)
    self.isBusy = true
    self._interlocutor = doer

    self.inst:ListenForEvent("attacked",    self._interruptedFn)
    self.inst:ListenForEvent("death",       self._interruptedFn)
    self.inst:ListenForEvent("onremove",    self._interruptedFn)
    self.inst:ListenForEvent("newtarget",   self._interruptedFn)
    self.inst:ListenForEvent("stopconversation",   self._interruptedFn)
end

--ingame
function GFInterlocutor:GetDebugString()
    local moods = {}
    for mood, _ in pairs(self.mood) do
        table.insert(moods, mood)
    end

    local node = {}
    for _, cNode in pairs(self.conversations) do
        table.insert(node, cNode.name)
    end

    return string.format("busy %s talker: %s mood: %s nodes: %s", tostring(self.isBusy), tostring(self._interlocutor), table.concat(moods, ", "), table.concat(node, ", "))
end

return GFInterlocutor