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

local ALL_SPELLS = _G.GF.GetSpells()

local function GetSpellCastTime(spellName)
	if spellName and ALL_SPELLS[spellName] then 
		return ALL_SPELLS[spellName].castTime or 0
	end

	return 0
end

local function IsValidGround(pos)
	return _G.TheWorld.Map:IsPassableAtPoint(pos:Get()) and not _G.TheWorld.Map:IsGroundTargetBlocked(pos)
end

local function CanCastSpell(sName, inst, item, target, pos)
	if not inst.replica.gfspellcaster:IsSpellReady(sName) then
		return false, "NOTREADY"
	end
	if item and item.replica.gfspellitem and not item.replica.gfspellitem:IsSpellReady(sName) then --check item if exists
		return false, "ITEMNOTREADY"
	end

	return inst.replica.gfspellcaster:PreCastCheck(sName, target, pos)
end

--drink
local gfdodrink = State{
	name = "gfdodrink",
	tags = { "doing", "busy" },

	onenter = function(inst)
		inst.components.locomotor:Stop()
		inst.AnimState:PlayAnimation("action_uniqueitem_pre")
		inst.AnimState:PushAnimation("action_uniqueitem_lag", false)
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
} 

--custom  anim cast
local gfcustomcast = State
{
	name = "gfcustomcast",
	tags = { "doing", "casting", "busy", "nodangle" },

	onenter = function(inst)
		inst.components.locomotor:Stop()

		local act = inst:GetBufferedAction()
		if act and act.spell then
			if act.pos then
				inst:ForceFacePoint(act.pos.x, 0, act.pos.z)
			end
			inst.AnimState:PlayAnimation("gf_fast_cast_pre")
			inst.AnimState:PushAnimation("gf_fast_cast_loop", true)

			inst:PerformPreviewBufferedAction()
			inst.sg:SetTimeout(GetSpellCastTime(act.spell) + 1)
			
			return
		end

		inst.sg:GoToState("idle")
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
			if inst.sg:HasStateTag("casting") then
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
			if act.pos then
				inst:ForceFacePoint(act.pos.x, 0, act.pos.z)
			end
			inst.AnimState:PlayAnimation("channel_pre")
			inst.AnimState:PushAnimation("channel_loop", true)

			inst:PerformPreviewBufferedAction()
			inst.sg:SetTimeout(GetSpellCastTime(act.spell) + 1)
			
			return
		end

		inst.sg:GoToState("idle")
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
			if inst.sg:HasStateTag("casting") then
				inst.sg:GoToState("idle") 
			end 
		end),
	},
}

--STATES--
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

			inst:PerformPreviewBufferedAction()
			inst.sg:SetTimeout(2)
			
			return
		end

		inst.sg:GoToState("idle")
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
			if inst.sg:HasStateTag("casting") then
				inst.sg:GoToState("idle") 
			end
		end),
	},
}

local gfthrow = State{
	name = "gfthrow",
	tags = {"doing", "casting", "busy", "nodangle"},

	onenter = function(inst)
		inst.components.locomotor:Stop()

		local act = inst:GetBufferedAction()
		if act and act.spell then
			if act.pos then
				inst:ForceFacePoint(act.pos.x, 0, act.pos.z)
			end

			inst.AnimState:PlayAnimation("throw", false)

			inst:PerformPreviewBufferedAction()
			inst.sg:SetTimeout(2)
			return
		end

		inst.sg:GoToState("idle")
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
			if inst.sg:HasStateTag("casting") then
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

		inst.components.locomotor:Stop()
		local act = inst:GetBufferedAction()
		if act and act.spell then
			if act.pos then
				inst:ForceFacePoint(act.pos.x, 0, act.pos.z)
			end
			inst.AnimState:PlayAnimation("atk_leap_pre")
        	inst.AnimState:PushAnimation("atk_leap_lag", false)

			inst:PerformPreviewBufferedAction()
			inst.sg:SetTimeout(2)
			
			return
		end

		inst.sg:GoToState("idle")
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
			if inst.sg:HasStateTag("casting") then
				inst.sg:GoToState("idle") 
			end
		end),
	},
}

local gfreadscroll = State
{
	name = "gfreadscroll",
	tags = {"doing", "casting", "busy", "nodangle"},

	onenter = function(inst)
		inst.components.locomotor:Stop()

		local act = inst:GetBufferedAction()
		if act and act.spell then
			local castTime = math.max(0.75, GetSpellCastTime(act.spell))
			if act.pos then
				inst:ForceFacePoint(act.pos.x, 0, act.pos.z)
			end

			inst.AnimState:PlayAnimation("scroll_open", false) 
			inst.AnimState:PushAnimation("scroll_loop", true) 


			inst:PerformPreviewBufferedAction()
			inst.sg:SetTimeout(GetSpellCastTime(act.spell) + 1)
			return
		end

		inst.sg:GoToState("idle")
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

	--[[ onexit = function(inst)
		if inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
			inst.AnimState:Show("ARM_carry") 
			inst.AnimState:Hide("ARM_normal")
		end
	end, ]]

	events =
	{
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
			inst.AnimState:PushAnimation("lunge_lag", false)

			inst:PerformPreviewBufferedAction()
			inst.sg:SetTimeout(2)
			return
		end

		inst.sg:GoToState("idle")
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

			inst.AnimState:PlayAnimation("action_uniqueitem_pre")
			inst.AnimState:PushAnimation("action_uniqueitem_lag", false)

			inst:PerformPreviewBufferedAction()
			inst.sg:SetTimeout(2)
			return
		end

		inst.sg:GoToState("idle")
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
			if act.pos then
				inst:ForceFacePoint(act.pos.x, 0, act.pos.z)
			end

			local item = act.invobject

			inst.AnimState:PlayAnimation("superjump_pre")
			inst.AnimState:PushAnimation("superjump", false)

			inst:PerformPreviewBufferedAction()
			inst.sg:SetTimeout(2)
			return
		end

		inst.sg:GoToState("idle")
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
			if inst.sg:HasStateTag("casting") then
				inst.sg:GoToState("idle") 
			end
		end), 
	},
}

local gftdartshoot = State{
	name = "gftdartshoot",
	tags = {"doing", "casting", "busy", "nodangle"},

	onenter = function(inst)
		inst.components.locomotor:Stop()

		local act = inst:GetBufferedAction()
		if act and act.spell then
			if act.pos then
				inst:ForceFacePoint(act.pos.x, 0, act.pos.z)
			end

			inst.AnimState:PlayAnimation("dart_pre", false)

			inst:PerformPreviewBufferedAction()
			inst.sg:SetTimeout(2)
			return
		end

		inst.sg:GoToState("idle")
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
			if act.pos then
				inst:ForceFacePoint(act.pos.x, 0, act.pos.z)
			end

			inst.AnimState:PlayAnimation("atk_leap_pre")
			inst.AnimState:PushAnimation("atk_leap_lag", false)

			inst:PerformPreviewBufferedAction()
			inst.sg:SetTimeout(2)
			return
		end

		inst.sg:GoToState("idle")
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
			if inst.sg:HasStateTag("casting") then
				inst.sg:GoToState("idle") 
			end
		end), 
	},
}

local gfflurry = State{
	name = "gfflurry",
	tags = {"doing", "casting", "busy", "nodangle"},

	onenter = function(inst)
		inst.components.locomotor:Stop()

		local act = inst:GetBufferedAction()
		if act and act.spell then
			if act.pos then
				inst:ForceFacePoint(act.pos.x, 0, act.pos.z)
			end

			inst.AnimState:PlayAnimation("multithrust_yell", false)

			inst:PerformPreviewBufferedAction()
			inst.sg:SetTimeout(2)
			return
		end

		inst.sg:GoToState("idle")
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
			if inst.sg:HasStateTag("casting") then
				inst.sg:GoToState("idle") 
			end
		end), 
	},
}

local gfcraftcast = State{
	name = "gfcraftcast",
	tags = {"doing", "casting", "busy", "nodangle"},

	onenter = function(inst)
		inst.components.locomotor:Stop()

		local act = inst:GetBufferedAction()
		if act and act.spell then
			inst.AnimState:PlayAnimation("build_pre")
            inst.AnimState:PushAnimation("build_loop", true)

			inst:PerformPreviewBufferedAction()
			inst.sg:SetTimeout(2)
			return
		end

		inst.sg:GoToState("idle")
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
			if inst.sg:HasStateTag("casting") then
				inst.sg:GoToState("idle") 
			end
		end), 
	},
}

local gfparry = State{
	name = "gfparry",
	tags = {"doing", "casting", "busy", "nodangle"},

	onenter = function(inst)
		inst.components.locomotor:Stop()

		local act = inst:GetBufferedAction()
		if act and act.spell then
			if act.pos then
				inst:ForceFacePoint(act.pos.x, 0, act.pos.z)
			end

            inst.AnimState:PlayAnimation("parry_pre")
            inst.AnimState:PushAnimation("parry_loop", true)

            inst:PerformPreviewBufferedAction()
			inst.sg:SetTimeout(2)

			return
		end

		inst.sg:GoToState("idle")
	end,

	ontimeout = function(inst)
		inst:ClearBufferedAction()
		inst.sg:GoToState("idle")
	end,

	onupdate = function(inst)
		if inst:HasTag("busy") then
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
			if inst.sg:HasStateTag("casting") then
				inst.sg:GoToState("idle") 
			end
		end), 
	},
}

local gfmakeattention = State
{
	name = "gfmakeattention",
	tags = {"doing", "nodangle"},

	onenter = function(inst)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("emoteXL_waving" .. math.random(3))
        inst:PerformPreviewBufferedAction()
		inst.sg:SetTimeout(2)
		return
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
}

--Add states block--------------
AddStategraphState("wilson_client", gfmakeattention)
AddStategraphState("wilson_client", gfdodrink)
AddStategraphState("wilson_client", gfcastwithstaff)
AddStategraphState("wilson_client", gfgroundslam)
AddStategraphState("wilson_client", gfchannelcast)
AddStategraphState("wilson_client", gfcustomcast)
AddStategraphState("wilson_client", gfreadscroll)
AddStategraphState("wilson_client", gftwirlcast)
AddStategraphState("wilson_client", gfbookcast)
AddStategraphState("wilson_client", gfhighleap)
AddStategraphState("wilson_client", gftdartshoot)
AddStategraphState("wilson_client", gfleap)
AddStategraphState("wilson_client", gfflurry)
AddStategraphState("wilson_client", gfcraftcast)
AddStategraphState("wilson_client", gfthrow)
AddStategraphState("wilson_client", gfparry)

--Add events block--------------
AddStategraphEvent("wilson_client", EventHandler("gfforcemove", function(inst, data)
	--hack for non-static spell range
	inst.components.locomotor:PushAction(data.act, true, true)
end))

--Add actions handlers block----
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.GFDRINKIT, "gfdodrink"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.GFENHANCEITEM, "dolongaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.GFLETSTALK, "gfmakeattention"))
--AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.GFTALKFORQUEST, "gfmakeattention"))

AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.GFCASTSPELL, function(inst)
    if inst.components.gfspellpointer == nil or inst.replica.gfspellcaster == nil then return "idle" end

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
			act.pos = Vector3(inst.Transform:GetWorldPosition())
		end
	end

	local spellName
	if act.spell ~= nil then --an instant spell without item (from the spell panel)
		spellName = act.spell
	elseif gfsp.currentSpell ~= nil then --get spell from the spell pointer
		spellName = gfsp.currentSpell
	elseif item and item.replica.gfspellitem then --an instant spell with item
		--there is a chance that the item's current spell will be changed next frame after a player clicks a button
		--and incorrect spell will be picked? Maybe should push the spell in collectors?
		spellName = item.replica.gfspellitem:GetCurrentSpell()
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
		--gfsp:Disable()

		if not ALL_SPELLS[spellName].needTarget 
			and act.target ~= nil 
			and not ALL_SPELLS[spellName]:CheckTarget(inst, act.target) 
		then 
			act.target = nil 
		end

		return spell:GetPlayerState()
	end
    --action data is not valid for spell cast
	return "idle"
end))
