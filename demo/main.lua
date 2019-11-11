if not love then
    love = require "love-portable"
end

local Map = require "gameon.engine.map"
local Rules = require "gameon.rules"
local Game = require "gameon.game"
local Unit = require "gameon.engine.unit"
local Sprite = require "gameon.engine.sprite"
local DrawableText = require "gameon.engine.drawable.text"

-- love.window.setMode(1920, 1080, { fullscreen = true })

function love.load()
    -- local music = love.audio.newSource( 'assets/music/Music 01.ogg', 'stream' )
    -- music:setLooping(true)
    -- music:play()

    love.filesystem.setIdentity("game")
    love.keyboard.setKeyRepeat(true)
    love.graphics.setFont(love.graphics.newFont(10))

    Rules:setInitResources{
        gold = 100,
        wood = 100,
        food = 100
    }

    -- The game needs rules
    Game:setRules(Rules)

    -- Create the blue player as HUMAN
    local currentPlayer = Game:createPlayer{
        type = "HUMAN",
        color = "MAGENTA",
        team = 1
    }
    Game:setCurrentPlayer(currentPlayer)

    -- Create the red player as AI
    local enemyPlayer = Game:createPlayer{
        type = "AI",
        color = "GREEN",
        team = 2
    }

    map = Map.load{
        mapfile = "assets/map/island.lua",
        spritesheets = {
            ["assets/sprite/barbarian1.json"] = { "MAGENTA" },
            ["assets/sprite/barbarian2.json"] = { "GREEN" },
            ["assets/sprite/flag.json"] = { "MAGENTA", "GREEN" }
        }
    }
    -- The game will play on a map
    Game:setMap(map)

    local enemy = Unit.new(enemyPlayer, "barbarian2")
    map:spawnSprite(enemy, 30, 17)

    local px, py = map:convertTileToPixel(35, 22)
    enemy:moveTo(px, py, true)
    px, py = map:convertTileToPixel(28, 18)
    enemy:moveTo(px, py, true)
end

function love.update(dt)
    -- FIXME: game:update(dt)
    map:update(dt)
end

function love.draw()
    -- FIXME: game:draw()
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
