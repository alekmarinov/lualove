local Drawable = require "gameon.engine.drawable"

local DrawableImage = setmetatable({
    transparency = 1
}, Drawable)
DrawableImage.__index = DrawableImage

function DrawableImage.new(options)
    assert(options.image, "image option is mandatory")
    return setmetatable(options, DrawableImage)
end

function DrawableImage:draw()
    love.graphics.push()
    love.graphics.translate( self.x, self.y )
    if self.rotation then
        love.graphics.rotate(self.rotation)
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.image, -self.image:getWidth() / 2, -self.image:getHeight() / 2)
    love.graphics.pop()
end

return DrawableImage
