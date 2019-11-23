--- Player module
-- @module gameon.engine.Player

local thispackage = (...):match("(.-)[^%.]+$")
local pltablex = require "pl.tablex"
local RACES = require (thispackage..".enums").RACES

local Player = {
    AI = "AI",
    HUMAN = "Human",
    MENPOWER_LIMIT = 10,
    GOLD_RATE = 1,
    production_time = 0
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
    if o.type == "AI" then
        o.ai = o.game.AI.new{ player = o }
    end
    return o
end

function Player:addStructure(structure)
    structure:setPlayer(self)
    assert(not pltablex.find(self.structures, structure), "Structure already added")
    table.insert(self.structures, structure)
end

function Player:removeStructure(structure)
    local idx = assert(pltablex.find(self.structures, structure), "Can't find structure")
    table.remove(self.structures, idx)
end

function Player:addManpower(amount)
    self.resources.menpower = self.resources.menpower + amount
    if self.resources.menpower < 0 then
        self.resources.menpower = 0
    elseif self.resources.menpower > self.MENPOWER_LIMIT then
        self.resources.menpower = self.MENPOWER_LIMIT
    end
end

function Player:update(dt)
    for _, structure in ipairs(self.structures) do
        structure:update(dt)
    end
    self.production_time = self.production_time + dt * self.resources.menpower
    if self.production_time > self.GOLD_RATE then
        self.resources.gold = self.resources.gold + 1
        self.production_time = 0
    end
    if self.ai then
        self.ai:update(dt)
    end
end

function Player:build(unitclass, tile)
    if tile.units and #tile.units > 0 then
        print("Can't build unit on occuppied tile")
        return
    end
    if unitclass.gold > self.resources.gold then
        print("Not enough gold")
        return
    end
    if self.resources.menpower == 0 then
        print("Not enough menpower")
        return
    end
    self.resources.menpower = self.resources.menpower - 1
    self.resources.gold = self.resources.gold - unitclass.gold
    local unit = unitclass.new{ player = self }
    table.insert(self.units, unit)
    self.game.map:spawnSprite(unit, tile)
    return unit
end

function Player:removeUnit(unit)
    for i, u in ipairs(self.units) do
        if u == unit then
            table.remove(self.units, i)
            return
        end
    end
end

function Player:destroy()
    self.game:removePlayer(self)
    print("Player "..self.color.." has been destroyed")
end

return Player
