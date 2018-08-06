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

AddStategraphState("pig", pigmanCastSpell)
AddStategraphActionHandler("pig", ActionHandler(ACTIONS.GFCASTSPELL, "castspell"))

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
