local _G = GLOBAL
local rawget = _G.rawget
local rawset = _G.rawset
local require = _G.require

if not rawget(_G, "GFSpellList") then
    rawset(_G, "GFSpellList", {})
end

if not rawget(_G, "GFSpellNameToID") then
    rawset(_G, "GFSpellNameToID", {})
end

if not rawget(_G, "GFSpellIDToName") then
    rawset(_G, "GFSpellIDToName", {})
end

if not GfCharacterSpells then
    rawset(_G, "GfCharacterSpells", {})
end

local GFSpellList = _G.GFSpellList
local GFSpellNameToID = _G.GFSpellNameToID
local GFSpellIDToName = _G.GFSpellIDToName

local spellArray = 
{

}

local spellsFolder = "spells/"
local commonFolder = "common/"

for k, v in pairs (spellArray) do
    local route = 
    {
        spellsFolder,
        v.folder or commonFolder,
        v.name
    }
    GFSpellList[v.name] = require(table.concat(route))
    GFSpellList[v.name].name = v.name
    GFSpellList[v.name].id = k
    GFSpellNameToID[v.name] = k
    GFSpellIDToName[k] = v.name
end