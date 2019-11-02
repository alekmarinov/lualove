if not love then
    love = require "love-portable"
end

local Map = require "gameon.engine.map"
local Unit = require "gameon.engine.unit"

-- love.window.setMode(1920, 1080, { fullscreen = true })

function love.load()
    love.keyboard.setKeyRepeat(true)
    love.graphics.setFont(love.graphics.newFont(10))

    map = Map.load{
        mapfile = "assets/map/island.lua",
        spritesheets = {
            "assets/sprite/barbarian1.json"
        }
    }

    map:spawnunit(Unit.new("barbarian1"), 1, 1)
    map:spawnunit(Unit.new("barbarian1"), 2, 1)
end

function love.update(dt)
    map:update(dt)
end

function love.draw()
    map:draw()
end

function love.wheelmoved(x, y)
    map:wheelmoved(x, y)
end

function love.mousepressed(x, y, b)
    map:mousepressed(x, y, b)
end

function love.mousemoved(x, y, dx, dy, istouch)
    map:mousemoved(x, y, dx, dy, istouch)
end

function love.keypressed(key)
    if map:keypressed(key) then
        return
    end

    if key == "escape" then
        love.event.quit()
    end
end

if love.loop then
    love.loop()
end
