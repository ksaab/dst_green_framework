AddModRPCHandler("GreenFramework", "GFPLAYEISRREADY", function(inst)
    inst:PushEvent("gfplayerisready")
end)

AddModRPCHandler("GreenFramework", "GFDISABLEPOINTER", function(inst)
    if inst.components.gfspellpointer then
        inst.components.gfspellpointer:Disable()
    end
end)

AddModRPCHandler("GreenFramework", "GFCLICKSPELLBUTTON", function(inst, spellName)
    if inst.components.gfspellcaster and spellName and type(spellName) == "string"then
        inst.components.gfspellcaster:HandleIconClick(spellName)
    end
end)

AddModRPCHandler("GreenFramework", "GFDIALOGRPC", function(inst, event, name, hash)
    --type: 0 - close, 1 - dialogue node, 2 - accept a quest, 3 - complete a quest, 4 - abandon a quest
    if event ~= nil and type(event) == "number" and inst.components.gfplayerdialog ~= nil then
        if event == 0 then
            inst.components.gfplayerdialog:HandleButton(0)
        elseif event >= 1 and event <= 3 and type(name) == "string" then
            inst.components.gfplayerdialog:HandleButton(event, name)
        elseif event == 4 and type(name) == "string" and type(hash) == "string" then
            inst.components.gfplayerdialog:HandleButton(4, name, hash)
        else
            _G.GFDebugPrint(string.format("Green! Invalid RPC data for %s, event - %s, name - %s, hash - %s",
                tostring(inst), tostring(event), tostring(name), tostring(hash)))
        end
    end
end)

AddModRPCHandler("GreenFramework", "GFSHOPRPC", function(inst, event, itemID)
    --events: 0 - close, 1 - buy
    if event ~= nil and type(event) == "number" and inst.components.gfplayerdialog ~= nil then
        if event == 0 then
            inst.components.gfplayerdialog:HandleShopButton(0)
        elseif event == 1 and type(itemID) == "number" then
            inst.components.gfplayerdialog:HandleShopButton(1, itemID)
        else
            _G.GFDebugPrint(string.format("Green! Invalid RPC data for %s, event - %s, item - %s",
                tostring(inst), tostring(event), tostring(itemID)))
        end
    end
end)