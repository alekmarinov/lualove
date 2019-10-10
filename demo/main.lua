if not love then
    love = require "love-portable"
end

local lfs = require "lfs"
local sti = require "sti"

-- love.window.setMode(800, 600, { fullscreen = true })

local Sprite = {}
Sprite.__index = Sprite

function Sprite.draw(self)
    love.graphics.draw(
        self.image,
        math.floor(self.x),
        math.floor(self.y),
        0,
        1,
        1,
        self.map.tilewidth,
        self.map.tileheight)
end

function Sprite.new(map, image, i, j)
    local x, y = map:convertTileToPixel(i, j)
    map.layers['Ground'].data[i][j].sprites = map.layers['Ground'].data[i][j].sprites or {}
    local o = setmetatable({
        map = map,
        x = x,
        y = y,
        i = i,
        j = j,
        image = love.graphics.newImage(image)
    }, Sprite)
    map.layers['Ground'].data[i][j].sprites[o] = o
    return o
end

function love.load()
    map = sti("map.lua")
    local layer = map:addCustomLayer("Sprites", 2)
    layer.sprites = {
        Sprite.new(map, "archer.png", 3, 3),
        Sprite.new(map, "archer.png", 4, 3),
        Sprite.new(map, "horse_archer.png", 4, 8),
        Sprite.new(map, "horseman.png", 6, 4)
    }

    -- Draw Sprites layer
    layer.draw = function(self)
        for _, sprite in ipairs(self.sprites) do
            sprite:draw()
        end
    end

    map.offset_x = 0 map.offset_y = 0
    map.target_x = 0 map.target_y = 0
    map.start_x = 0 map.start_y = 0

    -- archer = love.graphics.newImage( "archer.png" )
    -- horse_archer = love.graphics.newImage( "horse_archer.png" )
    -- horseman = love.graphics.newImage( "horseman.png" )
    -- archer_x = 0
    -- archer_y = 0
end

function similar(a, b)
    return math.abs(a - b) <= 1
end

function love.update(dt)
    map:update(dt)

    -- smooth map positioning
    local dx = dt * (map.target_x - map.start_x)
    local dy = dt * (map.target_y - map.start_y)
    if (dx < 0 and map.offset_x + dx > map.target_x) or (dx > 0 and map.offset_x + dx < map.target_x) then
        map.offset_x = map.offset_x + dx
    else
        map.offset_x = map.target_x
    end
    if (dy < 0 and map.offset_y + dy > map.target_y) or (dy > 0 and map.offset_y + dy < map.target_y) then
        map.offset_y = map.offset_y + dy
    else
        map.offset_y = map.target_y
    end
end

function love.draw()
    love.graphics.setBackgroundColor(0, 0.75, 0, 1)
    map:draw(map.offset_x, map.offset_y)

    love.graphics.translate(map.offset_x, map.offset_y)
    for j = 1, map.height do
        for i = 1, map.width do
            local tileprops = map:getTileProperties("Ground", i, j)
            local speed = tonumber(tileprops.speed or "-1")
            local x, y = map:convertTileToPixel(i, j)
            -- love.graphics.print(string.format("%d", speed), x - map.tilewidth / 2, y - map.tileheight / 2)
        end
    end

    -- love.graphics.draw(archer,  archer_x - map.offset_x,  archer_y - map.offset_y)
    -- love.graphics.draw(horse_archer,  archer_x - map.offset_x + 100,  archer_y - map.offset_y)
    -- love.graphics.draw(horseman,  archer_x - map.offset_x + 200,  archer_y - map.offset_y)
end

function love.mousepressed(x, y, b)
    if b == 1 then
        -- archer_x = x
        -- archer_y = y
        local tile_x, tile_y = map:convertPixelToTile(x - map.offset_x, y - map.offset_y)
        tile_x, tile_y = math.floor(tile_x+1), math.floor(tile_y+1)
        local tileprops = map:getTileProperties("Ground", tile_x, tile_y)
        print(tileprops and tileprops.speed)

        local sprites = map.layers['Ground'].data[tile_x][tile_y].sprites
        if sprites then
            for i, v in pairs(sprites) do
                print(i, v)
            end
        end
    elseif b == 2 then
        map.start_x = map.offset_x
        map.start_y = map.offset_y
        map.target_x = map.offset_x + love.graphics.getWidth() / 2 - x
        map.target_y = map.offset_y + love.graphics.getHeight() / 2 - y
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end

if love.loop then
    love.loop()
end
