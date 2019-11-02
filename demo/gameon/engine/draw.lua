--- Drawing primitives
-- @module gameon.engine.Draw

local Draw = {
}

--- Draws hexagon with given center and side size
-- @number cx Hexagon x center
-- @number cy Hexagon y center
-- @number size Hexagon side size
function Draw.hexagon(cx, cy, size)
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

return Draw
