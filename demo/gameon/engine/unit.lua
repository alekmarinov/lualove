--- Unit base module for all units in the game
-- @module gameon.engine.Unit

local thispackage = (...):match("(.-)[^%.]+$")

local pltablex = require "pl.tablex"
local Sprite = require (thispackage..".sprite")
local Animation = require (thispackage..".animation")
local MissionMove = require (thispackage..".mission.move")
local MissionAttack = require (thispackage..".mission.attack")
local MissionPatrol = require (thispackage..".mission.patrol")

local Game = require "gameon.game"

--- Base Unit table
-- @table Unit
local Unit = setmetatable({
    moveDuration = 1,
    attackDuration = 1,
    health = 100,
}, Sprite)
Unit.__index = Unit

function Unit.new(player, typename)
    local o = setmetatable(Sprite.new{
        color = player.color,
        player = player,
        typename = typename,
        action = "Idle"
    }, Unit)
    return o
end

function Unit:setPos(x, y)
    local previousTile = self.currentTile
    Sprite.setPos(self, x, y)
    if previousTile ~= self.currentTile then
        if previousTile then
            self.map:removeUnitFromTile(self, previousTile)
        end
        self.map:addUnitToTile(self, self.currentTile)
    end
end

function Unit:isAlive()
    return self.health >= 0
end

function Unit:onFrameChanged(cycle, prevFrame, nextFrame)
    if self.mission then
        self.mission:onFrameChanged(cycle, prevFrame, nextFrame)
    end
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

function Unit:onSelected(selected)
    Sprite.onSelected(self, selected)
    if self.mission then
        self.mission:onSelected(selected)
    end
end

function Unit:moveTo(x, y, patrol)
    local tileto = self.map:getTileAtPixel(x, y)
    if patrol then
        if self.mission then
            if getmetatable(self.mission)._NAME == "MissionPatrol" then
                self.mission:togglePatrolTile(tileto)
                return 
            else
                self.mission:abort()
            end
        end
        self.mission = MissionPatrol.new(self, tileto)
        self.mission:onSelected(self:isSelected())
        return
    end
    if self.mission then
        self.mission:abort()
    end
    local otherUnit = self.map:getUnitAtTile(tileto)
    if otherUnit and not self:isFriendly(otherUnit) then
        -- attack unit
        self.mission = MissionAttack.new(self, otherUnit)
        self.mission:onSelected(self:isSelected())
    else
        -- moving
        self.mission = MissionMove.new(self, tileto)
        self.mission:onSelected(self:isSelected())
    end
end

function Unit:destroy()
    self.health = 0
    if self.mission then
        self.mission:abort()
    end
    if self.currentTile then
        self.map:removeUnitFromTile(self, self.currentTile)
    end
    Sprite.destroy(self)
end

-- this unit has been hit by another unit
function Unit:hit(otherUnit)
    print(self, "HIT by ", otherUnit)
end

-- this unit has been attempted to be hit but missed
function Unit:miss(otherUnit)
    print(self, "MISS by ", otherUnit)
end

return Unit
