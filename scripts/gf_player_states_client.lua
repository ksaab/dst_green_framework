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

local function GetSpellCastTime(spellName)
	if spellName and spellList[spellName] then 
		return spellList[spellName].castTime or 0
	end

	return 0
end

local function IsValidGround(pos)
	return GLOBAL.TheWorld.Map:IsPassableAtPoint(pos:Get()) and not GLOBAL.TheWorld.Map:IsGroundTargetBlocked(pos)
end

local function CanCastSpell(spell, inst, item)
    local itemValid = true
    --check item if exists
    if item and item.replica.gfspellitem then 
        itemValid = item.replica.gfspellitem:CanCastSpell(spell)
    end

    --check doer
	local instValid = inst.replica.gfspellcaster and inst.replica.gfspellcaster:CanCastSpell(spell)
	local precastCheck = spellList[spell]:PreCastCheck(inst)

	return instValid and itemValid and precastCheck
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


--Add states block--------------
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

--Add events block--------------
AddStategraphEvent("wilson_client", EventHandler("gfforcemove", function(inst, data)
	--hack for non-static spell range
	inst.components.locomotor:PushAction(data.act, true, true)
end))

--Add actions handlers block----
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.GFDRINKIT, "gfdodrink"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.GFENHANCEITEM, "dolongaction"))

AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.GFCASTSPELL, function(inst)
    local act = inst:GetBufferedAction()
	local item = act.invobject
	local gfsp = inst.components.gfspellpointer 
	local spell
	local spellName
    
	if gfsp == nil or (act.pos == nil and act.target == nil) then return "idle" end

	if gfsp.currentSpell ~= nil then
		spellName = gfsp.currentSpell
	--Well, I don't know how to hook the name for an item-instant-spell in any other way
	elseif item and item.replica.gfspellitem then
		spellName = item.replica.gfspellitem:GetItemSpellName()	
	end

	if spellName == nil or spellList[spellName] == nil then return "idle" end --invalid spell name

	--gfsp:Disable()
	spell = spellList[spellName]

	if spell then
		if act.pos == nil then act.pos = Vector3(act.target.Transform:GetWorldPosition()) end
		local spellRange = spell:GetRange()
		if inst:GetDistanceSqToPoint(act.pos) > spellRange * spellRange then
			--print("to far")
			--if distace is greater then spell range, need to rebuffer the action 
			--and push a destination point to the locomotor
			inst:ClearBufferedAction()
			act.distance = spellRange
			act.spell = spellName
			inst:PushEvent("gfforcemove", {act = act})

			return "idle"
		else
			--print("close enough")
			--if distance is valid and item is not recharging
			--then go to item spell state
			if CanCastSpell(spellName, inst, item) then
				act.spell = spellName
				return spell:GetPlayerState()
			end
		end
	end

    --action data is not valid for spell cast
	return "idle"
end))
