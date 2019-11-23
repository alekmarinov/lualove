local Unit = require "gameon.engine.unit"

local Swordsman = setmetatable({
    speed = 1,
    range = 1,
    attack = 20,
    shield = 10,
    type = "swordsman",
    shield_modifier = {
        archer = 1.2
    },
    gold = 150
}, Unit)
Swordsman.__index = Swordsman

function Swordsman.new(options)
    return setmetatable(Unit.new(options), Swordsman)
end

return Swordsman
