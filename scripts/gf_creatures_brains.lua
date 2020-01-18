--local WhileNode = _G.WhileNode
--local DoAction = _G.DoAction
local _G = GLOBAL
local ALL_SPELLS = _G.GF.GetSpells()
local ACTIONS = _G.ACTIONS
local BufferedAction = _G.BufferedAction
--local DynamicPosition = _G.DynamicPosition or function(pos) return pos end
local Vector3 = _G.Vector3

_G.require "behaviours/standstill"

local function CheckSpells(inst)
	local splcstr = inst.components.gfspellcaster
	if splcstr then
		local spellData = splcstr:GetValidAiSpell()
		if spellData then
			local act = BufferedAction(inst, inst, ACTIONS.GFCASTSPELL)
			if act.SetActionPoint then
				act._vanillaPos = spellData.pos or Vector3(inst.Transform:GetWorldPosition())
				act:SetActionPoint(act._vanillaPos)
			else
				act.pos = spellData.pos or Vector3(inst.Transform:GetWorldPosition())
			end
			act.target = spellData.target or inst
			act.distance = spellData.distance or 12
			act.spell = spellData.spell
			act.params = spellData.params

			return act
		end
	end

	return false
end

local function MakeCaster(self)
	local DoCast = 
	_G.WhileNode(function() return self.inst.components.gfspellcaster end, "Can Cast",
		_G.DoAction(self.inst, CheckSpells, "Cast Spell", true, 3))

	for k, v in ipairs(self.bt.root.children) do
		if v.name == "Parallel" and v.children and v.children[1].name == "OnFire" then
			--print("inserting caster node after OnFire")
			table.insert(self.bt.root.children, k + 1, DoCast)
			return 
		end
	end

	--print("inserting caster node at first position")
	table.insert(self.bt.root.children, 1, DoCast)
end

local function GetInterlocutor(inst)
	if inst.components.gfinterlocutor and inst.components.gfinterlocutor.isBusy then
		return inst.components.gfinterlocutor._interlocutor
	end
end

local function KeepConversation(inst)
	return inst.components.gfinterlocutor ~= nil and inst.components.gfinterlocutor.isBusy
end

local function MakeCalmChatter(self)
	local DoChat = 
	_G.FaceEntity(self.inst, GetInterlocutor, KeepConversation)

	for k, v in ipairs(self.bt.root.children) do
		--print(v.name)
		if v.name == "ChattyNode" and v.children and v.children[1].name == "FaceEntity" then-- and v.children[1].name == "OnFire" then
			--print("inserting chatter node before trader")
			table.insert(self.bt.root.children, k, DoChat)
			return 
		end
	end

	--print("inserting chatter node at first position")
	table.insert(self.bt.root.children, 1, DoChat)
end

AddBrainPostInit("pigbrain", MakeCalmChatter)

AddBrainPostInit("pigbrain", MakeCaster)
AddBrainPostInit("bunnymanbrain", MakeCaster)
AddBrainPostInit("knightbrain", MakeCaster)
AddBrainPostInit("ghostbrain", MakeCaster)
AddBrainPostInit("abigailbrain", MakeCaster)
AddBrainPostInit("tallbirdbrain", MakeCaster)
AddBrainPostInit("spiderbrain", MakeCaster)
AddBrainPostInit("batbrain", MakeCaster)
AddBrainPostInit("houndbrain", MakeCaster)