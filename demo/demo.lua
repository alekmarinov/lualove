local love = require "love-portable"

function love.load()
    image = love.graphics.newImage("love-ball.png")
end

function love.draw()
    love.graphics.draw(image, 400, 300)
end

love.loop()
