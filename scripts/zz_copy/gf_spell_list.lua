local _G = GLOBAL
local rawget = _G.rawget
local rawset = _G.rawset
local require = _G.require

if not rawget(_G, "GF.GetSpells()") then
    rawset(_G, "GF.GetSpells()", {})
end

if not rawget(_G, "GFSpellNameToID") then
    rawset(_G, "GFSpellNameToID", {})
end

if not rawget(_G, "GF.GetSpellsIDs()") then
    rawset(_G, "GF.GetSpellsIDs()", {})
end

if not GfCharacterSpells then
    rawset(_G, "GfCharacterSpells", {})
end

local GF.GetSpells() = _G.GF.GetSpells()
local GFSpellNameToID = _G.GFSpellNameToID
local GF.GetSpellsIDs() = _G.GF.GetSpellsIDs()

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
    GF.GetSpells()[v.name] = require(table.concat(route))
    GF.GetSpells()[v.name].name = v.name
    GF.GetSpells()[v.name].id = k
    GFSpellNameToID[v.name] = k
    GF.GetSpellsIDs()[k] = v.name
end