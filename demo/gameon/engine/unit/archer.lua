local Unit = require "gameon.engine.unit"

local Archer = setmetatable({
    speed = 1,
    range = 2,
    throw = "arrow",
    attack = 20,
    shield = 5,
    type = "archer",
    gold = 100
}, Unit)
Archer.__index = Archer

function Archer.new(options)
    return setmetatable(Unit.new(options), Archer)
end

return Archer
