local function RunNode(doer, interlocutor)
    doer.components.gfplayerdialog:StartTradingWith(interlocutor)
end

local function fn()
    local node = GF.CreateDialogueNode()
    node.nodeFn = RunNode
    node.priority = 0

    return node
end

return GF.DialogueNode("trade_default", fn)