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

function Game:setAI(AI)
    self.AI = AI
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

function Game:createNeutralPlayer(options)
    options.team = 0
    options.color = "CYAN"
    self.neutralPlayer = self:createPlayer(options)
end

function Game:setCurrentPlayer(player)
    self.currentPlayer = player
end

function Game:getCurrentPlayer()
    return self.currentPlayer
end

function Game:removePlayer(player)
    for i, p in ipairs(self.players) do
        if p == player then
            table.remove(self.players, i)
            if player == self.currentPlayer then
                self.currentPlayer = nil
            elseif player == self.neutralPlayer then
                self.neutralPlayer = nil
            end
            return
        end
    end
end

function Game:update(dt)
    for _, player in ipairs(self.players) do
        if #player.structures == 0 and #player.units == 0 then
            player:destroy()
            return
        end
        player:update(dt)
    end
end

function Game:getWinnerTeam()
    local lastteam = 0
    for i, p in ipairs(self.players) do
        if p.team ~= 0 and p.team ~= lastteam then
            if lastteam ~= 0 then
                -- Still two different teams are in game
                return 0
            end
            lastteam = p.team
        end
    end
    -- Last remaining team
    return lastteam
end

return Game
