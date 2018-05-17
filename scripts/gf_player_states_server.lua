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

local function ToggleOffPhysics(inst)
    inst.sg.statemem.isphysicstoggle = true
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND)
end

local function ToggleOnPhysics(inst)
    inst.sg.statemem.isphysicstoggle = nil
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:CollidesWith(COLLISION.GIANTS)
end

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
--cast with staff
local gfcastwithstaff = State{
	name = "gfcastwithstaff",
	tags = { "casting", "doing", "busy", "nomorph" },

	onenter = function(inst)
		inst.components.locomotor:Stop()
		local item = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

        inst.AnimState:PlayAnimation("staff_pre")
        inst.AnimState:PushAnimation("staff", false)

        inst.SoundEmitter:PlaySound("dontstarve/common/rebirth_amulet_raise")
        inst.sg.statemem.stafflight = SpawnPrefab("staff_castinglight")
        inst.sg.statemem.stafflight.Transform:SetPosition(inst.Transform:GetWorldPosition())
        inst.sg.statemem.stafflight:SetUp({ 1, 1, 1 }, 1.9, .33)

        inst.sg.statemem.stafffx = SpawnPrefab(inst.components.rider:IsRiding() and "staffcastfx_mount" or "staffcastfx")
        inst.sg.statemem.stafffx.entity:SetParent(inst.entity)
        inst.sg.statemem.stafffx.Transform:SetRotation(inst.Transform:GetRotation())
        inst.sg.statemem.stafffx:SetUp({ 1, 1, 1 })
	end,

	onexit = function(inst) 
		if inst.sg.statemem.stafflight ~= nil and inst.sg.statemem.stafflight:IsValid() then
			inst.sg.statemem.stafflight:Remove()
		end
		if inst.sg.statemem.stafffx ~= nil and inst.sg.statemem.stafffx:IsValid() then
			inst.sg.statemem.stafffx:Remove()
		end
	end,

	events =
	{
		EventHandler("animqueueover", function(inst)
			if inst.AnimState:AnimDone() then
				inst.sg:GoToState("idle")
			end
		end),
		EventHandler("unequip", function(inst) 
			inst.sg:GoToState("idle") 
		end),
	},

	timeline =
	{
		TimeEvent(58 * FRAMES, function(inst)
			local sm = inst.sg.statemem
			inst:PerformBufferedAction()
		end),
	}
}

--groundslam
local gfgroundslam = State{
	name = "gfgroundslam",
	tags = { "casting", "doing", "busy", "nomorph" },

	onenter = function(inst)
		inst.components.locomotor:Stop()

        inst.AnimState:PlayAnimation("atk_leap_pre")
        inst.AnimState:PushAnimation("atk_leap", false)
	end,

	onexit = function(inst) 

	end,

	events =
	{
		EventHandler("animqueueover", function(inst)
			if inst.AnimState:AnimDone() then
				inst.sg:GoToState("idle")
			end
		end),
		EventHandler("unequip", function(inst) 
			inst.sg:GoToState("idle") 
		end),
	},

	timeline =
	{
		TimeEvent(26 * FRAMES, function(inst)
			if inst.AnimState:IsCurrentAnimation("atk_leap") then
                inst:PerformBufferedAction()
            end
		end),
	}
}

--Add states block--------------
AddStategraphState("wilson", gfcastwithstaff)
AddStategraphState("wilson", gfgroundslam)

--Add events block--------------
AddStategraphEvent("wilson", EventHandler("gfforcemove", function(inst, data)
	--hack for non-static spell range
	inst.components.locomotor:PushAction(data.act, true, true)
end))

--Add actions handlers block----
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.GFCASTPELL, function(inst)
    local act = inst:GetBufferedAction()
    local item = act.invobject
    
    if item.components.gfspellpointer then
        item.components.gfspellpointer:SetEnabled(false)
    end

    --need to check is act data valid for spell casting or not
    if act.pos == nil and act.target == nil then return "idle" end

    if item then
        --print("with item")
        --cast with spell item
        local splcstr = item.replica.gfspellitem
        if splcstr then
            --print("has component")
            local itemSpell = splcstr:GetItemSpellName()
            if itemSpell then
                --print("has spell")
                spell = spellList[itemSpell]
                if act.pos == nil then act.pos = Vector3(act.target.Transform:GetWorldPosition()) end

                local spellRange = spell:GetRange()
                if inst:GetDistanceSqToPoint(act.pos) > spellRange * spellRange then
                    --print("to far")
                    --if distace is greater then spell range, need to rebuffer the action 
                    --and push a destination point to the locomotor
                    inst:ClearBufferedAction()
                    act.distance = spellRange
                    inst:PushEvent("gfforcemove", {act = act})

                    return "idle"
                else
                    --print("close enough")
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
    --print("failed 2")
	return "idle"
end))
