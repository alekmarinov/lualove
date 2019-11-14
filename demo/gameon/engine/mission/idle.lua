
local thispackage = (...):match("(.-)[^%.]+$")
local MissionBase = require (thispackage..".base")

local MissionIdle = setmetatable({
    _NAME = "MissionIdle"
}, MissionBase)
MissionIdle.__index = MissionIdle

function MissionIdle.new(options)
    return setmetatable(MissionBase.new(options), MissionIdle)
end

function MissionIdle:update(dt)
    -- stay idle
end

return MissionIdle
