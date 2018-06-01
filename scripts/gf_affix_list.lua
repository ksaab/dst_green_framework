local rawget = GLOBAL.rawget
local rawset = GLOBAL.rawset
local require = GLOBAL.require

if not rawget(GLOBAL, "GFAffixList") then
    rawset(GLOBAL, "GFAffixList", {})
end
local GFAffixList = GLOBAL.GFAffixList

local affixArray = 
{
    pigman = 
    {
        chance = 1,
        list = 
        {
            "affix_shaman",
        },
    },
    spider = 
    {
        chance = 1,
        list = 
        {
            "affix_test",
        },
    },
}

for prefab, affixes in pairs (affixArray) do
    GFAffixList[prefab] = affixes
end