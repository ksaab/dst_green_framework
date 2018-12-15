local function RunNode(doer, interlocutor)
    local quests = (interlocutor.components.gfquestgiver ~= nil)
        and interlocutor.components.gfquestgiver:PickQuests(doer)
        or nil

    local dialogData = 
    {
        [1] = interlocutor.components.gfinterlocutor:GetString(),
        [2] = nil,
        [3] = quests ~= nil and quests.offer or nil,
        [4] = quests ~= nil and quests.complete or nil,
    }

    doer.components.gfplayerdialog:StartConversationWith(interlocutor, dialogData)
end

local function fn()
    local node = GF.CreateDialogueNode()
    node.nodeFn = RunNode
    node.priority = 0
    return node
end

return GF.DialogueNode("default_node", fn)