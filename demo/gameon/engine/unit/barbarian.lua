local Unit = require "gameon.engine.unit"

local Barbarian = setmetatable({
    attack = 55,
    shield = 5
}, Unit)
Barbarian.__index = Barbarian

function Barbarian.new(...)
    return setmetatable(Unit.new(...), Barbarian)
end

return Barbarian
