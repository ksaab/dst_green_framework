local _G = GLOBAL

if _G.rawget(_G, "net_strstream") ~= nil then return end

local function _debug(inst) 
    print(string.format("string stream variable %s.%s has got the value %s", tostring(inst), var.event, var:value())) 
end

local NetStream = Class(function(self, inst, id, event, period, separator)
    print("net stream initialized:", inst, id)
    _G.assert(inst ~= nil and id ~= nil, "net stream requires instance and unique id")
    self.inst = inst
    self.event = event or id

    self.values = {}
    self.period = period or 0.5
    self.nexttick = _G.GetTime() + math.random() * self.period
    self.separator = separator or '^'

    self._value = _G.net_string(inst.GUID, id, self.event)
    self._task = nil

    --[[ inst:ListenForEvent(self.event, function()
        print(string.format("string stream variable %s.%s has got the value %s", 
            tostring(inst), self.event, self:value()))
    end) ]]
end)

function NetStream:DoTick()
    --print("concat value " .. table.concat(self.values, self.separator))
    self._value:set_local("")
    self._value:set(table.concat(self.values, self.separator))
    --print("netvar value " .. self._value:value())
    self.nexttick = _G.GetTime() + self.period
    self.values = {}
    self._task = nil
end

function NetStream:push(val)
    if val ~= nil then
        self:push_string(tostring(val))
    end
end

function NetStream:push_string(val)
    if val == nil then return end
    --print("pushing new value: " .. val .. " to " .. tostring(self.inst))
    table.insert(self.values, --[[#(self.values) + 1,]] val)
    if self._task == nil then
        local delta = self.nexttick - _G.GetTime()
        if delta > 0 then
            --print("Need to wait, last tick was recently...")
            self._task =self.inst:DoTaskInTime(delta, function() self:DoTick() end)
        else
            --print("Last tick was far ago, let tick now.")
            self._task =self.inst:DoTaskInTime(0, function() self:DoTick() end)
        end 
        --[[ local tick = self.nexttick > _G.GetTime() and self.period or 0
        self.inst:DoTaskInTime(tick, function() self:DoTick() end) ]]
    else
        --print("Value was pushed, waiting for tick...")
    end
end

function NetStream:value()
    return self._value:value()
end

function NetStream:GetNextTickTime()
    return self.nexttick
end

function NetStream:__tostring()
    return table.concat(self.values, self.separator)
end

_G.rawset(_G, "net_strstream", NetStream)