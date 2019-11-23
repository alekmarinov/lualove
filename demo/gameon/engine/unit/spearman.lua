local Unit = require "gameon.engine.unit"

local Spearman = setmetatable({
    speed = 1,
    range = 1,
    attack = 20,
    shield = 8,
    type = "spearman",
    attack_modifier = {
        horseman = 1.5
    },
    gold = 100
}, Unit)
Spearman.__index = Spearman

function Spearman.new(options)
    return setmetatable(Unit.new(options), Spearman)
end

return Spearman
