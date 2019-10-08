if not love then
    love = require "love-portable"
end

local lfs = require "lfs"
local sti = require "sti"

love.window.setMode(800, 600, {
    fullscreen = false
})

function love.load()
    
    map = sti("map.lua")
end

function love.update(dt)
    map:update(dt)
end

local tx, ty = 0, 0
function love.draw()
    love.graphics.setBackgroundColor(0, 0.75, 0, 1)
    map:draw(tx, ty)
    tx = tx - 1
    ty = ty - 1
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end

if love.loop then
    love.loop()
end
