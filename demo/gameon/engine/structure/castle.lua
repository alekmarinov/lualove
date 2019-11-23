local thispackage = (...):match("(.-)[^%.]+$")
local StructureBase = require (thispackage..".base")

local Castle = setmetatable({
    _NAME = "Castle",
    BIRTH_RATE = 10,
    building = {
        archer = true,
        spearman = true,
        swordsman = true
    }
}, StructureBase)
Castle.__index = Castle

function Castle.new(options)
    return setmetatable(StructureBase.new(options), Castle)
end

return Castle
