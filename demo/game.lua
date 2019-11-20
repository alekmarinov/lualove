if not love then
    love = require "love-portable"
end

local Cursor = require "gameon.engine.cursor"
local Map = require "gameon.engine.map"
local Rules = require "gameon.rules"
local Game = require "gameon.game"
local Unit = require "gameon.engine.unit"
local Sprite = require "gameon.engine.sprite"
local DrawableText = require "gameon.engine.drawable.text"
local Waiter = require "gameon.engine.waiter"
local Horseman = require "gameon.engine.unit.horseman"
local Spearman = require "gameon.engine.unit.spearman"
local Archer = require "gameon.engine.unit.archer"
local Doctor = require "gameon.engine.unit.doctor"
local Swordsman = require "gameon.engine.unit.swordsman"
local Wizard = require "gameon.engine.unit.wizard"

-- love.window.setMode(1920, 1080, { fullscreen = true })

local time_multiplier = 1

local waiter

function love.load()
    -- local music = love.audio.newSource( 'assets/music/Music 01.ogg', 'stream' )
    -- music:setLooping(true)
    -- music:play()

    Cursor:load("assets/cursor")

    Cursor:setArrow()

    love.filesystem.setIdentity("game")
    love.keyboard.setKeyRepeat(true)
    love.graphics.setFont(love.graphics.newFont(10))

    Rules:setInitResources{
        gold = 100,
        menpower = 10
    }

    -- The game needs rules
    Game:setRules(Rules)

    -- Create the blue player as HUMAN
    local currentPlayer = Game:createPlayer{
        type = "HUMAN",
        color = "BLUE",
        team = 1
    }
    Game:setCurrentPlayer(currentPlayer)

    -- Create the red player as AI
    local enemyPlayer = Game:createPlayer{
        type = "AI",
        color = "RED",
        team = 2
    }

    map = Map.load{
        mapfile = "assets/map/island.lua",
        spritesheets = {
            ["assets/sprite/archer.json"] = { "RED", "BLUE" },
            ["assets/sprite/doctor.json"] = { "RED", "BLUE" },
            ["assets/sprite/horseman.json"] = { "RED", "BLUE" },
            ["assets/sprite/spearman.json"] = { "RED", "BLUE" },
            ["assets/sprite/swordsman.json"] = { "RED", "BLUE" },
            ["assets/sprite/wizard.json"] = { "RED", "BLUE" },
            ["assets/sprite/flag.json"] = { "BLUE", "RED" }
        },
        images = {
            arrow = "assets/image/arrow.png",
            ball = "assets/image/ball.png"
        }
    }
    map.debug = false

    -- The game will play on a map
    Game:setMap(map)

    local point1 = map:getTileAt(41, 17)
    -- local point2 = map:getTileAt(74, 91)
    local point2 = map:getTileAt(23, 8)

    -- local enemy = Swordsman.new{ player = enemyPlayer}
    -- map:spawnSprite(enemy, point1)
    -- local px, py = map:convertTileToPixel(point2.x, point2.y)
    -- enemy:patrolTo(px, py)
    -- local px, py = map:convertTileToPixel(point1.x, point1.y)
    -- enemy:patrolTo(px, py)

    waiter = Waiter.new{
        duration = 5,
        callback_finished = function(self)
            self:reset()

            local sprites = {Doctor, Horseman, Archer, Spearman, Swordsman, Wizard}
            local idx = math.random(#sprites)
            local sprite = sprites[idx]
        
            -- spawn friend
            local friend = sprite.new{ player = currentPlayer }
            map:spawnSprite(friend, point1)
            local px, py = map:convertTileToPixel(point2.x, point2.y)
            friend:patrolTo(px, py)
            px, py = map:convertTileToPixel(point1.x, point1.y)
            friend:patrolTo(px, py)

            -- spawn enemy
            local enemy = sprite.new{ player = enemyPlayer}
            map:spawnSprite(enemy, point2)
            local px, py = map:convertTileToPixel(point1.x, point1.y)
            enemy:patrolTo(px, py)
            px, py = map:convertTileToPixel(point2.x, point2.y)
            enemy:patrolTo(px, py)
        end
    }
end

function love.update(dt)
    -- FIXME: game:update(dt)
    map:update(dt * time_multiplier)
    if waiter then
        waiter:update(dt * time_multiplier)
    end
end

function love.draw()
    -- FIXME: game:draw()
    map:draw()
    love.graphics.print(string.format('fps: %.1f, mem: %d kb', love.timer.getFPS(), collectgarbage('count')), 10, 10)
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

    if key == "kp+" then
        time_multiplier = time_multiplier * 2
    elseif key == "kp-" then
        time_multiplier = time_multiplier / 2
    elseif key == "escape" then
        love.event.quit()
    end
end

if love.loop then
    love.loop()
end
