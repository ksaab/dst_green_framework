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
AddStategraphState("merm", pigmanCastSpell)
AddStategraphActionHandler("merm", ActionHandler(ACTIONS.GFCASTSPELL, "castspell"))
AddStategraphState("bunnyman", pigmanCastSpell)
AddStategraphActionHandler("bunnyman", ActionHandler(ACTIONS.GFCASTSPELL, "castspell"))

local knightCastSpell = State{
    name = "castspell",
    tags = { "casting", "busy" },

	onenter = function(inst)
		inst.Physics:Stop()
        inst.AnimState:PlayAnimation("taunt")
        inst.SoundEmitter:PlaySound("dontstarve/creatures/knight" .. inst.kind .. "/voice")
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

local ghostCastSpell = State{
    name = "castspell",
    tags = { "casting", "busy" },

	onenter = function(inst)
		inst.Physics:Stop()
        inst.AnimState:PlayAnimation("dissipate")
        inst.AnimState:PushAnimation("appear")
        inst.SoundEmitter:PlaySound(inst:HasTag("girl") and "dontstarve/ghost/ghost_girl_howl" or "dontstarve/ghost/ghost_howl")
	end,
	
    events =
    {
        EventHandler("animover", function(inst)
			if not inst.AnimState:AnimDone() then
                if inst.AnimState:IsCurrentAnimation("appear") then
                    inst.SoundEmitter:PlaySound(inst:HasTag("girl") and "dontstarve/ghost/ghost_girl_howl" or "dontstarve/ghost/ghost_howl")
                    inst:PerformBufferedAction()
                end
            else
                inst.sg:GoToState("idle")
			end
		end),
	},
}

AddStategraphState("ghost", ghostCastSpell)
AddStategraphActionHandler("ghost", ActionHandler(ACTIONS.GFCASTSPELL, "castspell"))

local tallbirdCastSpell = State{
    name = "castspell",
    tags = { "casting", "busy" },

    onenter = function(inst)
        inst.Physics:Stop()            
        inst.AnimState:PlayAnimation("steal")
        inst.SoundEmitter:PlaySound("dontstarve/creatures/smallbird/scratch_ground")
    end,

	timeline =
    {
        TimeEvent(11 * FRAMES, function(inst) 
            inst:PerformBufferedAction() 
        end),
    },
	
    events =
    {
        EventHandler("animover", function(inst) 
            inst.sg:GoToState("idle") 
        end),
    },    
}

AddStategraphState("tallbird", tallbirdCastSpell)
AddStategraphActionHandler("tallbird", ActionHandler(ACTIONS.GFCASTSPELL, "castspell"))

local spiderCastSpell = State{
    name = "castspell",
    tags = { "casting", "busy" },

    onenter = function(inst)
        inst.Physics:Stop()
        inst.AnimState:PlayAnimation("taunt")
        inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/scream")
    end,

    timeline =
    {
        TimeEvent(14 * FRAMES, function(inst) inst:PerformBufferedAction() end),
    },

    events=
    {
        EventHandler("animover", function(inst)
            inst:PerformBufferedAction()
            inst.sg:GoToState("idle")
        end),
    },
}

AddStategraphState("spider", spiderCastSpell)
AddStategraphActionHandler("spider", ActionHandler(ACTIONS.GFCASTSPELL, "castspell"))

local batCastSpell = State{
    name = "castspell",
    tags = { "casting", "busy" },

    onenter = function(inst)
        inst.Physics:Stop()
        inst.AnimState:PlayAnimation("taunt")
    end,

    timeline =
    {
        TimeEvent(1*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/taunt") end ),
        TimeEvent(7*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end ),
        TimeEvent(18*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end ),
        TimeEvent(28*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end ),
        TimeEvent(32*FRAMES, function(inst) inst:PerformBufferedAction() end),
        TimeEvent(43*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end ),
    },

    events=
    {
        EventHandler("animover", function(inst)
            inst.sg:GoToState("idle")
        end),
    },
}

AddStategraphState("bat", batCastSpell)
AddStategraphActionHandler("bat", ActionHandler(ACTIONS.GFCASTSPELL, "castspell"))

local houndCastSpell = State{
    name = "castspell",
    tags = { "busy", "casting" },

    onenter = function(inst)
        inst.Physics:Stop()
        inst.AnimState:PlayAnimation("taunt")
    end,

    timeline =
    {
        TimeEvent(13 * FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.bark) end),
        TimeEvent(24 * FRAMES, function(inst)
            inst:PerformBufferedAction()
            inst.SoundEmitter:PlaySound(inst.sounds.bark) 
        end),
    },

    events =
    {
        EventHandler("animover", function(inst)
            inst.sg:GoToState("idle")
        end),
    },
}

AddStategraphState("hound", houndCastSpell)
AddStategraphActionHandler("hound", ActionHandler(ACTIONS.GFCASTSPELL, "castspell"))
AddStategraphState("icehound", houndCastSpell)
AddStategraphActionHandler("icehound", ActionHandler(ACTIONS.GFCASTSPELL, "castspell"))
AddStategraphState("firehound", houndCastSpell)
AddStategraphActionHandler("firehound", ActionHandler(ACTIONS.GFCASTSPELL, "castspell"))

local mosquitoCastSpell = State{
    name = "attack",
    tags = { "busy", "casting" },

    onenter = function(inst)
        inst.Physics:Stop()
        inst.AnimState:PlayAnimation("atk")
    end,

    timeline =
    {
        TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.attack) end),
        TimeEvent(15*FRAMES, function(inst) inst:PerformBufferedAction() end),
    },

    events =
    {
        EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
    },
}

AddStategraphState("mosquito", mosquitoCastSpell)
AddStategraphActionHandler("mosquito", ActionHandler(ACTIONS.GFCASTSPELL, "castspell"))