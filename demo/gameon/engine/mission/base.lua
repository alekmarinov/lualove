local PLAYER_COLOR = require "gameon.engine.enums".PLAYER_COLOR
local Waiter = require "gameon.engine.waiter"

local MissionBase = {
    _NAME = "MissionBase"
}
MissionBase.__index = MissionBase

function MissionBase.new(o)
    o = o or {}
    assert(o.unit, ".unit is mandatory")
    o.map = o.unit.map
    return setmetatable(o, MissionBase)
end

function MissionBase:setState(stateClass, options)
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

function MissionBase:wait(time, callback)
    self.worker = Waiter.new{
        duration = time,
        callback_finished = function()
            self.worker = nil
            callback()
        end
    }
end

function MissionBase:update(dt)
    if self.worker then
        self.worker:update(dt)
    end
end

function MissionBase:abort()
    self.worker = nil
end

function MissionBase:onFrameChanged(cycle, prevFrame, nextFrame)
end

function MissionBase:onSelected(selected)
end

return MissionBase
