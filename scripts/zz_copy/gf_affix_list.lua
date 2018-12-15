local rawget = GLOBAL.rawget
local rawset = GLOBAL.rawset
local require = GLOBAL.require

if not rawget(GLOBAL, "GFAffixList") then
    rawset(GLOBAL, "GFAffixList", {})
end
local GFAffixList = GLOBAL.GFAffixList

local affixArray = 
{

}

for prefab, affixes in pairs (affixArray) do
    GLOBAL.GFEntitiesBaseAffixes[prefab] = affixes
end