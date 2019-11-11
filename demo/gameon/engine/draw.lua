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

function Draw.cross( p, size )
    love.graphics.setLineStyle("rough")
    love.graphics.line(p.x - size, p.y, p.x + size, p.y)
    love.graphics.line(p.x, p.y - size, p.x, p.y + size)
end

function Draw.dashline( p1, p2, dash, gap )
    local dy, dx = p2.y - p1.y, p2.x - p1.x
    local an, st = math.atan2( dy, dx ), dash + gap
    local len = math.sqrt( dx*dx + dy*dy )
    local nm = ( len - dash ) / st
    love.graphics.push()
    love.graphics.translate( p1.x, p1.y )
    love.graphics.rotate( an )
    for i = 0, nm do
        love.graphics.line(i * st, 0, i * st + dash, 0)
    end
    love.graphics.pop()
end

function Draw.dashrect( p1, p2, dash, gap)
    local topleft = { x = math.min(p1.x, p2.x), y = math.min(p1.y, p2.y) }
    local bottomright = { x = math.max(p1.x, p2.x), y = math.max(p1.y, p2.y) }
    local topright = { x = bottomright.x, y = topleft.y }
    local bottomleft = { x = topleft.x, y = bottomright.y }

    Draw.dashline(topleft, topright, dash, gap)
    Draw.dashline(topright, bottomright, dash, gap)
    Draw.dashline(bottomright, bottomleft, dash, gap)
    Draw.dashline(bottomleft, topleft, dash, gap)
end

return Draw
