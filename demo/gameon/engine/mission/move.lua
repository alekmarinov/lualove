
local Mission = require "gameon.engine.mission"
local Animation = require "gameon.engine.animation"
local Sprite = require "gameon.engine.sprite"

local MissionMove = setmetatable({
    _NAME = "MissionMove",
    moveprops = { "x", "y" },
    WAIT_TIME_START = 1,
    WAIT_TIME_MAX = 2,
    MAX_WAIT_ATTEMPTS = 4
}, Mission)
MissionMove.__index = MissionMove

function MissionMove.animationCallbackUpdate(unit, x, y)
    unit:setPos(x, y)
end

function MissionMove.new(unit, tileto)
    local o = setmetatable(Mission.new{
        unit = unit,
        tileto = tileto,
        map = unit.map,
        movesteps = {},
        moveto = { x = 0, y = 0 },
        wait = 0,
        wait_attempt = 0,
        wait_time = MissionMove.WAIT_TIME_START,
        completed = false
    }, MissionMove)
    return o
end

function MissionMove:reserveTile(tile)
    self:unreserveTile()
    self.reservedTile = tile
    self.map:reserveTileForUnit(self.unit, tile)
end

function MissionMove:unreserveTile()
    if self.reservedTile then
        self.map:unreserveTileFromUnit(self.unit, self.reservedTile)
        self.reservedTile = nil
    end
end

function MissionMove:update(dt)
    if self.completed then
        return true
    end
    -- if self.wait_attempt == MissionMove.MAX_WAIT_ATTEMPTS then
    --     -- waiting attempts to finish the mission exceeded max allowed, aborting the mission
    --     print("waiting attempts to finish the mission exceeded max allowed, aborting the mission")
    --     self:abort(true)
    --     return true
    -- end
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
            -- still moving
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
        if self.wait_time > MissionMove.WAIT_TIME_START then
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
        self.moveto.x, self.moveto.y = self.unit:getPositionAtTile(nextTile)
        -- FIXME: Implement method look toward tile
        if self.moveto.x ~= self.unit.x then
            self.unit.flipped = self.moveto.x < self.unit.x
        end
        self.moveAnimation = Animation.new{
            duration = self.map:getTileMovingPoints(nextTile) * self.unit.moveDuration,
            varlist = self.moveprops,
            varsto = self.moveto,
            object = self.unit,
            callback_update = MissionMove.animationCallbackUpdate
        }
        self.unit:setAction("Walking")
    end
    return false
end

function MissionMove:abort(completed)
    self.moveAnimation = nil
    for i = 0, #self.movesteps do
        self.movesteps[i]=nil
    end
    self.unit:setAction("Idle")
    self:unreserveTile()
    self.completed = completed
    self:showHideFlag(false)
end

function MissionMove:isCompleted()
    return self.completed
end

function MissionMove:waiting()
    self.wait = self.wait_time
    self.wait_attempt = self.wait_attempt + 1
    self.wait_time = math.max(MissionMove.WAIT_TIME_MAX, self.wait_time * 2)
end

function MissionMove:unwaiting()
    self.wait = 0
    self.wait_attempt = 0
    self.wait_time = MissionMove.WAIT_TIME_START
end

function MissionMove:onSelected(selected)
    self:showHideFlag(selected)
end

function MissionMove:showHideFlag(showing)
    if showing then
        if not self.flagSprite then
            self.flagSprite = Sprite.new{
                color = self.unit.color,
                typename = "flag"
            }
            map:spawnSprite(self.flagSprite, self.tileto.x, self.tileto.y)
        end
    else
        if self.flagSprite then
            self.flagSprite:destroy()
            self.flagSprite = nil
        end
    end
end

return MissionMove
