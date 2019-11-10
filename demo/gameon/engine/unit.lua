--- Unit base module for all units in the game
-- @module gameon.engine.Unit

local thispackage = (...):match("(.-)[^%.]+$")

local pltablex = require "pl.tablex"
local Sprite = require (thispackage..".sprite")
local Animation = require (thispackage..".animation")
local MissionMove = require (thispackage..".mission.move")
local Game = require "gameon.game"

--- Base Unit table
-- @table Unit
local Unit = setmetatable({
    moveduration = 1
}, Sprite)
Unit.__index = Unit

function Unit.new(player, typename)
    local o = setmetatable(Sprite.new{
        player = player,
        typename = typename,
        action = "Idle"
    }, Unit)
    return o
end

function Unit:isFriendly(unit)
    return self.player.team == unit.player.team
end

function Unit:update(dt)
    Sprite.update(self, dt)
    if self.mission then
        if self.mission:update(dt) then
            self.mission = nil
        end
    end
end

function Unit:moveto(x, y)
    if self.mission then
        self.mission:abort()
    end
    local tileTo = self.map:getTileAtPixel(x, y)
    self.mission = MissionMove.new(self, tileTo)
end

return Unit
