--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

local _G = GLOBAL
local State = _G.State
local EventHandler = _G.EventHandler
local FRAMES = _G.FRAMES
local TimeEvent = _G.TimeEvent
local ActionHandler = _G.ActionHandler
local EventHandler = _G.EventHandler
local EQUIPSLOTS = _G.EQUIPSLOTS
local COLLISION = _G.COLLISION
local SpawnPrefab = _G.SpawnPrefab
local ACTIONS = _G.ACTIONS
local ShakeAllCameras = _G.ShakeAllCameras
local CAMERASHAKE = _G.CAMERASHAKE
local Vector3 = _G.Vector3
local BufferedAction = _G.BufferedAction
local distsq = _G.distsq
local TUNING = _G.TUNING

_G.require "stategraphs/commonstates"

local ALL_SPELLS = _G.GF.GetSpells()

local function GetSpellCastTime(spellName)
	if spellName and ALL_SPELLS[spellName] then 
		return ALL_SPELLS[spellName].castTime or 0
	end

	return 0
end

local function FindValidGround(inst, range)
	range = (range ~= nil and range ~= math.huge) and range or 20
	local pos = Vector3()
	for i = range, 0, -1 do
		pos.x, pos.y, pos.z = inst.entity:LocalToWorldSpace(i, 0, 0)
		if _G.TheWorld.Map:IsPassableAtPoint(pos:Get()) and not _G.TheWorld.Map:IsGroundTargetBlocked(pos) then
			return pos
		end
	end

	return false
end

local function IsValidGround(pos)
	return _G.TheWorld.Map:IsPassableAtPoint(pos:Get()) and not _G.TheWorld.Map:IsGroundTargetBlocked(pos)
end

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

local function CanCastSpell(sName, inst, item, target, pos)
	if not inst.components.gfspellcaster:IsSpellReady(sName) then
		return false, "NOTREADY"
	end
	if item and item.components.gfspellitem and not item.components.gfspellitem:IsSpellReady(sName) then --check item if exists
		return false, "ITEMNOTREADY"
	end

	return inst.components.gfspellcaster:PreCastCheck(sName, target, pos)
end

--STATES--
--drink
local gfdodrink = State{
	name = "gfdodrink",
	tags = { "doing", "busy" },

	onenter = function(inst)
		inst.components.locomotor:Stop()
		local act = inst:GetBufferedAction()
		if act then
			local item = act.invobject
			local swapBuild, swapSymbol
			swapBuild = (item and item.swapBuild) and item.swapBuild or "swap_gf_bottle"
			swapSymbol = (item and item.swapSymbol) and item.swapSymbol or "swap_gf_bottle"
			--[[ local swap
			--print(act.invobject, act.target)
			if act.invobject and act.invobject.swapSymbol then
				swap = act.invobject.swapSymbol
			else
				swap = "swap_gf_cute_bottle"
			end ]]
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("action_uniqueitem_pre")
            inst.AnimState:PushAnimation("horn", false)
			inst.AnimState:OverrideSymbol("horn01", swapBuild, swapSymbol)
			--inst.AnimState:OverrideSymbol("horn01", "swap_potion_gw", "swap_twirl_orange")
			inst.AnimState:Show("ARM_normal")

			return
		end

		inst.sg:GoToState("idle")
	end,

	onexit = function(inst)
		if inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
			inst.AnimState:Show("ARM_carry") 
			inst.AnimState:Hide("ARM_normal")
		end
	end,

	timeline =
	{
		TimeEvent(48 * FRAMES, function(inst)
			inst:PerformBufferedAction()
		end),
	},

	events =
	{
		EventHandler("animqueueover", function(inst)
			inst.sg:GoToState("idle")
		end),
	},
}

--custom anim cast
local gfcustomcast = State
{
	name = "gfcustomcast",
	tags = { "doing", "casting", "busy", "nodangle" },

	onenter = function(inst)
		inst.components.locomotor:Stop()

		local act = inst:GetBufferedAction()
		if act and act.spell then
			local castTime = math.max(0.75, GetSpellCastTime(act.spell))
			if act.pos then
				inst:ForceFacePoint(act.pos.x, 0, act.pos.z)
			end
			
			inst.AnimState:PlayAnimation("gf_fast_cast_pre")
			inst.AnimState:PushAnimation("gf_fast_cast_loop", true)

			inst.sg:SetTimeout(castTime)
			return
		end

		inst.sg:GoToState("idle")
	end,

	ontimeout = function(inst)
		inst.sg:RemoveStateTag("casting")
		inst.sg:RemoveStateTag("busy")
		inst:PerformBufferedAction()
		inst.AnimState:PlayAnimation("gf_fast_cast_pst")
	end,

	events =
	{
		EventHandler("animqueueover", function(inst)
			if inst.AnimState:AnimDone() then
				inst.sg:GoToState("idle")
			end
		end),

		EventHandler("unequip", function(inst) 
			if inst.sg:HasStateTag("casting")  then
				inst.sg:GoToState("idle") 
			end
		end), 
	},
}

--cast with hand
local gfchannelcast = State
{
	name = "gfchannelcast",
	tags = { "doing", "casting", "busy", "nodangle" },

	onenter = function(inst)
		inst.components.locomotor:Stop()

		local act = inst:GetBufferedAction()
		if act and act.spell then
			local castTime = math.max(1, GetSpellCastTime(act.spell))
			if act.pos then
				inst:ForceFacePoint(act.pos.x, 0, act.pos.z)
			end
			
			inst.AnimState:PlayAnimation("channel_pre")
			inst.AnimState:PushAnimation("channel_loop", true)

			inst.sg:SetTimeout(castTime)
			return
		end

		inst.sg:GoToState("idle")
	end,

	ontimeout = function(inst)
		inst.sg:RemoveStateTag("casting")
		inst.sg:RemoveStateTag("busy")
		inst:PerformBufferedAction()
		inst.AnimState:PlayAnimation("channel_pst")
	end,

	events =
	{
		EventHandler("animqueueover", function(inst)
			if inst.AnimState:AnimDone() then
				inst.sg:GoToState("idle")
			end
		end),

		EventHandler("unequip", function(inst) 
			if inst.sg:HasStateTag("casting")  then
				inst.sg:GoToState("idle") 
			end
		end), 
	},
}

--cast with staff
local gfcastwithstaff = State{
	name = "gfcastwithstaff",
	tags = { "casting", "doing", "busy", "nomorph" },

	onenter = function(inst)
		inst.components.locomotor:Stop()

		local act = inst:GetBufferedAction()
		if act and act.spell then
			if act.pos then
				inst:ForceFacePoint(act.pos.x, 0, act.pos.z)
			end
			
			inst.AnimState:PlayAnimation("staff_pre")
			inst.AnimState:PushAnimation("staff", false)
			
			local visuals = ALL_SPELLS[act.spell].stateVisuals
			if visuals ~= nil then
				if visuals.sound ~= nil then
					inst.SoundEmitter:PlaySound(visuals.sound)
				end
				if visuals.lightColour ~= nil then
					inst.sg.statemem.stafflight = SpawnPrefab("staff_castinglight")
        			inst.sg.statemem.stafflight.Transform:SetPosition(inst.Transform:GetWorldPosition())
        			inst.sg.statemem.stafflight:SetUp(visuals.lightColour or {1, 1, 1, 1}, 1.9, .33)
				end
				if visuals.fxColour ~= nil then
					inst.sg.statemem.stafffx = SpawnPrefab(inst.components.rider:IsRiding() and "staffcastfx_mount" or "staffcastfx")
					inst.sg.statemem.stafffx.entity:SetParent(inst.entity)
					inst.sg.statemem.stafffx.Transform:SetRotation(inst.Transform:GetRotation())
					inst.sg.statemem.stafffx:SetUp(visuals.fxColour or {1, 1, 1, 1})
				end
			end

			--inst.sg:SetTimeout(castTime)
			return
		end

		inst.sg:GoToState("idle")
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
			if inst.sg:HasStateTag("casting")  then
				inst.sg:GoToState("idle") 
			end
		end), 
	},

	timeline =
	{
		TimeEvent(58 * FRAMES, function(inst)
			local sm = inst.sg.statemem
			inst:PerformBufferedAction()
			inst.sg:RemoveStateTag("busy")
			inst.sg:RemoveStateTag("casting")
		end),
	}
}

local gfthrow = State{
	name = "gfthrow",
	tags = { "casting", "busy", "doing", "nomorph" },

	onenter = function(inst)
		inst.components.locomotor:Stop()
		
		local act = inst:GetBufferedAction()
		if act and act.spell then
			if act.pos then
				inst:ForceFacePoint(act.pos.x, 0, act.pos.z)
			end
			inst.AnimState:PlayAnimation("throw")

			return
		end
		--failed
		inst.sg:GoToState("idle")
	end,

	timeline =
	{
		TimeEvent(7 * FRAMES, function(inst)
			inst:PerformBufferedAction()
			inst.sg.statemem.throwed = true
			inst.SoundEmitter:PlaySound("dontstarve/common/lava_arena/whoosh")
		end),
	},

	events =
	{
		EventHandler("animover", function(inst)
			inst.sg:GoToState("idle")
		end),

		EventHandler("unequip", function(inst) 
			if not inst.sg.statemem.throwed then
				inst.sg:GoToState("idle") 
			end
		end),
	},
}

--groundslam
local gfgroundslam = State{
	name = "gfgroundslam",
	tags = { "casting", "doing", "busy", "nomorph" },

	onenter = function(inst)
		inst.components.locomotor:Stop()

		local act = inst:GetBufferedAction()
		if act and act.spell then
			if act.pos then
				inst:ForceFacePoint(act.pos.x, 0, act.pos.z)
			end
			
			inst.AnimState:PlayAnimation("atk_leap_pre")
			inst.AnimState:PushAnimation("atk_leap", false)
			
			return
		end

		inst.sg:GoToState("idle")
	end,

	events =
	{
		EventHandler("animqueueover", function(inst)
			if inst.AnimState:AnimDone() then
				inst.sg:GoToState("idle")
			end
		end),
		EventHandler("unequip", function(inst) 
			if inst.sg:HasStateTag("casting")  then
				inst.sg:GoToState("idle") 
			end
		end), 
	},

	timeline =
	{
		TimeEvent(26 * FRAMES, function(inst)
			if inst.AnimState:IsCurrentAnimation("atk_leap") then
				inst.sg:RemoveStateTag("casting")
				inst.sg:RemoveStateTag("busy")
				inst:PerformBufferedAction()
            end
		end),
	}
}

local gfreadscroll = State
{
	name = "gfreadscroll",
	tags = {"doing", "casting", "busy", "nodangle"},

	onenter = function(inst)
		inst.components.locomotor:Stop()

		local act = inst:GetBufferedAction()
		if act and act.spell then
			local castTime = math.max(1.75, GetSpellCastTime(act.spell))
			if act.pos then
				inst:ForceFacePoint(act.pos.x, 0, act.pos.z)
			end

			local item = act.invobject
			local swapBuild, swapSymbol
			swapBuild = (item and item.swapBuild) and item.swapBuild or "swap_gw_scroll"
			swapSymbol = (item and item.swapSymbol) and item.swapSymbol or "swap_gw_scroll"

			inst.AnimState:PlayAnimation("scroll_open", false) 
			inst.AnimState:PushAnimation("scroll_loop", true) 
			inst.AnimState:OverrideSymbol("book", swapBuild, swapSymbol)
			inst.AnimState:Hide("ARM_carry") 
			inst.AnimState:Show("ARM_normal")
			inst.SoundEmitter:PlaySound("dontstarve/common/use_book") 

			inst.sg:SetTimeout(castTime)
			return
		end

		inst.sg:GoToState("idle")
	end,

	ontimeout = function(inst)
		inst.sg:RemoveStateTag("casting")
		inst.sg:RemoveStateTag("busy")
		inst:PerformBufferedAction()
		inst.AnimState:PlayAnimation("scroll_pst", false)
	end,

	onexit = function(inst)
		if inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
			inst.AnimState:Show("ARM_carry") 
			inst.AnimState:Hide("ARM_normal")
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
			if inst.sg:HasStateTag("casting") then
				inst.sg:GoToState("idle") 
			end
		end), 
	},
}

local gftwirlcast = State
{
	name = "gftwirlcast",
	tags = {"doing", "casting", "busy", "nodangle"},

	onenter = function(inst)
		inst.components.locomotor:Stop()

		local act = inst:GetBufferedAction()
		if act and act.spell then
			if act.pos then
				inst:ForceFacePoint(act.pos.x, 0, act.pos.z)
			end
			inst.AnimState:PlayAnimation("lunge_pre")
			inst.AnimState:PushAnimation("lunge_pst", false)

			return
		end

		inst.sg:GoToState("idle")
	end,

	onexit = function(inst)
		inst.components.colouradder:PopColour("lunge")
	end,

	onupdate = function(inst)
		if inst.sg.statemem.flash ~= nil and inst.sg.statemem.flash > 0 then
			inst.sg.statemem.flash = math.max(0, inst.sg.statemem.flash - .1)
			inst.components.colouradder:PushColour("lunge", inst.sg.statemem.flash, inst.sg.statemem.flash, 0, 0)
		end
	end,

	timeline =
	{
		TimeEvent(4 * FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/common/twirl", nil, nil, true)
		end),
	},

	events =
	{
		EventHandler("animover", function(inst)
			if not inst.AnimState:AnimDone() then
				if inst.AnimState:IsCurrentAnimation("lunge_pst") then
					inst.sg:RemoveStateTag("casting")
					inst:PerformBufferedAction()
					inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon")
					inst.SoundEmitter:PlaySound("dontstarve/common/lava_arena/fireball")
					inst.sg.statemem.flash = 1
				end
			else
				inst.sg:GoToState("idle")
			end
		end),

		EventHandler("unequip", function(inst) 
			if inst.sg:HasStateTag("casting") then
				inst.sg:GoToState("idle") 
			end
		end), 
	},
}

local gfbookcast = State
{
	name = "gfbookcast",
	tags = {"doing", "casting", "busy", "nodangle"},

	onenter = function(inst)
		inst.components.locomotor:Stop()

		local act = inst:GetBufferedAction()
		if act and act.spell then
			if act.pos then
				inst:ForceFacePoint(act.pos.x, 0, act.pos.z)
			end

			local item = act.invobject
			local swapBuild = (item and item.swapBuild) and item.swapBuild or "player_actions_uniqueitem"

			inst.AnimState:OverrideSymbol("book_open", swapBuild, "book_open")
            inst.AnimState:OverrideSymbol("book_closed", swapBuild, "book_closed")
			inst.AnimState:OverrideSymbol("book_open_pages", swapBuild, "book_open_pages")

			inst.AnimState:PlayAnimation("action_uniqueitem_pre")
			inst.AnimState:PushAnimation("book", false)

			inst.SoundEmitter:PlaySound("dontstarve/common/use_book") 

			local visuals = ALL_SPELLS[act.spell].stateVisuals
			if visuals ~= nil then
				if visuals.fxColour ~= nil then
					inst.sg.statemem.bookfx = SpawnPrefab(inst.components.rider:IsRiding() and "book_fx_mount" or "book_fx")
					inst.sg.statemem.bookfx.entity:SetParent(inst.entity)
					inst.sg.statemem.bookfx.Transform:SetRotation(inst.Transform:GetRotation())
					inst.sg.statemem.bookfx.AnimState:SetMultColour(_G.unpack(visuals.fxColour))
				end
			end

			return
		end

		inst.sg:GoToState("idle")
	end,

	onexit = function(inst)
		if inst.sg.statemem.bookfx ~= nil and inst.sg.statemem.bookfx:IsValid() then
			inst.sg.statemem.bookfx:Remove()
		end
	end,

	timeline =
	{
		TimeEvent(28 * FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/common/use_book_light")
		end),
		TimeEvent(54 * FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/common/use_book_close")
		end),
		TimeEvent(58 * FRAMES, function(inst)
			if inst.sg.statemem.bookfx ~= nil then
				if inst.sg.statemem.bookfx:IsValid() then
					(inst.sg.statemem.bookfx.KillFX or inst.sg.statemem.bookfx.Remove)(inst.sg.statemem.bookfx)
				end
				inst.sg.statemem.bookfx = nil
			end
			inst.sg.statemem.book_fx = nil
			inst.sg:RemoveStateTag("casting")
			inst.sg:RemoveStateTag("busy")
			inst:PerformBufferedAction()
		end),
	},

	events =
	{
		EventHandler("animqueueover", function(inst)
			if inst.AnimState:AnimDone() then
				inst.sg:GoToState("idle")
			end
		end),

		EventHandler("unequip", function(inst) 
			if inst.sg:HasStateTag("casting") then
				inst.sg:GoToState("idle") 
			end
		end), 
	},
}

local gfhighleap = State{
	name = "gfhighleap",
	tags = { "doing", "busy", "casting", "nopredict", "nomorph" },

	onenter = function(inst)
		inst.components.locomotor:Stop()

		local act = inst:GetBufferedAction()
		if act and act.spell and act.pos and IsValidGround(act.pos) then
			inst:ForceFacePoint(act.pos:Get())
			local castTime = math.max(0.75, GetSpellCastTime(spell))

			inst.AnimState:PlayAnimation("superjump_pre")
			inst.AnimState:PushAnimation("superjump", false)

			inst.sg.statemem.targetPos = act.pos
			inst.sg:SetTimeout(math.max(0.8, castTime))

			return
		end

		inst.sg:GoToState("idle")
	end,

	ontimeout = function(inst)
		inst.sg:GoToState("gfhighleapdone", inst.sg.statemem.targetPos)--, inst.sg.statemem.buffact)
	end,

	onexit = function(inst)
		inst.DynamicShadow:Enable(true)
		inst.components.colouradder:PopColour("superjump")
		inst.components.health:SetInvincible(false)
	end,

	timeline =
	{
		TimeEvent(FRAMES, function(inst)
			if inst.sg.statemem.jumping then
				inst.components.colouradder:PushColour("superjump", .3, .3, .2, 0)
			end
		end),
		
		TimeEvent(2 * FRAMES, function(inst)
			if inst.sg.statemem.jumping then
				inst.components.colouradder:PushColour("superjump", .6, .6, .4, 0)
			end
		end),
	},

	events =
	{
		EventHandler("animover", function(inst)
			if not inst.AnimState:AnimDone() then
				if inst.AnimState:IsCurrentAnimation("superjump") then
					inst.sg:AddStateTag("nointerrupt")
					inst.components.health:SetInvincible(true)
					inst.DynamicShadow:Enable(false)
				end
			end
		end),

		EventHandler("unequip", function(inst) 
			if inst.sg:HasStateTag("casting") then
				inst.sg:GoToState("idle") 
			end
		end), 
	},
}

local gfhighleapdone = State{
	name = "gfhighleapdone",
	tags = { "doing", "busy", "casting", "nopredict", "nomorph", "nointerrupt" },

	onenter = function(inst, pos)
		if pos ~= nil then
			inst.Transform:SetPosition(pos:Get())
			inst.AnimState:PlayAnimation("superjump_land")
			inst.DynamicShadow:Enable(false)
			inst.components.health:SetInvincible(true)
			inst.sg.statemem.flash = 0
			return
		end

		inst.sg:GoToState("idle") 
	end,

	onupdate = function(inst)
		if inst.sg.statemem.flash > 0 then
			inst.sg.statemem.flash = math.max(0, inst.sg.statemem.flash - .1)
			local c = math.min(1, inst.sg.statemem.flash)
			inst.components.colouradder:PushColour("superjump", c, c, 0, 0)
		end
	end,

	onexit = function(inst)
		inst.DynamicShadow:Enable(true)
		inst.components.colouradder:PopColour("superjump")
		inst.components.health:SetInvincible(false)
	end,

	timeline =
	{
		TimeEvent(FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon")
			inst.components.colouradder:PushColour("superjump", .1, .1, 0, 0)
		end),

		TimeEvent(2 * FRAMES, function(inst)
			inst.components.colouradder:PushColour("superjump", .2, .2, 0, 0)
		end),

		TimeEvent(3 * FRAMES, function(inst)
			inst.components.colouradder:PushColour("superjump", .4, .4, 0, 0)
			inst.DynamicShadow:Enable(true)
		end),

		TimeEvent(4 * FRAMES, function(inst)
			inst.components.colouradder:PushColour("superjump", 1, 1, 0, 0)
			inst.components.bloomer:PushBloom("superjump", "shaders/anim.ksh", -2)
			inst.sg.statemem.flash = 1.3
			ShakeAllCameras(CAMERASHAKE.VERTICAL, .7, .015, .2, inst, 5)
			local fx = SpawnPrefab("superjump_debris")
			if fx then fx.Transform:SetPosition(inst.Transform:GetWorldPosition()) end
			inst:PerformBufferedAction()
		end),

		TimeEvent(8 * FRAMES, function(inst)
			inst.components.bloomer:PopBloom("superjump")
			local act = inst.sg.statemem.buffact
			if act ~= nil and act.action == ACTIONS.GFCASTSPELL and act.spell and ALL_SPELLS[act.spell] then
				ALL_SPELLS[act.spell]:DoPostCast(inst, act.target, act.pos)
			end
			inst.components.health:SetInvincible(false)
			inst.sg:RemoveStateTag("nointerrupt")
			inst.sg:RemoveStateTag("busy")
		end),
	},

	events =
	{
		EventHandler("animover", function(inst)
			inst.sg:GoToState("idle") 
		end),

		EventHandler("unequip", function(inst) 
			if inst.sg:HasStateTag("casting") then
				inst.sg:GoToState("idle") 
			end
		end), 
	},
}

local gftdartshoot = State
{
	name = "gftdartshoot",
	tags = {"doing", "casting", "busy", "nodangle"},

	onenter = function(inst)
		inst.components.locomotor:Stop()

		local act = inst:GetBufferedAction()
		if act and act.spell then
			if act.pos then
				inst:ForceFacePoint(act.pos.x, 0, act.pos.z)
			end
			inst.AnimState:PlayAnimation("dart_pre")
			inst.AnimState:PushAnimation("dart_long", false)

			return
		end

		inst.sg:GoToState("idle")
	end,

	timeline =
	{
		TimeEvent(13 * FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/wilson/blowdart_shoot")
		end),
		TimeEvent(14 * FRAMES, function(inst)
			inst:PerformBufferedAction()
			inst.sg:RemoveStateTag("casting")
			inst.sg:RemoveStateTag("busy")
		end),
	},

	events =
	{
		EventHandler("animqueueover", function(inst)
			if inst.AnimState:AnimDone() then
				inst.sg:GoToState("idle")
			end
		end),

		EventHandler("unequip", function(inst) 
			if inst.sg:HasStateTag("casting") then
				inst.sg:GoToState("idle") 
			end
		end), 
	},
}

local gfleap = State{
	name = "gfleap",
	tags = { "doing", "busy", "casting", "nomorph" },

	onenter = function(inst)
		inst.components.locomotor:Stop()

		local act = inst:GetBufferedAction()
		if act and act.spell and act.pos and IsValidGround(act.pos) then
			inst:ForceFacePoint(act.pos:Get())
			inst.AnimState:PlayAnimation("atk_leap_pre")
			inst.sg.statemem.targetPos = act.pos

			return
		end

		inst.sg:GoToState("idle")
	end,

	events =
	{
		EventHandler("animover", function(inst)
			inst.sg:GoToState("gfleapdone", inst.sg.statemem.targetPos)
		end),

		EventHandler("unequip", function(inst) 
			inst.sg:GoToState("idle") 
		end), 
	},
}

local gfleapdone = State{
	name = "gfleapdone",
	tags = { "doing", "busy", "casting", "nopredict", "nomorph", "nointerrupt" },

	onenter = function(inst, pos)
		if pos ~= nil then
			ToggleOffPhysics(inst)
			inst.AnimState:PlayAnimation("atk_leap")
			inst.SoundEmitter:PlaySound("dontstarve/common/deathpoof")
			local spos = inst:GetPosition()
			if spos.x ~= pos.x or spos.z ~= pos.z then
				inst:ForceFacePoint(pos:Get())
				inst.Physics:SetMotorVel(math.sqrt(distsq(spos.x, spos.z, pos.x, pos.z)) / (12 * FRAMES), 0 ,0)
			end

			inst.sg.statemem.spos = spos
			inst.sg.statemem.tpos = pos

			return
		end

		inst.sg:GoToState("idle") 
	end,

	--[[ onupdate = function(inst)
		if inst.sg.statemem.flash > 0 then
			inst.sg.statemem.flash = math.max(0, inst.sg.statemem.flash - .1)
			local c = math.min(1, inst.sg.statemem.flash)
			inst.components.colouradder:PushColour("superjump", c, c, 0, 0)
		end
	end,]]

	onexit = function(inst)
		if inst.sg.statemem.isphysicstoggle then
			ToggleOnPhysics(inst)
			inst.Physics:Stop()
			inst.Physics:SetMotorVel(0, 0, 0)
			local x, y, z = inst.Transform:GetWorldPosition()
			if IsValidGround(Vector3(x, 0, z)) then
				inst.Physics:Teleport(x, 0, z)
			else
				inst.Physics:Teleport(inst.sg.statemem.tpos.x, 0, inst.sg.statemem.tpos.z)
			end
		end
	end,

	timeline =
	{
		TimeEvent(12 * FRAMES, function(inst)
			ToggleOnPhysics(inst)
			inst.Physics:Stop()
			inst.Physics:SetMotorVel(0, 0, 0)
			inst.Physics:Teleport(inst.sg.statemem.tpos.x, 0, inst.sg.statemem.tpos.z)
		end),
		TimeEvent(13 * FRAMES, function(inst)
			ShakeAllCameras(CAMERASHAKE.VERTICAL, .7, .015, .8, inst, 20)
			inst:PerformBufferedAction()
			inst.sg:RemoveStateTag("nointerrupt")
		end),
	},

	events =
	{
		EventHandler("animover", function(inst)
			inst.sg:GoToState("idle") 
		end),

		EventHandler("unequip", function(inst) 
			inst.sg:GoToState("idle") 
		end), 
	},
}

local gfflurry = State
{
	name = "gfflurry",
	tags = {"doing", "casting", "busy", "nodangle"},

	onenter = function(inst)
		inst.components.locomotor:Stop()

		local act = inst:GetBufferedAction()
		if act and act.spell then
			if act.pos then
				inst:ForceFacePoint(act.pos.x, 0, act.pos.z)
			end
			inst.AnimState:PlayAnimation("multithrust_yell")
			inst.AnimState:PushAnimation("multithrust", false)

			return
		end

		inst.sg:GoToState("idle")
	end,

	onexit = function(inst)
		inst.Transform:SetFourFaced()
	end,

	timeline =
	{
		TimeEvent(18 * FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon")
		end),
		TimeEvent(22 * FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon")
			inst:PerformBufferedAction()
			inst.sg:RemoveStateTag("casting")
			inst.sg:RemoveStateTag("busy")
		end),
	},

	events =
	{
		EventHandler("animover", function(inst)
			if not inst.AnimState:AnimDone() then
				if inst.AnimState:IsCurrentAnimation("multithrust") then
					inst.Transform:SetEightFaced()
				end
			else
				inst.sg:GoToState("idle")
			end
		end),

		EventHandler("unequip", function(inst) 
			if inst.sg:HasStateTag("casting") then
				inst.sg:GoToState("idle") 
			end
		end), 
	},
}

local gfcraftcast = State
{
	name = "gfcraftcast",
	tags = {"doing", "casting", "busy", "nodangle"},

	onenter = function(inst)
		inst.components.locomotor:Stop()

		local act = inst:GetBufferedAction()
		if act and act.spell then
			local castTime = math.max(0.75, GetSpellCastTime(act.spell))

			inst.AnimState:PlayAnimation("build_pre", false) 
			inst.AnimState:PushAnimation("build_loop", true) 
			inst.SoundEmitter:PlaySound("dontstarve/wilson/make_trap", "make_preview")

			inst.sg:SetTimeout(castTime)
			return
		end

		inst.sg:GoToState("idle")
	end,

	ontimeout = function(inst)
		inst.sg:RemoveStateTag("casting")
		inst.sg:RemoveStateTag("busy")
		inst:PerformBufferedAction()
		inst.AnimState:PlayAnimation("build_pst", false)
	end,

	onexit = function(inst)
		inst.SoundEmitter:KillSound("make_preview")
	end,

	events =
	{
		EventHandler("animqueueover", function(inst)
			if inst.AnimState:AnimDone() then
				inst.sg:GoToState("idle")
			end
		end),

		EventHandler("unequip", function(inst) 
			if inst.sg:HasStateTag("casting") then
				inst.sg:GoToState("idle") 
			end
		end), 
	},
}

--that's awful
--TODO - make this less awful
local gfparry = State
{
	name = "gfparry",
	tags = {"doing", "casting", "busy", "nodangle", "parryhit", "parrying"},

	onenter = function(inst, data)
		inst.components.locomotor:Stop()

		local act = inst:GetBufferedAction()
		if act and act.spell then
			local spellParams = ALL_SPELLS[act.spell]:GetSpellParams()
			local castTime = math.max(1.25, GetSpellCastTime(act.spell))
			local redir = SpawnPrefab("gf_redirect_dummy")
			absorb = (spellParams ~= nil and spellParams.absorb ~= nil)
				and spellParams.absorb
				or 100

			inst.sg.statemem.remain = castTime
			inst.sg.statemem.redir = redir
			inst.sg.statemem.absorb = absorb
			inst.sg.statemem.readytoparry = false

			inst.components.combat.redirectdamagefn = function(inst, attacker, damage, weapon, stimuli) 
				if inst.sg.statemem.redir ~= nil 
					and not inst.sg.statemem.redir.components.health:IsDead()
					and attacker ~= nil
					and stimuli == nil
				then
					local x, y, z = inst.Transform:GetWorldPosition()
					local xa, ya, za = attacker.Transform:GetWorldPosition()
					local angle = (math.atan2(xa - x, za - z) - 1.5708) --/ _G.DEGREES
					local look = inst.Transform:GetRotation() * _G.DEGREES

					--print(("before look %.2f, angle %.2f"):format(look, angle))

					angle = angle < -math.pi and angle + 6.28319 or angle
					look = look < -math.pi and look + 6.28319 or look

					--print(("after look %.2f, angle %.2f"):format(look, angle))

					return (math.abs(look - angle) < 1.5708) and inst.sg.statemem.redir or nil
				end

				return nil
			end

			inst.AnimState:PlayAnimation("parry_pre", false) 
			inst.AnimState:PushAnimation("parry_loop", true) 

			inst.sg:SetTimeout(castTime)
			return
		end

		inst.sg:GoToState("idle")
	end,

	ontimeout = function(inst)
		inst.sg:GoToState("gfparrypost")
	end,

	onexit = function(inst)
		inst.components.combat.redirectdamagefn = nil
		inst.sg.statemem.readytoparry = false
		if inst.sg.statemem.redir ~= nil and inst.sg.statemem.redir:IsValid() then
			inst.sg.statemem.redir:Remove()
		end
	end,

	timeline =
    {
        TimeEvent(4 * FRAMES, function(inst)
			inst.sg:RemoveStateTag("busy")
			inst:PerformBufferedAction()
			inst.sg.statemem.readytoparry = true
        end),
    },

	events =
	{
		EventHandler("unequip", function(inst) 
			if inst.sg:HasStateTag("casting") then
				inst.sg:GoToState("idle") 
			end
		end), 
		EventHandler("attacked", function(inst, data) 
			inst:PushEvent("attacked_hax", data)
		end), 
		EventHandler("attacked_hax", function(inst, data) 
			if inst.sg.statemem.readytoparry and inst.sg.statemem.absorb > 0 then
				if data.damageresolved == 0 then
					inst.sg.statemem.absorb = inst.sg.statemem.absorb - data.damage
					inst.AnimState:PlayAnimation("parryblock", false) 
					inst.AnimState:PushAnimation("parry_loop", true) 
					inst:PushEvent("parry", data)
				else
					inst.sg:GoToState(inst.sg:HasStateTag("nointerrupt") and "gfparrypost" or "hit")
				end
			else
				if data.damageresolved > 0 and not inst.sg:HasStateTag("nointerrupt") then
					inst.sg:GoToState("hit")
				else
					inst.sg:GoToState("gfparrypost")
				end
			end
		end), 
		EventHandler("ontalk", function(inst)
			if inst.sg.statemem.talktask ~= nil then
				inst.sg.statemem.talktask:Cancel()
				inst.sg.statemem.talktask = nil
				inst.SoundEmitter:KillSound("talk")
			end
			if true --[[_G.DoTalkSound(inst)]] then
				inst.sg.statemem.talktask =
					inst:DoTaskInTime(1.5 + math.random() * .5,
						function()
							inst.SoundEmitter:KillSound("talk")
							inst.sg.statemem.talktask = nil
						end)
			end
		end),
		EventHandler("donetalking", function(inst)
			if inst.sg.statemem.talktalk ~= nil then
				inst.sg.statemem.talktask:Cancel()
				inst.sg.statemem.talktask = nil
				inst.SoundEmitter:KillSound("talk")
			end
		end),
	},
}

local gfparrypost = _G.State
{
	name = "gfparrypost",
	tags = {"doing", "nodangle"},

	onenter = function(inst)
        inst.AnimState:PlayAnimation("parry_pst", false)
	end,

	events =
	{
		EventHandler("animover", function(inst)
            inst.sg:GoToState("idle")
		end),
	},
}

local gfmakeattention = _G.State
{
	name = "gfmakeattention",
	tags = {"doing", "nodangle"},

	onenter = function(inst)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("emoteXL_waving" .. math.random(3))
        local act = inst:GetBufferedAction()
		if act and act.target then
            act.target:PushEvent("gfQGGetAttention", inst)
        end
	end,

    timeline =
    {
        _G.TimeEvent(35 * _G.FRAMES, function(inst)
            inst:PerformBufferedAction()
        end),
    },

	events =
	{
		_G.EventHandler("animover", function(inst)
            inst.sg:GoToState("idle")
		end),
	},
}

--Add states--------------
AddStategraphState("wilson", gfdodrink)
AddStategraphState("wilson", gfcastwithstaff)
AddStategraphState("wilson", gfgroundslam)
AddStategraphState("wilson", gfchannelcast)
AddStategraphState("wilson", gfcustomcast)
AddStategraphState("wilson", gfreadscroll)
AddStategraphState("wilson", gftwirlcast)
AddStategraphState("wilson", gfbookcast)
AddStategraphState("wilson", gfhighleap)
AddStategraphState("wilson", gfhighleapdone)
AddStategraphState("wilson", gftdartshoot)
AddStategraphState("wilson", gfleap)
AddStategraphState("wilson", gfleapdone)
AddStategraphState("wilson", gfflurry)
AddStategraphState("wilson", gfcraftcast)
AddStategraphState("wilson", gfthrow)
AddStategraphState("wilson", gfparry)
AddStategraphState("wilson", gfparrypost)
AddStategraphState("wilson", gfmakeattention)

--Add events--------------
AddStategraphEvent("wilson", EventHandler("gfforcemove", function(inst, data)
	--hack for non-static spell range
	inst.components.locomotor:PushAction(data.act, true, true)
end))



--Add actions handlers----
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.GFDRINKIT, function(inst, act)
	local drink = act.target or act.invobject
	if drink == nil or drink.components.gfdrinkable == nil then return end
	local check, reason = drink.components.gfdrinkable:CheckBeforeDrunk(inst)
	if check then 
		return "gfdodrink"
	else
		inst:PushEvent("gfRefuseDrink", {reason = reason})
		return "idle"
	end
end))
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.GFENHANCEITEM, "dolongaction"))
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.GFLETSTALK, "gfmakeattention"))
--AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.GFTALKFORQUEST, "gfmakeattention"))

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.GFCASTSPELL, function(inst)
	if inst.components.gfspellpointer == nil or inst.components.gfspellcaster == nil then return "idle" end

	local act = inst:GetBufferedAction()
	local item = act.invobject
	local gfsp = inst.components.gfspellpointer

	--some spell need a position, but the "equipped" collector returns only a target
	if act.pos == nil then
		if act.target == nil then
			--if we don't have a target too (an instant spell from inventory or spell from panel) set caster as default target and get its position
			act.target = inst
			act.pos = Vector3(inst.Transform:GetWorldPosition())
		else
			act.pos = Vector3(act.target.Transform:GetWorldPosition())
		end
	end

	local spellName
	if act.spell ~= nil then --an instant spell without item (from the spell panel)
		spellName = act.spell
	elseif gfsp.currentSpell ~= nil then --get spell from the spell pointer
		spellName = gfsp.currentSpell
	elseif item and item.components.gfspellitem then --an instant spell with item
		--there is a chance that the item's current spell will be changed next frame after a player clicks a button
		--and incorrect spell will be picked? Maybe should push the spell in collectors?
		spellName = item.components.gfspellitem:GetCurrentSpell()
	end

	if spellName == nil or ALL_SPELLS[spellName] == nil or ALL_SPELLS[spellName].passive then return "idle" end --invalid spell

	local check, reason = CanCastSpell(spellName, inst, item, act.target, act.pos)
	if not check then
		inst:PushEvent("gfSCCastFailed", reason)
		return "idle"
	end

	local spell = ALL_SPELLS[spellName]
	local spellRange = spell:GetRange()

	if inst:GetDistanceSqToPoint(act.pos) > spellRange * spellRange then
		--if distance is greater then spell range, need to rebuffer the action 
		--and push a destination point to the locomotor
		--print("too far")
		inst:ClearBufferedAction()
		act.distance = spellRange
		act.spell = spellName
		inst:PushEvent("gfforcemove", {act = act})

		return "idle"
	else
		--if distance is valid then return the spell state
		--print("close enough")
		act.spell = spellName
		gfsp:Disable()

		--remove invalid target (FX, NOCLICK, shadows) from the action
		--this is a doble check for CanCastSpell
		--TODO - make this check in another place
		if not ALL_SPELLS[spellName].needTarget 
			and act.target ~= nil 
			and not ALL_SPELLS[spellName]:CheckTarget(inst, act.target) 
		then 
			act.target = nil 
		end
		
		--print("action", act, _G.PrintTable(act))
		return spell:GetPlayerState()
	end

    --action data is not valid for spell cast
	return "idle"
end))