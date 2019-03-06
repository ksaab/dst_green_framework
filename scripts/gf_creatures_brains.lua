--local WhileNode = _G.WhileNode
--local DoAction = _G.DoAction
local _G = GLOBAL
local ALL_SPELLS = _G.GF.GetSpells()
local ACTIONS = _G.ACTIONS
local BufferedAction = _G.BufferedAction

_G.require "behaviours/standstill"

local function CheckSpells(inst)
	if inst.spells ~= nil and inst:HasTag("spellcaster") then
		for k, v in pairs(inst.spells) do
			if v.AICanCastFn then
				local checkres = v:AICanCastFn()
				if checkres then
					local act = BufferedAction(inst, inst, ACTIONS.DOCASTSPELL)
					act.target = checkres.target
					act.range = checkres.range
					act.pos = checkres.pos
					act.spell = k

					return act
				end
			--else
				--print(("Spell %s has no AI check function"):format(k))
			end
		end
	end

	return false
end

local function CheckSpells(inst)
	local splcstr = inst.components.gfspellcaster
	if splcstr then
		local spellData = splcstr:GetValidAiSpell()
		if spellData then
			local act = BufferedAction(inst, inst, ACTIONS.GFCASTSPELL)
			act.target = spellData.target
			act.distance = spellData.distance or 12
			act.pos = spellData.pos
			act.spell = spellData.spell

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

AddBrainPostInit("pigbrain", MakeCaster)
AddBrainPostInit("pigbrain", MakeCalmChatter)
AddBrainPostInit("bunnymanbrain", MakeCaster)
AddBrainPostInit("knightbrain", MakeCaster)
AddBrainPostInit("ghostbrain", MakeCaster)
AddBrainPostInit("abigailbrain", MakeCaster)