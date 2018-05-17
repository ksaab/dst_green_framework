local rawget = GLOBAL.rawget
local rawset = GLOBAL.rawset
local require = GLOBAL.require

if not rawget(GLOBAL, "GFSpellList") then
    rawset(GLOBAL, "GFSpellList", {})
end

if not rawget(GLOBAL, "GFSpellNameToID") then
    rawset(GLOBAL, "GFSpellNameToID", {})
end

if not rawget(GLOBAL, "GFSpellIDToName") then
    rawset(GLOBAL, "GFSpellIDToName", {})
end

local GFSpellList = GLOBAL.GFSpellList
local GFSpellNameToID = GLOBAL.GFSpellNameToID
local GFSpellIDToName = GLOBAL.GFSpellIDToName

local spellArray = 
{
    [1] = { name = "create_flower" },
    [2] = { name = "create_goldnugget"},
    [3] = { name = "equip_chainlightning", folder = "item/"},
    [4] = { name = "equip_crushlightning", folder = "item/"},
    [5] = { name = "equip_groundslam", folder = "item/"},

    [100] = {name = "amulet_magic_echo"},
    [101] = {name = "apply_lesser_rejuvenation"},
    [102] = {name = "apply_slow"},
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