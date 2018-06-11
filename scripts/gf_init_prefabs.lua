--[[Init the world]]
local gfFunctions = GLOBAL.require "gf_global_functions"

AddPrefabPostInit("world", function(world)
    world:ListenForEvent("playerentered", function(world, player)
        gfFunctions.GFDebugPrint(string.format("Add Spell Pointer (%s) to %s", gfFunctions.GFGetIsMasterSim() and "server" or "client", tostring(player)))
        player:AddComponent("gfspellpointer")
        if not gfFunctions.GFGetDedicatedNet() then
            gfFunctions.GFDebugPrint(string.format("Add Recharge Watcher to %s", tostring(player)))
            player:AddComponent("gfrechargewatcher")
        end

        if gfFunctions.GFGetIsMasterSim() then
            if GLOBAL.GFDev then
                world:ListenForEvent("playeractivated", function(world, player)
                    local inv = player.components.inventory
        
                    if inv and not inv:Has("gf_magic_echo_amulet", 1) then
                        inv:GiveItem( GLOBAL.SpawnPrefab("gf_magic_echo_amulet") )
                        inv:GiveItem( GLOBAL.SpawnPrefab("gf_lightning_spear") )
                        inv:GiveItem( GLOBAL.SpawnPrefab("hammer") )
                        inv:GiveItem( GLOBAL.SpawnPrefab("gf_tentacle_staff") )
                    end
                end)
            end
        end

        --[[ if gfFunctions.GFGetIsMasterSim() then
            GFDebugPrint(string.format("Add Spell Pointer (server) to %s", tostring(player)))
            player:AddComponent("gfspellpointer")
            if not gfFunctions.GFGetDedicatedNet() then --dedicated server doesn't need the recharge watcher component
                GFDebugPrint(string.format("Add Recharge Watcher to %s", tostring(player)))
                player:AddComponent("gfrechargewatcher")
            end

            world:ListenForEvent("playeractivated", function(world, player)
                local inv = player.components.inventory
    
                if inv and not inv:Has("gf_magic_echo_amulet", 1) then
                    inv:GiveItem( GLOBAL.SpawnPrefab("gf_magic_echo_amulet") )
                    inv:GiveItem( GLOBAL.SpawnPrefab("gf_lightning_spear") )
                    inv:GiveItem( GLOBAL.SpawnPrefab("hammer") )
                    inv:GiveItem( GLOBAL.SpawnPrefab("gf_tentacle_staff") )
                end
            end)
        else
            GFDebugPrint(string.format("Add Spell Pointer (client) to %s", tostring(player)))
            player:AddComponent("gfspellpointer")
            GFDebugPrint(string.format("Add Recharge Watcher to %s", tostring(player)))
            player:AddComponent("gfrechargewatcher")
        end  ]]
    end)
end)

--[[Init players]]--
local allCharacters = 
{
    wilson = {"equip_chainlightning"},
    willow = {"equip_crushlightning"},
    --wendy = {},
    wes = {},
    wickerbottom = {"character_crushlightning"},
    wolfgang = {},
    winona = {"character_chainlightning"},
    woodie = {},
    waxwell = {},
    webber = {},
    wx78 = {},
    wathgrithr = {},
}

for prefab, spells in pairs(allCharacters) do
    gfFunctions.GFSetUpCharacterSpells(prefab, spells)
end

local function PlayerFFCheck(self, target)
    return (target:HasTag("player") and not isPVPEnabled)
        or (self.inst.components.leader and self.inst.components.leader:IsFollower(target))
end

AddPlayerPostInit(function(player)
    player:AddTag("gfcandrink")
    gfFunctions.GFMakePlayerCaster(player)
    if gfFunctions.GFGetIsMasterSim() then
        player.components.gfspellcaster:SetIsTargetFriendlyFn(PlayerFFCheck)
        --player:AddComponent("gfeffectable")
        --player:AddComponent("gfeventreactor")
    end 
end)

--[[Init other stuff]]
--equipment
AddPrefabPostInit("boomerang", function(inst)
    if GLOBAL.TheWorld.ismastersim then
        inst:ListenForEvent("gfonweaponhit", function(inst) print(inst, "did the hit!") end)
    end 
end)

AddPrefabPostInit("gf_lightning_spear", function(inst)
    gfFunctions.GFMakeInventoryCastingItem(inst, {"equip_chainlightning", "equip_crushlightning"})
end)

AddPrefabPostInit("gf_tentacle_staff", function(inst)
    gfFunctions.GFMakeInventoryCastingItem(inst, {"apply_lesser_rejuvenation", "apply_slow"})
end)

AddPrefabPostInit("hammer", function(inst)
    gfFunctions.GFMakeInventoryCastingItem(inst, {"equip_groundslam", "character_chainlightning"})
end)

--creatures
local function PigmanFFCheck(self, target)
    local isFriend = (target:HasTag("pig") and not target:HasTag("werepig"))
        or (target.components.leader and target.components.leader:IsFollower(self.inst))

    return isFriend or false
end

AddPrefabPostInit("pigman", function(inst)
    gfFunctions.GFMakeCaster(inst)
    if gfFunctions.GFGetIsMasterSim() then
        inst.components.gfspellcaster:SetIsTargetFriendlyFn(PigmanFFCheck)
    end
end)

--[[Init common]]
AddPrefabPostInitAny(function(inst) 
	if not (inst:HasTag("FX") or inst:HasTag("NOCLICK")) then
        if gfFunctions.GFGetIsMasterSim() then
            inst:AddComponent("gfeffectable")
            inst:AddComponent("gfeventreactor")
        end
    end
end)