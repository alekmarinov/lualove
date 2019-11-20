local Unit = require "gameon.engine.unit"

local Doctor = setmetatable({
    speed = 1,
    range = 1,
    attack = 15,
    shield = 0,
    type = "doctor"
}, Unit)
Doctor.__index = Doctor

function Doctor.new(options)
    return setmetatable(Unit.new(options), Doctor)
end

return Doctor
