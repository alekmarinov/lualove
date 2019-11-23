local thispackage = (...):match("(.-)[^%.]+$")
local StructureBase = require (thispackage..".base")

local Camp = setmetatable({
    _NAME = "Camp"
}, StructureBase)
Camp.__index = Camp

function Camp.new(options)
    return setmetatable(StructureBase.new(options), Camp)
end

return Camp
