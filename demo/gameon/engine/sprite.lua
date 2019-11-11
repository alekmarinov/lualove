--- Sprite base module for all sprites in the game
-- @module gameon.engine.Sprite

--- Base Sprite table
-- @table Sprite
local Sprite = {
    color = nil, -- The spritesheet's color of this sprite
    action = nil, -- The name of current animation action
    x = 0, -- The sprite x position
    y = 0, -- The sprite y position
    last_update_x = -1, -- The x position of last sprite update
    last_update_y = -1, -- The y position of last sprite update
    flipped = false, -- Is the sprite flipped horizontally
    cycle = 0 -- animation cycle
}
Sprite.__index = Sprite

function Sprite.new(o)
    assert(o and o.color, "color attribute is mandatory")
    o = setmetatable(o, Sprite)
    o.action = o.action or o.typename
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

function Sprite:getCurrentTile()
    return self.currentTile
end

function Sprite:setPos(x, y)
    local frameinfo = self.spriteSheet.frames[self.action]
    local tx, ty = self.map:convertPixelToTile(x + frameinfo.origin_x, y + frameinfo.origin_y)
    self.currentTile = self.map:getTileAt(tx, ty)   
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
    local force_update = self.last_update_x ~= self.x or self.last_update_y ~= self.y
    self.last_update_x, self.last_update_y = self.x, self.y
    local action_frames_count = #self.spriteSheet.frames[self.action]
    local action_duration = self.spriteSheet.frames[self.action].duration
    self.current_time = self.current_time + dt
    if self.current_time >= action_duration then
        self.current_time = self.current_time - action_duration
        self.cycle = self.cycle + 1
    end
    local frame_index = math.floor(self.current_time / action_duration * action_frames_count) % action_frames_count + 1
    if self.frame_index ~= frame_index then
        self:onFrameChanged(self.cycle, self.frame_index, frame_index)
        force_update = true
    end
    if force_update then
        self.frame_index = frame_index
        self.spriteSheet:updateSprite(self)
    end
end

function Sprite:onFrameChanged(cycle, prevFrame, nextFrame)
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
