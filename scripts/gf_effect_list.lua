local rawget = GLOBAL.rawget
local rawset = GLOBAL.rawset
local require = GLOBAL.require

if not rawget(GLOBAL, "GFEffectList") then
    rawset(GLOBAL, "GFEffectList", {})
end

if not rawget(GLOBAL, "GFEffectNameToID") then
    rawset(GLOBAL, "GFEffectNameToID", {})
end

if not rawget(GLOBAL, "GFEffectIDToName") then
    rawset(GLOBAL, "GFEffectIDToName", {})
end

local GFEffectList = GLOBAL.GFEffectList
local GFEffectNameToID  = GLOBAL.GFEffectNameToID
local GFEffectIDToName = GLOBAL.GFEffectIDToName

local effectArray = 
{
    [1] = {name = "testeffect"},
    [2] = {name = "testpositive"},
    [3] = {name = "testnegative"},
    [4] = {name = "affix_test", folder = "affix/"}
}

local effectsFolder = "effects/"
local commonFolder = "common/"

for k, v in pairs (effectArray) do
    local route = 
    {
        effectsFolder,
        v.folder or commonFolder,
        v.name
    }
    GFEffectList[v.name] = require(table.concat(route))
    GFEffectList[v.name].name = v.name
    GFEffectList[v.name].id = k
    GFEffectNameToID[v.name] = k
    GFEffectIDToName[k] = v.name
end