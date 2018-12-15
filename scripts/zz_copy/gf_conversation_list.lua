local rawget = GLOBAL.rawget
local rawset = GLOBAL.rawset
local require = GLOBAL.require

if not rawget(GLOBAL, "DialogueNodes") then
    rawset(GLOBAL, "DialogueNodes", {})
end

if not rawget(GLOBAL, "DialogueNodesNameToID") then
    rawset(GLOBAL, "DialogueNodesNameToID", {})
end

if not rawget(GLOBAL, "DialogueNodesIDs") then
    rawset(GLOBAL, "DialogueNodesIDs", {})
end

local DialogueNodes = GLOBAL.DialogueNodes
local DialogueNodesNameToID  = GLOBAL.DialogueNodesNameToID
local DialogueNodesIDs = GLOBAL.DialogueNodesIDs

local eventsArray = 
{
    {name = "default_node",}
}

local eventsFolder = "ALL_DIALOGUE_NODES/"
local commonFolder = "common/"

local CID = 1

for k, v in pairs (eventsArray) do
    local function AddNode(node, i)
        local name = node.name or (v.name .. '_' .. i)
        DialogueNodes[name] = node 
        DialogueNodes[name].id = CID
        DialogueNodesNameToID[name] = CID
        DialogueNodesIDs[CID] = name

        print(("Dialogue node %s was created with ID %i"):format(name, CID))
        CID = CID + 1
    end

    local route = 
    {
        eventsFolder,
        v.folder or commonFolder,
        v.name
    }
    
    local r = require(table.concat(route))
    if r.nodes == nil then
        AddNode(r)
    else
        for i = 1, #(r.nodes) do
            AddNode(r.nodes[i], i)
        end
    end
end