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

AddModRPCHandler("GreenFramework", "GFEVENTRPC", function(inst, event)
    if type(event) == "string" and inst.components.gfplayerdialog ~= nil then
        inst.components.gfplayerdialog:HandleEventButton(event)
    end
end)

AddModRPCHandler("GreenFramework", "GFQUESTRPC", function(inst, event, qName, hash)

    ------------------------
    --events:
    --0 - accept a quest
    --1 - decline a quest
    --2 - abandon a quest
    --3 - complete 
    ------------------------

    if type(event) == "number"
        and (qName == nil or type(qName) == "string")
        and (hash == nil or type(hash) == "string")
        and inst.components.gfplayerdialog ~= nil
    then
        inst.components.gfplayerdialog:HandleQuestRPC(event, qName, hash)
    else
        print("wrong data for GFQUESTRPC ", inst, qName, type(qName), event, type(event))
    end
end)