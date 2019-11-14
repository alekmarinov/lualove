local pltablex = require "pl.tablex"
local thispackage = (...):match("(.-)[^%.]+$")
local MissionBase = require (thispackage..".base")
local Animation = require "gameon.engine.animation"
local Waiter = require "gameon.engine.waiter"
local Sprite = require "gameon.engine.sprite"
local DrawableText = require "gameon.engine.drawable.text"
local PLAYER_COLOR = require "gameon.engine.enums".PLAYER_COLOR

local MissionMove = setmetatable({
    _NAME = "MissionMove",
    moveprops = { "x", "y" },
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
    _NAME = "StateMove"
}, State)
StateMove.__index = StateMove

local StateWait = setmetatable({
    _NAME = "StateWait"
}, State)
StateWait.__index = StateWait

local StateFight = setmetatable({
    _NAME = "StateFight"
}, State)
StateFight.__index = StateFight

-- State
function State:next()
end
function State:cancel()
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
    return o
end
function StateMove:next()
    if self.mission.tileto and self.mission.tileto == self.unit.tile then
        if #self.mission.tiles <= 1 then
            self.unit:stop()
            return
        else
            self.mission.tileIdx = self.mission.tileIdx + 1
            if self.mission.tileIdx > #self.mission.tiles then
                self.mission.tileIdx = 1
            end
            self.mission.tileto = self.mission.tiles[self.mission.tileIdx]
        end
        self.mission:setState(StateBlock)
        self.mission.state:next()
        return 
    end

    if #self.path == 0 or not self.mission:checkNoUnitsOnTile(self.path[1]) then
        self.mission:setState(StateBlock)
        self.mission.state:next()
        return 
    end

    if self.map:enemiesInRange(self.unit, 1)() then
        self.mission:setState(StateFight)
        self.mission.state:next()
        return
    end

    self.mission:moveToTile(self.path[1], function()
        table.remove(self.path, 1)
        self.mission.state:next()
    end)
end

-- StateBlock
function StateBlock.new(options)
    return setmetatable(State.new(options), StateBlock)
end
function StateBlock:next()
    if self.map:enemiesInRange(self.unit, 1)() then
        self.mission:setState(StateFight)
        self.mission.state:next()
        return
    end

    local path = self.mission:findPath(MissionMove.checkNoUnitsOnTile)
    if #path > 0 then
        self.mission:setState(StateMove, {path = path})
        self.mission.state:next()
        return 
    end

    -- wait until unblocked
    self.mission:setState(StateWait, { time = MissionMove.WAIT_TIME })
    self.mission.state:next()
end

-- StateFight
function StateFight.new(options)
    return setmetatable(State.new(options), StateFight)
end

function StateFight:next()
    local enemy = self.map:enemiesInRange(self.unit, 1)()
    if not enemy then
        self.mission:setState(StateBlock)
        self.mission.state:next()
    else
        if self.unit.action ~= "Attacking" then
            self.unit:attackUnit(enemy)
        end
        self.mission:wait(MissionMove.WAIT_TIME, function()
            self.mission.state:next()
        end)
    end
end

function MissionMove.animationCallbackUpdate(unit, x, y)
    unit:setPos(x, y)
end

function MissionMove.new(options)
    local o = setmetatable(MissionBase.new(options), MissionMove)
    assert(o.tileto or o.followUnit, ".tileto or .followUnit is mandatory")
    o.moveto = { x = nil, y = nil }
    o.tiles = { o.tileto }
    o.tileIdx = 1
    o.flagSprites = {}
    o.flagDrawables = {}
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
    if self.state then
        if self.map.debug then
            self.map:addFloatingTextAtTile(self.unit.tile, state._NAME, PLAYER_COLOR[self.color])
        end
        self.state:cancel()
    end
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

function MissionMove:moveToTile(tile, callback)
    self.unit:lookAtTile(tile)
    self:reserveTile(tile)
    self.moveto.x, self.moveto.y = self.unit:getPositionAtTile(tile)
    if self.unit.action ~= "Walking" then
        self.unit:setAction("Walking")
    end
    self.worker = Animation.new{
        duration = self.map:getTileMovingPoints(tile) * self.unit.speed,
        fields = self.moveprops,
        varsto = self.moveto,
        object = self.unit,
        callback_update = MissionMove.animationCallbackUpdate,
        callback_finished = function()
            self.worker = nil
            self:unreserveTile()
            callback()
        end
    }
end

function MissionMove:wait(time, callback)
    self.worker = Waiter.new{
        duration = MissionMove.WAIT_TIME,
        callback_finished = function()
            self.worker = nil
            callback()
        end
    }
end

function MissionMove:checkNoStandingUnitsOnTile(tile)
    if self.map:isTileReserved(tile) then
        return false
    end
    local unitAtTile = self.map:getUnitAtTile(tile)
    if not unitAtTile then
        return true
    end
    return unitAtTile.mission._NAME == "MissionMove"
end

function MissionMove:checkNoUnitsOnTile(tile)
    return not self.map:getUnitAtTile(tile) and not self.map:isTileReserved(tile)
end

function MissionMove:checkNoUnitsOnTileExceptGroup(tile)
    if self.map:isTileReserved(tile) then
        return false
    end
    local unitAtTile = self.map:getUnitAtTile(tile)
    if not unitAtTile then
        return true
    end
    return self:isUnitInGroup(unitAtTile)
end

function MissionMove:findPath(callback_walkable, isfast)
    return self.map:findPath{
        unit = self.unit,
        start = self.unit.tile,
        stop = self.tileto or self.followUnit.tile,
        isfast = false,
        callback_is_tile_walkable = function(tile)
            return callback_walkable(self, tile)
        end
    }
end

function MissionMove:abort()
    self.worker = nil
    self:setState(StateStop)
    self:unreserveTile()
    self:showHideFlags(false)
end

function MissionMove:onSelected(selected)
    self:showHideFlags(selected)
end

function MissionMove:togglePatrolTile(tile)
    self:showHideFlags(false)
    local idx = pltablex.find(self.tiles, tile)
    if idx then
        if idx == self.tileIdx then
            self.tileIdx = self.tileIdx - 1
            table.remove(self.tiles, idx)

            if self.tileIdx == 0 then
                self.tileIdx = #self.tiles
            end

            self.tileto = self.tiles[self.tileIdx]
            if not self.tileto then
                self:setState(StateStop)
            else
                self:setState(StateBlock)
            end
            self.state:next()
        else
            table.remove(self.tiles, idx)
        end
    else
        table.insert(self.tiles, tile)
    end
    if self.unit:isSelected() then
        self:showHideFlags(true)
    end
end

function MissionMove:showHideFlags(showing)
    if showing then
        if #self.flagSprites == 0 then
            for i, tile in ipairs(self.tiles) do
                local flag = Sprite.new{
                    color = self.unit.color,
                    typename = "flag"
                }
                self.unit.map:spawnSprite(flag, tile)
                table.insert(self.flagSprites, flag)

                if #self.tiles > 1 then
                    local x, y = self.unit.map:convertTileToPixel(tile.x, tile.y)
                    local text = DrawableText.new{
                        text = tostring(i),
                        x = x,
                        y = y
                    }
                    self.unit.map:addDrawable(text)
                    table.insert(self.flagDrawables, text)
                end
            end
        end
    else
        if #self.flagSprites > 0 then
            for i = #self.flagSprites, 1, -1 do
                local flag = self.flagSprites[i]
                flag:destroy()
                self.flagSprites[i] = nil
            end
            for i = #self.flagDrawables, 1, -1 do
                local text = self.flagDrawables[i]
                self.unit.map:removeDrawable(text)
                self.flagDrawables[i] = nil
            end
        end
    end
end

return MissionMove
