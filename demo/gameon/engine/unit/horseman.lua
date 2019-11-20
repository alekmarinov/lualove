local Unit = require "gameon.engine.unit"

local Horseman = setmetatable({
    range = 1,
    speed = 0.5,
    attack = 25,
    shield = 10,
    type = "horseman"
}, Unit)
Horseman.__index = Horseman

function Horseman.new(options)
    return setmetatable(Unit.new(options), Horseman)
end

return Horseman
