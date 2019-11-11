--- Game module
-- @module gameon.Game

local thispackage = (...):match("(.-)[^%.]+$")

local Player = require (thispackage..".engine.player")

local Game = {
    players = {},
    currentPlayer = nil
}
Game.__index = Game

function Game:setRules(rules)
    self.rules = rules
end

function Game:setMap(map)
    self.map = map
end

function Game:createPlayer(options)
    options.game = self
    local player = Player.new(options)
    table.insert(self.players, player)
    return player
end

function Game:setCurrentPlayer(player)
    self.currentPlayer = player
end

function Game:getCurrentPlayer()
    return self.currentPlayer
end

return Game
