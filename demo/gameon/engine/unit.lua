--- Unit base module for all units in the game
-- @module gameon.engine.Unit

local thispackage = (...):match("(.-)[^%.]+$")

local Sprite = require (thispackage..".sprite")
local Animation = require (thispackage..".animation")

--- Base Unit table
-- @table Unit
local Unit = setmetatable({
    moveduration = 2
}, Sprite)
Unit.__index = Unit

function Unit.new(typename)
    local o = setmetatable({
        typename = typename,
        action = "Idle"
    }, Unit)
    return o
end

function Unit:moveto(x, y)
    self:setaction("Walking")
    self:setanimation(Animation.new{
        duration = self.moveduration, 
        varlist = { "x", "y" },
        varsto = { x = x, y = y },
        object = self,
        callback_finished = function ()
            self:setaction("Idle")
        end
    })
    self.flipped = x < self.x
end

return Unit
