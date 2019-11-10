--- Animation primitives
-- @module gameon.engine.Animation


local Animation = {
    INTERPOLATION = "interpolation"
}
Animation.__index = Animation

function Animation.new(params)
    params.duration = params.duration or 1
    params.animtype = params.animtype or Animation.INTERPOLATION
    local o = setmetatable({
        animtype = params.animtype,
        duration = params.duration,
        varlist = params.varlist,
        varsto = params.varsto,
        object = params.object,
        callback_finished = params.callback_finished,
        callback_update = params.callback_update,
        initials = {}
    }, Animation)

    for _, varname in ipairs(o.varlist) do
        o.initials[varname] = o.object[varname]
    end
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
    self.callback_update(unpack(varvalues))
    if finished and self.callback_finished then
        self.callback_finished()
    end
    return finished
end

function Animation:update(dt)
    return self[self.animtype](self, dt)
end

return Animation
