local thispackage = (...):match("(.-)[^%.]+$")
local StructureBase = require (thispackage..".base")

local Castle = setmetatable({
    _NAME = "Castle"
}, StructureBase)
Castle.__index = Castle

function Castle.new(options)
    return setmetatable(StructureBase.new(options), Castle)
end

return Castle
