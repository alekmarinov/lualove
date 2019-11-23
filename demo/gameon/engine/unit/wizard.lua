local Unit = require "gameon.engine.unit"

local Wizard = setmetatable({
    speed = 1,
    range = 3,
    throw = "ball",
    attack = 30,
    shield = 0,
    type = "wizard",
    gold = 300
}, Unit)
Wizard.__index = Wizard

function Wizard.new(options)
    return setmetatable(Unit.new(options), Wizard)
end

return Wizard
