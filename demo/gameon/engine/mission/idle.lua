
local thispackage = (...):match("(.-)[^%.]+$")
local MissionBase = require (thispackage..".base")
local Waiter = require "gameon.engine.waiter"

local MissionIdle = setmetatable({
    _NAME = "MissionIdle",
    WAIT_TIME = 0.1
}, MissionBase)
MissionIdle.__index = MissionIdle

-- idle state classes
local State = {
    _NAME = "State"
}
State.__index = State

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

-- StateFight
function StateFight.new(options)
    return setmetatable(State.new(options), StateFight)
end

function StateFight:next()
    if self.unit.map then
        local enemy = self.unit.map:enemiesInRange(self.unit)()
        if enemy then
            if self.unit.action ~= "Attacking" then
                self.unit:attackUnit(enemy)
            end
        else
            self.unit:setAction("Idle")
        end
    end
    self.mission:wait(MissionIdle.WAIT_TIME, function()
        self.mission.state:next()
    end)
end

function MissionIdle.new(options)
    local o = setmetatable(MissionBase.new(options), MissionIdle)
    o:setState(StateFight)
    o.state:next()
    return o
end

return MissionIdle
