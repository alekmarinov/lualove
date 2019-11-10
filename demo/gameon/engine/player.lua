--- Player module
-- @module gameon.engine.Player

local Player = {
    AI = "AI",
    HUMAN = "Human"
}
Player.__index = Player

function Player.new(options)
    local rules = options.rules
    local o = setmetatable({
        team = options.team,
        units = {},
        resources = {
            gold = rules.init_resources.gold or 0,
            wood = rules.init_resources.wood or 0,
            food = rules.init_resources.food or 0
        }
    }, Player)

    return o
end

return Player
