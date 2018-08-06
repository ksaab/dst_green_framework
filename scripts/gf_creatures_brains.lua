--local WhileNode = GLOBAL.WhileNode
--local DoAction = GLOBAL.DoAction
local spellList = GFSpellList
local ACTIONS = GLOBAL.ACTIONS
local BufferedAction = GLOBAL.BufferedAction

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
	GLOBAL.WhileNode(function() return self.inst.components.gfspellcaster end, "Can Cast",
		GLOBAL.DoAction(self.inst, CheckSpells, "Cast Spell", true, 3))

	for k, v in ipairs(self.bt.root.children) do
		if v.name == "Parallel" and v.children and v.children[1].name == "OnFire" then
			table.insert(self.bt.root.children, k + 1, DoCast)
			return 
		end
	end

	table.insert(self.bt.root.children, 1, DoCast)
end


AddBrainPostInit("pigbrain", MakeCaster)
AddBrainPostInit("bunnymanbrain", MakeCaster)
AddBrainPostInit("knightbrain", MakeCaster)