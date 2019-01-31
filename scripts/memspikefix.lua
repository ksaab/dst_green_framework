--Source https://gitlab.com/DSTAPIS/GemCore/blob/master/scripts/memspikefix.lua
--Thanks to NSimplex and Zarklord!

--[[
-- Receives a Prefab object, and tweaks its entity constructor ("fn") to
-- make the prefab be loaded before it is spawned.
--]]
local function MakeLazyLoader(prefab)
	if prefab.fn then
		local fn = prefab.fn
		local current_fn

		local function new_fn(...)
			TheSim:LoadPrefabs({prefab.name})

			-- Ensures this only runs once, for efficiency.
			current_fn = fn

			return fn(...)
		end

		current_fn = new_fn

		--[[
		-- This extra layer of indirection ensures greater mod friendliness.
		--
		-- If we just set prefab.fn to new_fn, and later back to fn, we could
		-- end up overriding an fn patch done by another mod. By switching between
		-- the two internally, via the current_fn upvalue, we preserve any such
		-- patching.
		--]]
		prefab.fn = function(...)
			return current_fn(...)
		end
	else
		--Prefab's without a .fn get loaded immediatly, since its just assets for Skins
		TheSim:LoadPrefabs({prefab.name})
	end
end


------------------------------------------------------------------------

local function FixModRecipe(rec)
	local placer_name = rec.placer or (rec.name.."_placer")
	local placer_prefab = Prefabs[placer_name]
	if not placer_prefab then return end

	placer_prefab.deps = placer_prefab.deps or {}
	table.insert(placer_prefab.deps, rec.name)
end

------------------------------------------------------------------------


ModManager.RegisterPrefabs = (function()
	local ModRegisterPrefabs = ModManager.RegisterPrefabs

	return function(self, ...)
		local ModWrangler_self = self

		local MainRegisterPrefabs = RegisterPrefabs

		local mod_prefabnames = {}

		RegisterPrefabs = function(...)
			for _, prefab in ipairs({...}) do
				local moddir = prefab.name:match("^MOD_(.+)$")
				if moddir then
					--print("MEMFIXING "..moddir)
					for _, name in ipairs(prefab.deps) do
						table.insert(mod_prefabnames, name)
					end

					prefab.deps = {}
					--print("Purged deps from "..prefab.name)
				end
			end
			return MainRegisterPrefabs(...)
		end

		ModRegisterPrefabs(self, ...)

		RegisterPrefabs = MainRegisterPrefabs

		-- First, do a pass over recipes to extend dependencies if need be.
		for _, prefabname in ipairs(mod_prefabnames) do
			local rec = AllRecipes[prefabname]
			if rec then
				FixModRecipe(rec)
			end
		end

		for _, prefabname in ipairs(mod_prefabnames) do
			--print("Registering "..prefabname)
			
			local prefab = Prefabs[prefabname]

			MainRegisterPrefabs(prefab)

			MakeLazyLoader(prefab)

			-- This also takes care of the unloading, so there's no need to patch ModWrangler:UnloadPrefabs.
			table.insert(self.loadedprefabs, prefabname)
		end
	end
end)()
