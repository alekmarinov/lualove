--- hexmap formulas
-- @module gameon.engine.algo.hexmap
-- https://www.redblobgames.com/grids/hexagons/#distances

local HexMap = {
    directions = {
        {
            { 1,  0}, { 1, -1}, { 0, -1}, 
            {-1, -1}, {-1,  0}, { 0,  1}
        },
        {
            { 1,  1}, { 1,  0}, { 0, -1}, 
            {-1,  0}, {-1,  1}, { 0,  1}
        }
    }
}
HexMap.__index = HexMap

function HexMap.neighbours(offset)
    local i = 0
    local parity = 1 + (offset.x-1) % 2

    return function ()
        local dir = HexMap.directions[parity][i+1]
        if dir then
            i = i + 1
            return i, offset.x + dir[1], offset.y + dir[2]
        end
    end
end

function HexMap.offset_to_cube(col, row)
    local x = col
    local z = row - (col + col % 2) / 2
    local y = -x-z
    return x, y, z
end

function HexMap.cube_to_offset(x, y, z)
    return x, z + (x + x % 2) / 2
end

function HexMap.cube_distance(ax, ay, az, bx, by, bz)
    return math.max(math.abs(ax - bx), math.abs(ay - by), math.abs(az - bz))
end

-- https://github.com/peterwittek/somoclu/issues/130
function HexMap.offset_distance(a, b)
    local ax, ay, az = HexMap.offset_to_cube(a.x, a.y)
    local bx, by, bz = HexMap.offset_to_cube(b.x, b.y)
    return HexMap.cube_distance(ax, ay, az, bx, by, bz)
end

function HexMap.range(center, N, withcenter)
    local cx, cy, cz = HexMap.offset_to_cube(center.x, center.y)

    return coroutine.wrap(function()
        for x = -N, N do
            for y = math.max(-N, -x - N), math.min(N, -x + N) do
                if withcenter or (x ~= 0 or y ~= 0) then
                    local z = -x -y
                    coroutine.yield(HexMap.cube_to_offset(cx + x, cy + y, cz + z))
                end
            end
        end
    end)
end

return HexMap
