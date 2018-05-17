local State = GLOBAL.State
local EventHandler = GLOBAL.EventHandler
local FRAMES = GLOBAL.FRAMES
local TimeEvent = GLOBAL.TimeEvent
local ActionHandler = GLOBAL.ActionHandler
local EventHandler = GLOBAL.EventHandler
local EQUIPSLOTS = GLOBAL.EQUIPSLOTS
local COLLISION = GLOBAL.COLLISION
local SpawnPrefab = GLOBAL.SpawnPrefab
local ACTIONS = GLOBAL.ACTIONS
local ShakeAllCameras = GLOBAL.ShakeAllCameras
local CAMERASHAKE = GLOBAL.CAMERASHAKE
local Vector3 = GLOBAL.Vector3
local BufferedAction = GLOBAL.BufferedAction

local spellList = GLOBAL.GFSpellList

local function CanCastSpell(spell, inst, item)
    local itemValid = true
    --check item if exists
    if item and item.replica.gfspellitem then 
        itemValid = item.replica.gfspellitem:CanCastSpell(spell)
    end

    --check doer
    local instValid = inst.replica.gfspellcaster and inst.replica.gfspellcaster:CanCastSpell(spell)

	return instValid and itemValid
end

--STATES--
local gfcastwithstaff = State{
	name = "gfcastwithstaff",
	tags = { "casting", "doing", "busy", "nomorph" },

	onenter = function(inst)
		inst.components.locomotor:Stop()

        inst.AnimState:PlayAnimation("staff_pre")
        inst.AnimState:PushAnimation("staff", false)

        inst:PerformPreviewBufferedAction()
		inst.sg:SetTimeout(2)
	end,
    
    ontimeout = function(inst)
		inst:ClearBufferedAction()
		inst.sg:GoToState("idle")
    end,
    
    onupdate = function(inst)
		if inst:HasTag("doing") then
			if inst.entity:FlattenMovementPrediction() then
				inst.sg:GoToState("idle", "noanim")
			end
		elseif inst.bufferedaction == nil then
			inst.sg:GoToState("idle")
		end
	end,

	events =
	{
		EventHandler("unequip", function(inst) 
			inst.sg:GoToState("idle") 
		end),
	},
}

--groundslam
local gfgroundslam = State{
	name = "gfgroundslam",
	tags = { "casting", "doing", "busy", "nomorph" },

	onenter = function(inst)
		inst.components.locomotor:Stop()

        inst.AnimState:PlayAnimation("atk_leap_pre")
        inst.AnimState:PushAnimation("atk_leap_lag", false)

        inst:PerformPreviewBufferedAction()
		inst.sg:SetTimeout(2)
	end,

	ontimeout = function(inst)
		inst:ClearBufferedAction()
		inst.sg:GoToState("idle")
    end,
    
    onupdate = function(inst)
		if inst:HasTag("doing") then
			if inst.entity:FlattenMovementPrediction() then
				inst.sg:GoToState("idle", "noanim")
			end
		elseif inst.bufferedaction == nil then
			inst.sg:GoToState("idle")
		end
	end,

	events =
	{
		EventHandler("unequip", function(inst) 
			inst.sg:GoToState("idle") 
		end),
	},
}

--Add states block--------------
AddStategraphState("wilson_client", gfcastwithstaff)
AddStategraphState("wilson_client", gfgroundslam)

--Add events block--------------
AddStategraphEvent("wilson_client", EventHandler("gfforcemove", function(inst, data)
	--hack for non-static spell range
	inst.components.locomotor:PushAction(data.act, true, true)
end))

--Add actions handlers block----
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.GFCASTPELL, function(inst)
    local act = inst:GetBufferedAction()
    local item = act.invobject
    
    if item.components.gfspellpointer then
        item.components.gfspellpointer:SetEnabled(false)
    end

    --need to check is act data valid for spell casting or not
    if act.pos == nil and act.target == nil then return "idle" end

    if item then
        --cast with spell item
        local splcstr = item.replica.gfspellitem
        if splcstr then
            local itemSpell = splcstr:GetItemSpellName()
            if itemSpell then
                spell = spellList[itemSpell]
                if act.pos == nil then act.pos = Vector3(act.target.Transform:GetWorldPosition()) end

                local spellRange = spell:GetRange()
                if inst:GetDistanceSqToPoint(act.pos) > spellRange * spellRange then
                    --if distace is greater then spell range, need to rebuffer the action 
                    --and push a destination point to the locomotor
                    inst:ClearBufferedAction()
                    act.distance = spellRange
                    inst:PushEvent("gfforcemove", {act = act})

                    return "idle"
                else
                    --if distance is valid and item is not recharging
                    --then go to item spell state
                    if CanCastSpell(itemSpell, inst, item) then
                        return spell:GetPlayerState()
                    end
                end
            end
        end
    else
        --cast without spell item
    end

    --action data is not valid for spell cast
	return "idle"
end))
