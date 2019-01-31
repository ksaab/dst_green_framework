local function RunNode(doer, interlocutor)
    return {interlocutor.components.gfinterlocutor:GetString()}
end

local function fn()
    local node = GF.CreateDialogueNode()
    node.nodeFn = RunNode
    node.priority = 0
    node.hasQuests = true

    return node
end

return GF.DialogueNode("default_node", fn)