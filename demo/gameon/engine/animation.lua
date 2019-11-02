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
        initials = {}
    }, Animation)

    for _, varname in ipairs(o.varlist) do
        o.initials[varname] = o.object[varname]
    end

    return o
end

function Animation:interpolation(dt)
    local finished = true
    for _, varname in ipairs(self.varlist) do
        local dx = dt * (self.varsto[varname] - self.initials[varname]) / self.duration
        if (dx < 0 and self.object[varname] + dx > self.varsto[varname]) or (dx > 0 and self.object[varname] + dx < self.varsto[varname]) then
            self.object[varname] = self.object[varname] + dx
            finished = false
        else
            self.object[varname] = self.varsto[varname]
        end
    end
    if finished and self.callback_finished then
        self.callback_finished()
    end
    return finished
end

function Animation:update(dt)
    return self[self.animtype](self, dt)
end

return Animation
