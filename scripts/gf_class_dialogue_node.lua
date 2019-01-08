--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

------------------------------------------------------------
--INFO------------------------------------------------------
------------------------------------------------------------
--All methods are unsafe, do not use them directly
--Valid ways to work with effects are implemented in
--gfinterlocutor component
------------------------------------------------------------

local DialogueNode = Class(function(self, name)
    --[[SERVER AND CLIENT]]
    self.name = name

    self.global = false
    self.priority = 0

    self.preCheckFn = nil
    self.checkFn = nil

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
        self.nodeFn(doer, interlocutor)
    else
        print("DialogueNode", self.name, "doesn't have an event function!")
    end
end

function DialogueNode:CollectQuests(doer, interlocutor)
    if interlocutor.components.gfquestgiver and doer.components.gfquestdoer then
        return interlocutor.components.gfquestgiver:PickQuests(doer)
    end

    return nil
end

return DialogueNode