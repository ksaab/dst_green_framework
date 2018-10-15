local rawget = GLOBAL.rawget
local rawset = GLOBAL.rawset
local require = GLOBAL.require
local assert = GLOBAL.assert

if not rawget(GLOBAL, "GFQuestList") then
    rawset(GLOBAL, "GFQuestList", {})
end

if not rawget(GLOBAL, "GFQuestIDToName") then
    rawset(GLOBAL, "GFQuestIDToName", {})
end

local GFQuestList = GLOBAL.GFQuestList
local GFQuestIDToName = GLOBAL.GFQuestIDToName

local questArray = 
{
    {
        name = "_bring_items",
    },
    {
        name = "_bring_items2",
    },
    {
        name = "_kill_creatures2",
    },
    {
        name = "_kill_creatures",
    },
}

local questFolder = "quests/"
local commonFolder = "common/"

for k, v in pairs (questArray) do
    local route = 
    {
        questFolder,
        v.folder or commonFolder,
        v.name
    }

    local q = require(table.concat(route))
    assert(q.name ~= nil, "Quest name isn't setted in file " .. table.concat(route))
    
    GFQuestList[q.name] = q     --It's a "database" for quests
    GFQuestList[q.name].id = k  --unique ID for quest (works only in current session, may change in another)
                                --id are used only for network things, all server/client stuff works with names

    GFQuestIDToName[k] = q.name --cached quests IDs

    --GFQuestList[v.name].name = v.name
    --GFQuestList[v.name].id = k
    --GFQuestNameToID[v.name] = k
    --GFQuestIDToName[k] = v.name
end