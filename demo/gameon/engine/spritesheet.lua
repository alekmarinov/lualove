--- SpriteSheet module for loading and generating sprites from a sprite sheet
-- Supports the format produced by Free Texture Packer
--
-- @module gameon.engine.SpriteSheet

-- imports and locals
local thispackage = (...):match("(.-)[^%.]+$")
local Util = require "gameon.util"
local json = require "dkjson"
local Paint = require (thispackage..".paint")

local SpriteSheet = {
}
SpriteSheet.__index = SpriteSheet

local function getNameFromFile(jsonfile)
    return Util.splitext(Util.basename(jsonfile))
end

--- Loads spritesheet from file
-- @string jsonfile Path to json file in the format of Free Texture Packer
function SpriteSheet.load(painter, jsonfile, hexsidelength)
    local jsonstr, err = love.filesystem.read(jsonfile)
    if not jsonstr then
        return nil, err
    end

    local o = setmetatable({
        sprites = {},
        frames = {},
        batches = {},
        painter = painter
    }, SpriteSheet)

    local info = json.decode(jsonstr)
    o.name = getNameFromFile(jsonfile)

    local image = painter:load(o.name, Util.join(Util.dirname(jsonfile), info.meta.image))

    for framename, frameinfo in pairs(info.frames) do
        local _, action_name_index = Util.splitpath(framename)
        local frame_index = action_name_index:match(".*_(.*)")
        frame_index = 1 + tonumber(frame_index)
        local action_name = action_name_index:match("(.*)_.*")
        o.frames[action_name] = o.frames[action_name] or {}
        o.frames[action_name].duration = 1
        o.frames[action_name].origin_x = (o.frames[action_name].origin_x or 0) + frameinfo.frame.w
        o.frames[action_name].origin_y = (o.frames[action_name].origin_y or 0) + frameinfo.frame.h
        o.frames[action_name][frame_index] = {
            quad = love.graphics.newQuad(
                frameinfo.frame.x, frameinfo.frame.y,
                frameinfo.frame.w, frameinfo.frame.h, info.meta.size.w, info.meta.size.h),
            frame = frameinfo.spriteSourceSize
        }
    end
    for action_name, action_info in pairs(o.frames) do
        action_info.origin_x = action_info.origin_x / #action_info / 2
        action_info.origin_y = action_info.origin_y / #action_info / 2
        if action_name == "Attacking" then
            action_info.attack_hit_frame = math.floor(0.8 * #action_info)
        end
    end
    return o
end

function SpriteSheet:createForColor(color)
    local image = self.painter:create(self.name, color)
    self.batches[color] = love.graphics.newSpriteBatch(image)
    self.sprites[color] = {
        max_sprite_index = 0
    }
end

--- Creates new sprite instance from this spritesheet
-- @param sprite A sprite object
-- @see gameon.engine.Sprite
function SpriteSheet:createSprite(sprite)
    local color = sprite.color

    -- searching for a gap
    local sprite_index = self.sprites[color].max_sprite_index + 1
    for i = 1, self.sprites[color].max_sprite_index do
        if not self.sprites[color][i] then
            sprite_index = i
        end
    end
    sprite.frame_index = 1
    sprite.current_time = 0
    sprite.sprite_index = sprite_index

    local frameinfo = self.frames[sprite.action][sprite.frame_index]
    local flipped_correction = sprite.flipped and frameinfo.frame.w or 0
    local params = {frameinfo.quad, sprite.x + flipped_correction, sprite.y, 0, sprite.flipped and -1 or 1, 1}
    if sprite_index > self.sprites[color].max_sprite_index then
        -- add new sprite's quad to batch
        self.batches[color]:add(unpack(params))
        self.sprites[color].max_sprite_index = sprite_index
    else
        -- set to deleted slot
        self.batches[color]:set(sprite_index, unpack(params))
    end
    -- add or update the array of sprite instances 
    self.sprites[color][sprite_index] = sprite

    -- set reference in the sprite to self
    sprite.spriteSheet = self
    return sprite
end

--- Updates a sprite
-- Call this function when one of the following sprite property changed - x, y, frame_index, action, flipped
-- @param sprite A sprite instance
-- @see gameon.engine.Sprite
function SpriteSheet:updateSprite(sprite)
    local color = sprite.color
    local frameinfo = self.frames[sprite.action][sprite.frame_index]
    local flipped_correction = sprite.flipped and frameinfo.frame.w or 0
    self.batches[color]:set(sprite.sprite_index, frameinfo.quad, sprite.x + flipped_correction, sprite.y, 0, sprite.flipped and -1 or 1, 1)
end

--- Deletes sprite instance
-- @param sprite A sprite instance
-- @see gameon.engine.Sprite
function SpriteSheet:deleteSprite(sprite)
    local color = sprite.color
    self.sprites[color][sprite.sprite_index] = nil
    self.batches[color]:set(sprite.sprite_index, 0, 0, 0, 0, 0)
end

--- Updates all sprites in the spritesheet
-- Call this function in love.update
-- @number dt time elapsed from last love.update
function SpriteSheet:update(dt)
    for color, sprites in pairs(self.sprites) do
        for i = 1, sprites.max_sprite_index do
            local sprite = sprites[i]
            if sprite then
                sprite:update(dt)
            end
        end
    end
end

function SpriteSheet:updateEventBoxes(dt)
    for color, sprites in pairs(self.sprites) do
        for i = 1, sprites.max_sprite_index do
            local sprite = sprites[i]
            if sprite then
                sprite.eventBox:update(dt)
            end
        end
    end
end

--- Draws all sprite instances
function SpriteSheet:draw()
    for color, batch in pairs(self.batches) do
        love.graphics.draw(batch)
    end
end

return SpriteSheet
