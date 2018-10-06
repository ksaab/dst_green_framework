local rawget = GLOBAL.rawget
local rawset = GLOBAL.rawset
local require = GLOBAL.require

if not rawget(GLOBAL, "GFQuestList") then
    rawset(GLOBAL, "GFQuestList", {})
end

--[[-------------------------------------------
if not rawget(GLOBAL, "GFQuestNameToID") then
    rawset(GLOBAL, "GFQuestNameToID", {})
end

if not rawget(GLOBAL, "GFQuestIDToName") then
    rawset(GLOBAL, "GFQuestIDToName", {})
end
]]---------------------------------------------

local GFQuestList = GLOBAL.GFQuestList
--local GFQuestNameToID  = GLOBAL.GFQuestNameToID
--local GFQuestIDToName = GLOBAL.GFQuestIDToName

local questArray = 
{

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
    GFQuestList[v.name] = require(table.concat(route))
    --GFQuestList[v.name].name = v.name
    --GFQuestList[v.name].id = k
    --GFQuestNameToID[v.name] = k
    --GFQuestIDToName[k] = v.name
end