
local Mission = require "gameon.engine.mission"
local Animation = require "gameon.engine.animation"

local MoveMission = setmetatable({
    moveprops = { "x", "y" },
    WAIT_TIME_START = 1,
    WAIT_TIME_MAX = 2,
    MAX_WAIT_ATTEMPTS = 4
}, Mission)
MoveMission.__index = MoveMission

local function animation_callback_update(unit, x, y)
    unit:setPos(x, y)
end

function MoveMission.new(unit, tileto)
    local o = setmetatable(Mission.new{
        unit = unit,
        tileto = tileto,
        map = unit.map,
        movesteps = {},
        moveto = { x = 0, y = 0 },
        wait = 0,
        wait_attempt = 0,
        wait_time = MoveMission.WAIT_TIME_START,
        completed = false
    }, MoveMission)
    return o
end

function MoveMission:reserveTile(tile)
    self:unreserveTile()
    self.reservedTile = tile
    self.map:reserveTileForUnit(self.unit, tile)
end

function MoveMission:unreserveTile()
    if self.reservedTile then
        self.map:unreserveTileFromUnit(self.unit, self.reservedTile)
        self.reservedTile = nil
    end
end

function MoveMission:update(dt)
    if self.completed then
        return true
    end
    if self.wait_attempt == MoveMission.MAX_WAIT_ATTEMPTS then
        -- waiting attempts to finish the mission exceeded max allowed, aborting the mission
        print("waiting attempts to finish the mission exceeded max allowed, aborting the mission")
        self:abort(true)
        return true
    end
    if self.wait > 0 then
        self.wait = math.max(0, self.wait - dt)
        return
    end
    if self.moveAnimation then
        if self.moveAnimation:update(dt) then
            -- moving finished
            self.moveAnimation = nil
            table.remove(self.movesteps, 1)
        else
            -- just moving
            return false
        end
    end
    local currentTile = self.unit:getCurrentTile()
    if currentTile == self.tileto then
        -- mission completed
        self:abort(true)
        return true
    end
    if #self.movesteps < 2 then
        -- create moving steps
        local excluded = {}
        if self.tilefrom then
            excluded[self.tilefrom] = true
        end
        if self.wait_time > MoveMission.WAIT_TIME_START then
            self.movesteps = self.map:findPathFast(currentTile, self.tileto, excluded)
        else
            self.movesteps = self.map:findPath(currentTile, self.tileto, excluded)
        end
        if #self.movesteps == 1 then
            -- can't find path to destination
            print(self.unit, "No path to destination!")
            self:waiting()
            self:abort()
        end
    end
    if #self.movesteps > 1 then
        local nextTile = self.movesteps[2]
        local otherUnit = self.map:getUnitAtTile(nextTile)
        if otherUnit then
            local otherUnit = nextTile.units[1]
            print(self.unit, "Have units in the destination tile!")
            self:waiting()
            self:abort()
            return false
        end
        if self.map:isTileReserved(nextTile) then
            print(self.unit, "Destination tile is reserved for unit!")
            self:waiting()
            self:abort()
            return false
        end
        self:unwaiting()

        self:reserveTile(nextTile)
        self.moveto.x, self.moveto.y = self.unit:getPositionAtTile(nextTile.x, nextTile.y)
        if self.moveto.x ~= self.unit.x then
            self.unit.flipped = self.moveto.x < self.unit.x
        end
        self.moveAnimation = Animation.new{
            duration = self.map:getTileMovingPoints(nextTile) * self.unit.moveduration,
            varlist = self.moveprops,
            varsto = self.moveto,
            object = self.unit,
            callback_update = animation_callback_update
        }
        self.unit:setaction("Walking")
    end
    return false
end

function MoveMission:abort(completed)
    self.moveAnimation = nil
    for i = 0, #self.movesteps do
        self.movesteps[i]=nil
    end
    self.unit:setaction("Idle")
    self:unreserveTile()
    self.completed = completed
end

function MoveMission:isCompleted()
    return self.completed
end

function MoveMission:waiting()
    self.wait = self.wait_time
    self.wait_attempt = self.wait_attempt + 1
    self.wait_time = math.max(MoveMission.WAIT_TIME_MAX, self.wait_time * 2)
end

function MoveMission:unwaiting()
    self.wait = 0
    self.wait_attempt = 0
    self.wait_time = MoveMission.WAIT_TIME_START
end

return MoveMission
