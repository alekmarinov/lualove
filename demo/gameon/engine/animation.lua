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
    o.varsfrom = {}
    for _, field in ipairs(o.fields) do
        o.varsfrom[field] = o.object[field]
    end
    o.loops = 0
    return o
end

function Animation:interpolation(dt)
    local finished = true
    local varvalues = {}
    for _, field in ipairs(self.fields) do
        local dx = dt * (self.varsto[field] - self.varsfrom[field]) / self.duration
        if (dx < 0 and self.object[field] + dx > self.varsto[field]) or (dx > 0 and self.object[field] + dx < self.varsto[field]) then
            table.insert(varvalues, self.object[field] + dx)
            finished = false
        else
            table.insert(varvalues, self.varsto[field])
        end
    end
    if self.callback_update then
        self.callback_update(self, unpack(varvalues))
    else
        for i, field in ipairs(self.fields) do
            self.object[field] = varvalues[i]
        end
    end
    if finished and self.reversed and self.loops == 0 then
        self.loops = self.loops + 1
        finished = false
        -- swap varsfrom with varsto
        for _, field in ipairs(self.fields) do
            self.varsfrom[field], self.varsto[field] = self.varsto[field], self.varsfrom[field]
        end
    end

    if finished and self.callback_finished then
        self.callback_finished(self)
    end
    return finished
end

function Animation:update(dt)
    return self[self.animtype](self, dt)
end

return Animation
