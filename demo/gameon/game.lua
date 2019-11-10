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

function Game:createPlayer(team)
    assert(self.rules, "No rules set. Call setRules first")
    local player = Player.new{
        rules = self.rules,
        team = team
    }
    table.insert(self.players, player)
    if not self.currentPlayer then
        self.currentPlayer = player
    end
end

function Game:getCurrentPlayer()
    return self.currentPlayer
end

return Game
