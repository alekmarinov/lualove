if not love then
    love = require "love-portable"
end

local Cursor = require "gameon.engine.cursor"
local Map = require "gameon.engine.map"
local Rules = require "gameon.rules"
local Game = require "gameon.game"
local Unit = require "gameon.engine.unit"
local Barbarian = require "gameon.engine.unit.barbarian"
local Sprite = require "gameon.engine.sprite"
local DrawableText = require "gameon.engine.drawable.text"
local Waiter = require "gameon.engine.waiter"

-- love.window.setMode(1920, 1080, { fullscreen = true })

local time_multiplier = 1

local waiter

function love.load()
    local music = love.audio.newSource( 'assets/music/Music 01.ogg', 'stream' )
    music:setLooping(true)
    music:play()

    Cursor:load("assets/cursor")

    Cursor:setArrow()

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
            ["assets/sprite/barbarian2.json"] = { "BLUE" },
            ["assets/sprite/barbarian1.json"] = { "RED" },
            ["assets/sprite/flag.json"] = { "BLUE", "RED" }
        }
    }
    map.debug = false

    -- The game will play on a map
    Game:setMap(map)

    local patrol_from = map:getTileAt(30, 14)
    local patrol_to = map:getTileAt(29, 31)
    waiter = Waiter.new{
        duration = 5,
        callback_finished = function(_, self)
            self:reset()
        
            -- spawn enemy
            local enemy = Barbarian.new(currentPlayer, "barbarian2")
            map:spawnSprite(enemy, patrol_from)
            local px, py = map:convertTileToPixel(patrol_to.x, patrol_to.y)
            enemy:patrolTo(px, py)
            px, py = map:convertTileToPixel(patrol_from.x, patrol_from.y)
            enemy:patrolTo(px, py)

            -- spawn friend
            local friend = Barbarian.new(enemyPlayer, "barbarian1")
            map:spawnSprite(friend, patrol_to)
            local px, py = map:convertTileToPixel(patrol_from.x, patrol_from.y)
            friend:patrolTo(px, py)
            px, py = map:convertTileToPixel(patrol_to.x, patrol_to.y)
            friend:patrolTo(px, py)
        end
    }
end

function love.update(dt)
    -- FIXME: game:update(dt)
    map:update(dt * time_multiplier)
    waiter:update(dt * time_multiplier)
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
