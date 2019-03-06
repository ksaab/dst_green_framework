local function RunNode(doer, interlocutor)
    local nodes
    if interlocutor.components.gfshop ~= nil then
        nodes = {"trade_default"}
    end
    return {interlocutor.components.gfinterlocutor:GetString(), nodes}
end

local function fn()
    local node = GF.CreateDialogueNode()
    node.nodeFn = RunNode
    node.priority = 0
    node.hasQuests = true

    return node
end

return GF.DialogueNode("default_node", fn)