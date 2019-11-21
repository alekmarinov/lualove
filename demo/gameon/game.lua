--- Game module
-- @module gameon.Game
local thispackage = (...):match("(.-)[^%.]+$")

local Player = require (thispackage..".engine.player")

local Game = {
    players = {},
    currentPlayer = nil,
    teamgen = 0
}
Game.__index = Game

function Game:setRules(rules)
    self.rules = rules
end

function Game:newTeam()
    self.teamgen = self.teamgen + 1
    return self.teamgen
end

function Game:setMap(map)
    self.map = map
end

function Game:createPlayer(options)
    options.game = self
    options.team = options.team or self:newTeam()
    local player = Player.new(options)
    table.insert(self.players, player)
    return player
end

function Game:getPlayers(filter)
    filter = filter or {}
    local players = {}
    for _, player in ipairs(self.players) do
        local match = true
        for n, v in pairs(filter) do
            if player[n] ~= v then
                match = false
                break
            end
        end
        if match then
            table.insert(players, player)
        end
    end
    return players
end

function Game:createNeutralPlayer()
    self.neutralPlayer = self:createPlayer{
        team = 0,
        color = "CYAN"
    }
end

function Game:setCurrentPlayer(player)
    self.currentPlayer = player
end

function Game:getCurrentPlayer()
    return self.currentPlayer
end

return Game
