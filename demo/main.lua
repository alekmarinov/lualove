if not love then
    love = require "love-portable"
end

local Map = require "gameon.engine.map"
local Rules = require "gameon.rules"
local Game = require "gameon.game"
local Unit = require "gameon.engine.unit"

-- love.window.setMode(1920, 1080, { fullscreen = true })

function love.load()
    -- local music = love.audio.newSource( 'assets/music/Music 01.ogg', 'stream' )
    -- music:setLooping(true)
    -- music:play()

    love.keyboard.setKeyRepeat(true)
    love.graphics.setFont(love.graphics.newFont(10))

    map = Map.load{
        mapfile = "assets/map/island.lua",
        spritesheets = {
            "assets/sprite/barbarian1.json",
            "assets/sprite/barbarian2.json"
        }
    }

    Rules:setInitResources{
        gold = 100,
        wood = 100,
        food = 100
    }

    -- The game needs rules
    Game:setRules(Rules)

    -- The game will play on a map
    Game:setMap(map)

    -- The game needs at least one player
    Game:createPlayer()

    local unit = Unit.new(Game.currentPlayer, "barbarian2")
    map:spawnunit(unit, 30, 17)
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

function love.mousereleased(x, y, b)
    map:mousereleased(x, y, b)
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
