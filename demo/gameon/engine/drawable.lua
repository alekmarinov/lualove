local Drawable = {}
Drawable.__index = Drawable

function Drawable:update(dt)
    if self.animation then
        self.animation:update(dt)
    end
end

function Drawable:draw()
end

return Drawable
