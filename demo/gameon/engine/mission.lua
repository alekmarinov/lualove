
local Mission = {}
Mission.__index = Mission

function Mission.new(o)
    o = o or {}
    o.completed = false
    return setmetatable(o, Mission)
end

function Mission:update(dt)
end

function Mission:isCompleted()
    return self.completed
end

return Mission
