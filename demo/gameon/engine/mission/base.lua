
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

function MissionBase:update(dt)
end

function MissionBase:abort()
end

function MissionBase:onFrameChanged(cycle, prevFrame, nextFrame)
end

function MissionBase:onSelected(selected)
end

return MissionBase
