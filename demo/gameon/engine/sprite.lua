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

function Sprite:setanimation(animation)
    self.animation = animation
end

function Sprite:setaction(action)
    self.action = action
    self.current_time = 0
    self.frame_index = 1
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

    if self.animation then
        if self.animation:update(dt) then
            self.animation = nil
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

return Sprite
