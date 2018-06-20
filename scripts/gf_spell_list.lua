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
    [3] = { name = "equip_chainlightning", folder = "item/"},
    [4] = { name = "equip_crushlightning", folder = "item/"},
    [5] = { name = "equip_groundslam", folder = "item/"},

    [10] = { name = "character_chainlightning", folder = "character/"},
    [11] = { name = "character_crushlightning", folder = "character/"},

    [100] = {name = "amulet_magic_echo"},
    [101] = {name = "apply_lesser_rejuvenation"},
    [102] = {name = "apply_slow"},

    [105] = {name = "equip_shootsting", folder = "item/"}
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