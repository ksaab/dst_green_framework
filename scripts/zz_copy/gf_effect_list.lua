local rawget = GLOBAL.rawget
local rawset = GLOBAL.rawset
local require = GLOBAL.require

if not rawget(GLOBAL, "GF.GetStatusEffects()") then
    rawset(GLOBAL, "GF.GetStatusEffects()", {})
end

if not rawget(GLOBAL, "GF.GetStatusEffectsIDs()") then
    rawset(GLOBAL, "GF.GetStatusEffectsIDs()", {})
end

if not rawget(GLOBAL, "GFEffectIDToName") then
    rawset(GLOBAL, "GFEffectIDToName", {})
end

local GF.GetStatusEffects() = GLOBAL.GF.GetStatusEffects()
local GF.GetStatusEffectsIDs()  = GLOBAL.GF.GetStatusEffectsIDs()
local GFEffectIDToName = GLOBAL.GFEffectIDToName

local effectArray = 
{

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
    GF.GetStatusEffects()[v.name] = require(table.concat(route))
    GF.GetStatusEffects()[v.name].name = v.name
    GF.GetStatusEffects()[v.name].id = k
    GF.GetStatusEffectsIDs()[v.name] = k
    GFEffectIDToName[k] = v.name
end