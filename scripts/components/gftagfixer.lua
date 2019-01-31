--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.

local GFTagFixer = Class(function(self, inst)
    self.inst = inst
end)

function GFTagFixer:OnSave()
    return {}
end

function GFTagFixer:OnLoad(data, noremove)
    local inst = self.inst
    local alltags = string.sub(string.match(inst:GetDebugString(), "Tags:.-\n"), 7) --get all tags from the debug line
    if alltags ~= nil then
        local tmptags = {}
        local total = 0
        for id in alltags:gmatch("%S+") do
            total = total + 1
            if string.sub(id, 1, 1) ~= "_" then
                inst._tagfixnum = inst._tagfixnum - 1
                inst:_old_RemoveTag(id)
                table.insert(tmptags, id)
            end
        end
        print(string.format("total %i, non-replica %s", total, table.concat(tmptags, ', ')))
        for i = 1, #tmptags do
            inst:AddTag(tmptags[i])
        end
    end
    if noremove ~= true then
        inst:RemoveComponent("gftagfix")
    end
end

return GFTagFixer