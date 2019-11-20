local Drawable = require "gameon.engine.drawable"

local DrawableText = setmetatable({
    FONT_SIZE = 10,
    COLOR = { 1, 1, 1, 1 },
    transparency = 1
}, Drawable)
DrawableText.__index = DrawableText

function DrawableText.new(options)
    local o = setmetatable(options or {}, DrawableText)
    o.size = o.size or DrawableText.FONT_SIZE
    local font = love.graphics.newFont(o.size)
    o.textDrawable = love.graphics.newText(font, o.text)
    o.color = o.color or DrawableText.COLOR
    return o
end

function DrawableText:draw()
    love.graphics.setColor(self.color)
    love.graphics.draw(self.textDrawable, self.x - self.textDrawable:getWidth() / 2, self.y - self.textDrawable:getHeight() / 2)
    love.graphics.setColor(1, 1, 1, 1)
end

return DrawableText
