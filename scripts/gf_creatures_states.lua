local ActionHandler = GLOBAL.ActionHandler
local ACTIONS = GLOBAL.ACTIONS
local FRAMES = GLOBAL.FRAMES
local EventHandler = GLOBAL.EventHandler
local TimeEvent = GLOBAL.TimeEvent
local State = GLOBAL.State

local pigmanCastSpell = State{
    name = "castspell",
    tags = { "casting", "busy" },

	onenter = function(inst)
		inst.Physics:Stop()
        inst.AnimState:PlayAnimation("atk")
	end,

	timeline =
	{
		TimeEvent(13 * FRAMES, function(inst) inst:PerformBufferedAction() end),
	},
	
    events =
    {
        EventHandler("animover", function(inst)
			inst.sg:GoToState("idle")
		end),
	},
}

--[[ local pigmanQuestReact = State{
    name = "gfquestreaction",
    tags = { "busy" },

	onenter = function(inst)
		inst.Physics:Stop()
        inst.AnimState:PlayAnimation("idle_happy")
        inst.SoundEmitter:PlaySound("dontstarve/pig/oink")
	end,

    events =
    {
        EventHandler("animover", function(inst)
			inst.sg:GoToState("idle")
		end),
	},
} ]]

AddStategraphState("pig", pigmanCastSpell)
--AddStategraphState("pig", pigmanQuestReact)

AddStategraphActionHandler("pig", ActionHandler(ACTIONS.GFCASTSPELL, "castspell"))
--[[ AddStategraphEvent("pig", EventHandler("gfQGGetAttention", function(inst)
		print("event listened")
        if (inst.components.health ~= nil and not inst.components.health:IsDead())
            or (giver.components.combat ~= nil and giver.components.combat.target ~= nil) 
            or (giver.components.burnable ~= nil and giver.components.burnable:IsBurning()) 
            or (giver.components.freezable ~= nil and giver.components.freezable:IsFrozen()) 
            or (giver.components.sleeper ~= nil and giver.components.sleeper:IsAsleep()) 
        then
            return
        end

        inst.sg:GoToState("gfquestreaction")
    end)
) ]]

local knightCastSpell = State{
    name = "castspell",
    tags = { "casting", "busy" },

	onenter = function(inst)
		inst.Physics:Stop()
        inst.AnimState:PlayAnimation("taunt")
        inst.SoundEmitter:PlaySound("dontstarve/creatures/knight"..inst.kind.."/voice")
	end,

	timeline =
	{
		TimeEvent(18 * FRAMES, function(inst) inst:PerformBufferedAction() end ),
	},
	
    events =
    {
        EventHandler("animover", function(inst)
			inst.sg:GoToState("idle")
		end),
	},
}

AddStategraphState("knight", knightCastSpell)
AddStategraphActionHandler("knight", ActionHandler(ACTIONS.GFCASTSPELL, "castspell"))
