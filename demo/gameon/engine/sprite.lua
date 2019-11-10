--- Sprite base module for all sprites in the game
-- @module gameon.engine.Sprite

--- Base Sprite table
-- @table Sprite
local Sprite = {
    action = nil, -- The name of current animation action
    x = 0, -- The sprite x position
    y = 0, -- The sprite y position
    flipped = false -- Is the sprite flipped horizontally
}
Sprite.__index = Sprite

function Sprite.new(o)
    o = o or {}
    o.animation = nil
    return setmetatable(o, Sprite)
end

function Sprite:setanimation(animation)
    self.animation = animation
end

function Sprite:setaction(action)
    self.action = action
    self.current_time = 0
    self.frame_index = 1
    self.animation = nil
end

function Sprite:getPositionAtTile(tx, ty)
    if type(tx) == "table" then
        tx, ty = tx.x, tx.y
    end
    local px, py = self.map:convertTileToPixel(tx, ty)
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
    local previousTile = self.currentTile
    self.currentTile = self.map:getTileInfoAt(tx, ty)   
    self.x = x
    self.y = y
    if previousTile ~= self.currentTile then
        if previousTile then
            self.map:removeUnitFromTile(self, previousTile)
        end
        self.map:addUnitToTile(self, self.currentTile)
    end
end

--- Updates sprite's animation.
-- If dt param is nil the method will force update the sprite.
-- This method will be called in response of SpriteSheet.update(dt).
-- @param dt time elapsed from last love.update
function Sprite:update(dt)
    if not dt then
        self.spriteSheet:updateSprite(self)
        return
    end

    -- if #self.animations > 0 then
    --     if self.animations[1]:update(dt) then
    --         self.animations = {}
    --     end
    --     self.spriteSheet:updateSprite(self)
    -- end
    if self.animation then
        if self.animation:update(dt) then
            -- self.animation = nil
        end
        self.spriteSheet:updateSprite(self)
    end

    local action_frames_count = #self.spriteSheet.frames[self.action]
    local action_duration = self.spriteSheet.frames[self.action].duration
    self.current_time = self.current_time + dt
    if self.current_time >= action_duration then
        self.current_time = self.current_time - action_duration
    end
    local frame_index = math.floor(self.current_time / action_duration * action_frames_count) % action_frames_count + 1

    if self.frame_index ~= frame_index then
        self.frame_index = frame_index
        self.spriteSheet:updateSprite(self)
    end
end

function Sprite:destroy()
    if self.currentTile then
        self.map:removeUnitFromTile(self)
    end
    self.spriteSheet:deleteSprite(self)    
    self.deleted = true
end

return Sprite
