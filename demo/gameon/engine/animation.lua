--- Animation primitives
-- @module gameon.engine.Animation


local Animation = {
    INTERPOLATION = "interpolation"
}
Animation.__index = Animation

function Animation.new(options)
    local o = setmetatable(options or {}, Animation)
    assert(o.duration, "duration attribute is mandatory")
    o.animtype = o.animtype or Animation.INTERPOLATION
    o.initials = {}
    for _, varname in ipairs(o.varlist) do
        o.initials[varname] = o.object[varname]
    end
    o.loops = 0
    return o
end

function Animation:interpolation(dt)
    local finished = true
    local varvalues = {}
    for _, varname in ipairs(self.varlist) do
        local dx = dt * (self.varsto[varname] - self.initials[varname]) / self.duration
        if (dx < 0 and self.object[varname] + dx > self.varsto[varname]) or (dx > 0 and self.object[varname] + dx < self.varsto[varname]) then
            table.insert(varvalues, self.object[varname] + dx)
            finished = false
        else
            table.insert(varvalues, self.varsto[varname])
        end
    end
    self.callback_update(self.object, unpack(varvalues))
    if finished and self.reversed and self.loops == 0 then
        self.loops = self.loops + 1
        finished = false
        -- swap initials with varsto
        for _, varname in ipairs(self.varlist) do
            self.initials[varname], self.varsto[varname] = self.varsto[varname], self.initials[varname]
        end
    end

    if finished and self.callback_finished then
        self.callback_finished(self.object)
    end
    return finished
end

function Animation:update(dt)
    return self[self.animtype](self, dt)
end

return Animation
