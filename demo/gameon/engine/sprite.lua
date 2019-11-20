--- Sprite base module for all sprites in the game
-- @module gameon.engine.Sprite

local thispackage = (...):match("(.-)[^%.]+$")

local EventBox = require (thispackage..".eventbox")

--- Base Sprite table
-- @table Sprite
local Sprite = {
    color = nil, -- The spritesheet's color of this sprite
    action = nil, -- The name of current animation action,
    opacity = 0, -- Sprites' opacity
    lock_opacity = false, -- Set the opacity as locked to avoid changing by fade during move
    x = 0, -- The sprite x position
    y = 0, -- The sprite y position
    last_update_x = -1, -- The x position of last sprite update
    last_update_y = -1, -- The y position of last sprite update
    last_update_opacity = -1, -- The opacity of last sprite update
    flipped = false, -- Is the sprite flipped horizontally
    cycle = 0 -- animation cycle
}
Sprite.__index = Sprite

function Sprite.new(o)
    assert(o and o.color, "color attribute is mandatory")
    o = setmetatable(o, Sprite)
    if not o.action then
        o.action = o.type -- there is only one action with the name of the sprite type
    end
    o.eventBox = EventBox.new(o)
    return o
end

function Sprite:setanimation(animation)
    self.animation = animation
end

function Sprite:setAction(action)
    self.action = action
    self.current_time = 0
    self.frame_index = 1
    self.animation = nil
    self.cycle = 0
end

function Sprite:getPositionAtTile(tile)
    local px, py = self.map:convertTileToPixel(tile.x, tile.y)
    local frameinfo = self.spriteSheet.frames[self.action]
    px = px - frameinfo.origin_x
    py = py - frameinfo.origin_y
    return px, py
end

function Sprite:setOpacity(opacity)
    self.opacity = opacity
    self:lockOpacity(true)
end

function Sprite:lockOpacity(locked)
    self.lock_opacity = locked
end

function Sprite:getOrigin()
    local frameinfo = self.spriteSheet.frames[self.action]
    return frameinfo.origin_x, frameinfo.origin_y
end

function Sprite:setPos(x, y)
    local ox, oy = self:getOrigin()
    local tx, ty = self.map:convertPixelToTile(ox + x, oy + y)
    self.tile = self.map:getTileAt(tx, ty)
    self.x = x
    self.y = y
end

--- Updates sprite's animation.
-- If dt param is nil the method will force update the sprite.
-- This method will be called in response of SpriteSheet.update(dt).
-- @param dt time elapsed from last love.update
function Sprite:update(dt)
    if self.animation then
        self.animation:update(dt)
    end
    local force_update = self.last_update_x ~= self.x or self.last_update_y ~= self.y or self.last_update_opacity ~= self.opacity
    self.last_update_x, self.last_update_y, self.last_update_opacity = self.x, self.y, self.opacity
    local action_frames_count = #assert(self.spriteSheet.frames[self.action], "Action "..self.action.." is undefined")
    local action_duration = self.spriteSheet.frames[self.action].duration
    self.current_time = self.current_time + dt
    if self.current_time >= action_duration then
        self.current_time = self.current_time - action_duration
    end
    local frame_index = math.floor(self.current_time / action_duration * action_frames_count) % action_frames_count + 1
    if self.frame_index ~= frame_index then
        self:onFrameChanged(self.cycle, self.frame_index, frame_index)
        force_update = true
    end
    if force_update then
        local cycled = frame_index < self.frame_index
        self.frame_index = frame_index
        self.spriteSheet:updateSprite(self)
        if cycled then
            self:onAnimationFinished(self.cycle)
            self.cycle = self.cycle + 1
        end
    end
end

function Sprite:onFrameChanged(cycle, prevFrame, nextFrame)
end

function Sprite:onAnimationFinished(cycle)
end

function Sprite:onSelected(selected)
    self.selected = selected
end

function Sprite:isSelected()
    return self.selected
end

function Sprite:destroy()
    self.spriteSheet:deleteSprite(self)    
    self.deleted = true
end

return Sprite
