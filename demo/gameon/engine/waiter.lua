-- @module gameon.engine.Waiter

local Waiter = {
}
Waiter.__index = Waiter

function Waiter.new(options)
    local o = setmetatable(options or {}, Waiter)
    assert(o.duration, "duration attribute is mandatory")
    o:reset()
    return o
end

function Waiter:reset()
    self.timer = self.duration
end

function Waiter:update(dt)
    if self.timer - dt > 0 then
        self.timer = self.timer - dt
        return false
    else
        self.timer = 0
        self.callback_finished(self)
        return true
    end
end

return Waiter
