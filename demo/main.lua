if not love then
    love = require "love-portable"
end

local lfs = require "lfs"
local sti = require "sti"
local json = require "dkjson"
local plpath = require "pl.path"

-- love.window.setMode(1920, 1080, { fullscreen = true })

local zoomstep = 0.1

local Game = {
    spritesheets = {},
    zoom = 1
}

local Sprite = {}
Sprite.__index = Sprite

function Sprite:update(dt)
    local action_frames_count = #Game.spritesheets[self.name].frames[self.action]
    local action_duration = Game.spritesheets[self.name].frames[self.action].duration
    self.current_time = self.current_time + dt
    if self.current_time >= action_duration then
        self.current_time = self.current_time - action_duration
    end
    local frame_index = math.floor(self.current_time / action_duration * action_frames_count) % action_frames_count + 1
    if self.frame_index ~= frame_index then
        self.frame_index = frame_index
        self.spriteBatch:updateSprite(self)
    end
end

local SpriteBatch = {
    sprites = {}
}
SpriteBatch.__index = SpriteBatch

function SpriteBatch:update(dt)
    for i = 1, #self.sprites do
        local sprite = self.sprites[i]
        if sprite then
            sprite:update(dt)
        end
    end
end

function SpriteBatch:updateSprite(sprite)
    local quad = self.frames[sprite.action][sprite.frame_index]
    self.batch:set(sprite.sprite_index, quad, sprite.x, sprite.y, 0, sprite.flipped and -1 or 1, 1)
end

function SpriteBatch:draw()
    love.graphics.draw(self.batch)
end

function SpriteBatch:deleteSprite(sprite)
    self.sprites[sprite.sprite_index] = nil
    self.batch:set(sprite.sprite_index, 0, 0, 0, 0, 0)
end

function SpriteBatch:createSprite(action, x, y, flipped)
    -- searching a gap
    local sprite_index = #self.sprites + 1
    for i = 1, #self.sprites do
        if not self.sprites[i] then
            sprite_index = i
        end
    end
    local sprite = setmetatable({
        name = self.name,
        action = action,
        x = x,
        y = y,
        flipped = flipped,
        frame_index = 1,
        current_time = 0,
        sprite_index = sprite_index
    }, Sprite)
    local quad = self.frames[sprite.action][sprite.frame_index]
    local params = {quad, sprite.x, sprite.y, 0, sprite.flipped and -1 or 1, 1}
    if sprite_index > #self.sprites then
        self.batch:add(unpack(params))
    else
        self.batch:set(sprite_index, unpack(params))
    end
    self.sprites[sprite_index] = sprite
    sprite.spriteBatch = self
    return sprite
end

function SpriteBatch.load(jsonfile)
    local fd, err = io.open(jsonfile)
    if not fd then
        return nil, err
    end
    local jsonstr = fd:read("*all")
    fd:close()

    local o = setmetatable({
        frames = {}
    }, SpriteBatch)

    local info = json.decode(jsonstr)
    o.name = plpath.splitext(plpath.basename(jsonfile))
    local image = love.graphics.newImage(plpath.join(plpath.dirname(jsonfile), info.meta.image))

    for framename, frameinfo in pairs(info.frames) do
        local _, action_name_index = plpath.splitpath(framename)
        local frame_index = 1 + tonumber(action_name_index:sub(-3))
        local action_name = action_name_index:sub(1, -5)
        o.frames[action_name] = o.frames[action_name] or {}
        o.frames[action_name].duration = 1
        o.frames[action_name][frame_index] = love.graphics.newQuad(
            frameinfo.frame.x, frameinfo.frame.y,
            frameinfo.frame.w, frameinfo.frame.h, image:getDimensions())
    end
    o.batch = love.graphics.newSpriteBatch(image)
    return o
end

local mouse_x, mouse_y = 0, 0
local mhex_x = 1
local mhex_y = 1
local sprite
local showgrid = false

local function drawhex(cx, cy, size)
    local lastX = nil
	local lastY = nil
	for i = 0, 6 do
		local angle = 2 * math.pi / 6 * i
		local x = cx + size * math.cos(angle)
		local y = cy + size * math.sin(angle)
		if i > 0 then
			love.graphics.line(lastX, lastY, x, y)
		end
		lastX = x
		lastY = y
	end
end

function love.load()
    love.keyboard.setKeyRepeat(true)
    love.graphics.setFont(love.graphics.newFont(10))

    map = sti("assets/map/island.lua")
    local layer = map:addCustomLayer("Sprites", 2)
    local spriteSheet = SpriteBatch.load("assets/sprite/barbarian1.json")
    Game.spritesheets[spriteSheet.name] = spriteSheet

    layer.sprites = {}

    local actions = {
        "Idle",
        "Attacking",
        "Jump Loop",
        "Jump Start",
        "Walking",
        "Dying",
        "Hurt",
        "Idle Blink",
        "Taunt"
    }
    for i = 1, 1 do
        for j = 1, 1 do
            local action = actions[1 + ((j-1) * 33 + i-1) % #actions]
            local x, y = map:convertTileToPixel(i, j)
            local flipped = false -- idx % 2 == 1
            local _sprite = spriteSheet:createSprite(action, x - 21/2, y - 17/2, flipped)
            if not sprite then
                sprite = _sprite
            end
        end
    end

    -- Draw Sprites layer
    layer.draw = function(self)
        -- draw sprites
        for _, spritesheet in pairs(Game.spritesheets) do
            spritesheet:draw()
        end

        if showgrid then
            -- draw grid
            for i = 1, 33 do
                for j = 1, 33 do
                    local px, py = map:convertTileToPixel(i, j)
                    love.graphics.setColor(0, 1, 0, 1)
                    drawhex(px, py, map.hexsidelength)
                    love.graphics.setColor(0, 0, 0, 1)
                    love.graphics.printf(string.format("%d, %d", i, j), px-map.hexsidelength, py-map.hexsidelength/2, 2*map.hexsidelength, "center")
                end
            end
        end

        -- draw rectangle around the hero
        if mhex_x and mhex_y then
            px, py = map:convertTileToPixel(mhex_x, mhex_y)
            love.graphics.setColor(1, 0, 0, 1)
            drawhex(px, py, map.hexsidelength)
        end

        -- draw hexagon under the cursor
        local tx, ty = map:convertPixelToTile(-map.offset_x + mouse_x / Game.zoom, -map.offset_y + mouse_y / Game.zoom)
        px, py = map:convertTileToPixel(tx, ty)
        love.graphics.setColor(1, 1, 1, 1)
        drawhex(px, py, map.hexsidelength)
        love.graphics.printf(string.format("%d %d", tx, ty), px - map.hexsidelength, py - map.hexsidelength/2, 2*map.hexsidelength, "center")
    end

    map.offset_x = 0 map.offset_y = 0
    map.target_x = 0 map.target_y = 0
    map.start_x = 0 map.start_y = 0
end

function similar(a, b)
    return math.abs(a - b) <= 1
end

function love.update(dt)
    map:update(dt)

    -- update sprite animations
    for _, spritesheet in pairs(Game.spritesheets) do
        spritesheet:update(dt)
    end

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
    love.graphics.setBackgroundColor(0.25, 0.25, 0.75, 1)
    map:draw(map.offset_x, map.offset_y, Game.zoom, Game.zoom)
end

function love.wheelmoved(x, y)
    Game.zoom = Game.zoom + y * zoomstep
    if Game.zoom < 1 then
        Game.zoom = 1
    elseif Game.zoom > 2 then
        Game.zoom = 2
    end
end

function love.mousepressed(x, y, b)
    if b == 1 then
        local tile_x, tile_y = map:convertPixelToTile(x - map.offset_x, y - map.offset_y)
        tile_x, tile_y = math.floor(tile_x+1), math.floor(tile_y+1)
        print(tile_x, tile_y)
        local tileprops = map:getTileProperties("Ground", tile_x, tile_y)

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


function love.mousemoved(x, y, dx, dy, istouch)
    mouse_x, mouse_y = x, y
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "return" then
        map.offset_x = 0 map.offset_y = 0
        map.target_x = 0 map.target_y = 0
        map.start_x = 0 map.start_y = 0
    elseif key == "g" then
        showgrid = not showgrid
    elseif key == "left" then
        mhex_x = mhex_x - 1
    elseif key == "right" then
        mhex_x = mhex_x + 1
    elseif key == "up" then
        mhex_y = mhex_y - 1
    elseif key == "down" then
        mhex_y = mhex_y + 1
    end
    local px, py = map:convertTileToPixel(mhex_x, mhex_y)
    sprite.x = px - 21/2
    sprite.y = py - 17/2
    sprite.spriteBatch:updateSprite(sprite)
end

if love.loop then
    love.loop()
end
