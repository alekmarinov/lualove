--- Player module
-- @module gameon.engine.Player

local thispackage = (...):match("(.-)[^%.]+$")
local RACES = require (thispackage..".enums").RACES

local Player = {
    AI = "AI",
    HUMAN = "Human"
}
Player.__index = Player

function Player.new(options)
    local o = setmetatable(options, Player)
    o.units = {}
    o.structures = {}
    o.resources = {
        gold = o.game.rules.init_resources.gold or 0,
        menpower = o.game.rules.init_resources.menpower or 0
    }
    if not o.color then
        assert(o.race, "race or color option is mandatory")
        assert(RACES[o.race], string.format("race %s is not supported", o.race))
        o.color = RACES[o.race].color
    end
    return o
end

function Player:addStructure(structure)
    structure:setPlayer(self)
    table.insert(self.structures, structure)
end

return Player
