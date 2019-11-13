
local thispackage = (...):match("(.-)[^%.]+$")
local MissionBase = require (thispackage..".base")
local Animation = require "gameon.engine.animation"
local Waiter = require "gameon.engine.waiter"
local Sprite = require "gameon.engine.sprite"

local MissionMove = setmetatable({
    _NAME = "MissionMove",
    WAIT_TIME = 1
}, MissionBase)
MissionMove.__index = MissionMove

-- moving state classes
local State = {
    _NAME = "State"
}
State.__index = State

local StateBlock = setmetatable({
    _NAME = "StateBlock",
}, State)
StateBlock.__index = StateBlock

local StateStop = setmetatable({
    _NAME = "StateStop"
}, State)
StateStop.__index = StateStop

local StateMove = setmetatable({
    _NAME = "StateMove",
    moveprops = { "x", "y" }
}, State)
StateMove.__index = StateMove

local StateWait = setmetatable({
    _NAME = "StateWait"
}, State)
StateWait.__index = StateWait

-- State
function State:next()
end
function State.new(options)
    return setmetatable(options, State)
end

-- StateStop
function StateStop.new(options)
    return setmetatable(State.new(options), StateStop)
end
function StateStop:next()
    self.unit:stop()
end

-- StateWait
function StateWait.new(options)
    return setmetatable(State.new(options), StateWait)
end
function StateWait:next()
    self.unit:setAction("Idle")
    self.mission.worker = Waiter.new{
        duration = self.time,
        callback_finished = function()
            self.mission.worker = nil
            self.mission.state:next()
        end
    }
    self.mission:setState(StateBlock)
end

-- StateMove
function StateMove.new(options)
    local o = setmetatable(State.new(options), StateMove)
    assert(o.path, "path is mandatory for StateMove")
    o.moveto = { x = nil, y = nil }
    return o
end
function StateMove:next()
    if self.mission.tileto and self.mission.tileto == self.unit.tile then
        self.unit:stop()
        return 
    end

    if self.mission.followUnit and self.unit:isNearBy(self.mission.followUnit) then
        self.mission:setState(StateWait, { time = MissionMove.WAIT_TIME })
        self.mission.state:next()
        return 
    end

    if #self.path == 0 then
        self.mission:setState(StateBlock)
        self.mission.state:next()
        return 
    end
    local tile = self.path[1]
    if not self.mission:checkNoUnitsOnTile(tile) then
        self.mission:setState(StateBlock)
        self.mission.state:next()
        return 
    end

    self.unit:lookAtTile(tile)
    self.mission:reserveTile(tile)
    self.moveto.x, self.moveto.y = self.unit:getPositionAtTile(tile)
    if self.unit.action ~= "Walking" then
        self.unit:setAction("Walking")
    end
    self.mission.worker = Animation.new{
        duration = self.map:getTileMovingPoints(tile) * self.unit.speed,
        fields = self.moveprops,
        varsto = self.moveto,
        object = self.unit,
        callback_update = MissionMove.animationCallbackUpdate,
        callback_finished = function()
            self.mission.worker = nil
            self.mission:unreserveTile()
            table.remove(self.path, 1)
            self.mission.state:next()
        end
    }
end

-- StateBlock
function StateBlock.new(options)
    return setmetatable(State.new(options), StateBlock)
end
function StateBlock:next()
    local path = self.mission:findPath(MissionMove.checkNoUnitsOnTile)
    if #path > 0 then
        self.mission:setState(StateMove, {path = path})
        self.mission.state:next()
        return 
    end
    if self.mission.followUnit then
        -- wait until move to follow
        self.mission:setState(StateWait, { time = MissionMove.WAIT_TIME })
        self.mission.state:next()
        return 
    else
        -- no path to target
        self.unit:stop()
    end
end

function MissionMove.animationCallbackUpdate(unit, x, y)
    unit:setPos(x, y)
end

function MissionMove.new(options)
    local o = setmetatable(MissionBase.new(options), MissionMove)
    assert(o.tileto or o.followUnit, ".tileto or .followUnit is mandatory")
    o:setState(StateBlock)
    o.state:next()
    return o
end

function MissionMove:setState(stateClass, options)
    options = options or {}
    options.mission = self
    options.unit = self.unit
    options.map = self.map
    local state = stateClass.new(options)
    print("MissionMove:setState: "..state._NAME.." -> "..state._NAME)
    self.state = state
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
    if self.worker then
        self.worker:update(dt)
    end
end

function MissionMove:checkNoUnitsOnTile(tile)
    return not self.map:getUnitAtTile(tile) and not self.map:isTileReserved(tile)
end

function MissionMove:findPath(callback_walkable, isfast)
    return self.map:findPath{
        unit = self.unit,
        start = self.unit.tile,
        stop = self.tileto or self.followUnit.tile,
        isfast = isfast,
        callback_is_tile_walkable = function(tile)
            return callback_walkable(self, tile)
        end
    }
end

function MissionMove:findPathFast(callback_walkable)
    return self:findPath(callback_walkable, true)
end

function MissionMove:abort()
    self.worker = nil
    self:setState(StateStop)
    self:unreserveTile()
    self:showHideFlag(false)
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
            local tile = self.tileto
            if not tile then
                tile = self.followUnit.tile
            end
            map:spawnSprite(self.flagSprite, tile.x, tile.y)
        end
    else
        if self.flagSprite then
            self.flagSprite:destroy()
            self.flagSprite = nil
        end
    end
end

return MissionMove
