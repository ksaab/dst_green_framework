local rawget = GLOBAL.rawget
local rawset = GLOBAL.rawset
local require = GLOBAL.require
local assert = GLOBAL.assert

if not rawget(GLOBAL, "GF.GetQuests") then
    rawset(GLOBAL, "GF.GetQuests", {})
end

if not rawget(GLOBAL, "GF.GetQuestsIDs()") then
    rawset(GLOBAL, "GF.GetQuestsIDs()", {})
end

local GF.GetQuests = GLOBAL.GF.GetQuests
local GF.GetQuestsIDs() = GLOBAL.GF.GetQuestsIDs()

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
    
    GF.GetQuests[q.name] = q     --It's a "database" for quests
    GF.GetQuests[q.name].id = k  --unique ID for quest (works only in current session, may change in another)
                                --id are used only for network things, all server/client stuff works with names

    GF.GetQuestsIDs()[k] = q.name --cached quests IDs

    --GF.GetQuests[v.name].name = v.name
    --GF.GetQuests[v.name].id = k
    --GFQuestNameToID[v.name] = k
    --GF.GetQuestsIDs()[k] = v.name
end