--- Player module
-- @module gameon.engine.Player

local Player = {
    AI = "AI",
    HUMAN = "Human"
}
Player.__index = Player

function Player.new(options)
    local o = setmetatable(options, Player)
    o.units = {}
    o.resources = {
        gold = o.game.rules.init_resources.gold or 0,
        wood = o.game.rules.init_resources.wood or 0,
        food = o.game.rules.init_resources.food or 0
    }
    return o
end

return Player
