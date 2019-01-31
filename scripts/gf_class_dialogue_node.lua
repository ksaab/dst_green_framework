--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

------------------------------------------------------------
--INFO------------------------------------------------------
------------------------------------------------------------
--All methods are unsafe, do not use them directly
--Valid ways to work with nodes are implemented in
--the gfinterlocutor component
------------------------------------------------------------

local DialogueNode = Class(function(self, name)
    --[[SERVER AND CLIENT]]
    self.name = name

    self.isLast = false     --if true - dialog window will be closed, when player run the node
    self.hasQuests = false  --collect quests for this node or not
    self.priority = 0       --interlocutor component picks node with the highest priority (if checkFn for it return true)

    self.preCheckFn = nil   --this function runs when the interlocutor picks a node to run
    self.checkFn = nil      --this when server runs the event

    self.nodeFn = nil
end)

------------------------------------------------------------
--server only metods ---------------------------------------
------------------------------------------------------------

function DialogueNode:PreCheck(doer, interlocutor)
    --print(self.name, self.preCheckFn == nil or self.preCheckFn(doer, interlocutor))
    return (self.preCheckFn == nil or self.preCheckFn(doer, interlocutor))
end

function DialogueNode:Check(doer, interlocutor)
    return (self.checkFn == nil or self.checkFn(doer, interlocutor))
end

function DialogueNode:RunNode(doer, interlocutor)
    if self.nodeFn ~= nil then
        local res = self.nodeFn(doer, interlocutor)
        if res ~= nil then
            if type(res) == "table" then
                doer.components.gfplayerdialog:StartConversationWith(interlocutor, res, self.hasQuests)
            elseif type(res) == "string" then
                doer.components.gfplayerdialog:StartConversationWith(interlocutor, {res}, self.hasQuests)
            end
        end
    else
        print("DialogueNode", self.name, "doesn't have an event function!")
    end

    --closing a dialog if node marked as last
    if self.isLast then doer.components.gfplayerdialog:CloseDialog() end
end

function DialogueNode:CollectQuests(doer, interlocutor)
    if interlocutor.components.gfquestgiver and doer.components.gfquestdoer then
        return interlocutor.components.gfquestgiver:PickQuests(doer)
    end

    return nil
end

return DialogueNode