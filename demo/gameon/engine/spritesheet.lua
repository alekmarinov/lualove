--- SpriteSheet module for loading and generating sprites from a sprite sheet
-- Supports the format produced by Free Texture Packer
--
-- @module gameon.engine.SpriteSheet

-- imports and locals
local thispackage = (...):match("(.-)[^%.]+$")

local json = require "dkjson"
local plpath = require "pl.path"

local SpriteSheet = {
}
SpriteSheet.__index = SpriteSheet

--- Loads spritesheet from file
-- @string jsonfile Path to json file in the format of Free Texture Packer
function SpriteSheet.load(jsonfile)
    local jsonstr, err = love.filesystem.read(jsonfile)
    if not jsonstr then
        return nil, err
    end

    local o = setmetatable({
        sprites = {},
        frames = {},
        max_width = 0,
        max_height = 0,
    }, SpriteSheet)

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
        if frameinfo.frame.w > o.max_width then
            o.max_width = frameinfo.frame.w
        end
        if frameinfo.frame.h > o.max_height then
            o.max_height = frameinfo.frame.h
        end
    end
    o.batch = love.graphics.newSpriteBatch(image)
    return o
end

--- Creates new sprite instance from this spritesheet
-- @param sprite A sprite object
-- @see gameon.engine.Sprite
function SpriteSheet:createSprite(sprite)

    -- searching for a gap
    local sprite_index = #self.sprites + 1
    for i = 1, #self.sprites do
        if not self.sprites[i] then
            sprite_index = i
        end
    end

    sprite.frame_index = 1
    sprite.current_time = 0
    sprite.sprite_index = sprite_index

    local quad = self.frames[sprite.action][sprite.frame_index]
    local params = {quad, sprite.x, sprite.y, 0, sprite.flipped and -1 or 1, 1}
    if sprite_index > #self.sprites then
        -- add new sprite's quad to batch
        self.batch:add(unpack(params))
    else
        -- set to deleted slot
        self.batch:set(sprite_index, unpack(params))
    end
    -- add or update the array of sprite instances 
    self.sprites[sprite_index] = sprite

    -- set reference in the sprite to self
    sprite.spriteSheet = self
    return sprite
end

--- Updates a sprite
-- Call this function when one of the following sprite property changed - x, y, frame_index, action, flipped
-- @param sprite A sprite instance
-- @see gameon.engine.Sprite
function SpriteSheet:updateSprite(sprite)
    local quad = self.frames[sprite.action][sprite.frame_index]
    if not quad then
        print(string.format("Quad is missing for %s frame #%d", sprite.action, sprite.frame_index))
    end
    local flipped_correction = 0
    if sprite.flipped then
        flipped_correction = self.max_width
    end
    self.batch:set(sprite.sprite_index, quad, sprite.x + flipped_correction, sprite.y, 0, sprite.flipped and -1 or 1, 1)
end

--- Deletes sprite instance
-- @param sprite A sprite instance
-- @see gameon.engine.Sprite
function SpriteSheet:deleteSprite(sprite)
    self.sprites[sprite.sprite_index] = nil
    self.batch:set(sprite.sprite_index, 0, 0, 0, 0, 0)
end

--- Updates all sprites in the spritesheet
-- Call this function in love.update
-- @number dt time elapsed from last love.update
function SpriteSheet:update(dt)
    for i = 1, #self.sprites do
        local sprite = self.sprites[i]
        if sprite then
            sprite:update(dt)
        end
    end
end

--- Draws all sprite instances
function SpriteSheet:draw()
    love.graphics.draw(self.batch)
end

return SpriteSheet
