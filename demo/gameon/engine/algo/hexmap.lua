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
            return i, { x = offset.x + dir[1], y = offset.y + dir[2] }
        end
    end
end

function HexMap.offset_to_cube(offset)
    local x = offset.x
    local z = offset.y - (offset.x + offset.x % 2) / 2
    local y = -x-z
    return {x = x, y = y, z = z}
end

function HexMap.cube_distance(a, b)
    return math.max(math.abs(a.x - b.x), math.abs(a.y - b.y), math.abs(a.z - b.z))
end

-- https://github.com/peterwittek/somoclu/issues/130
function HexMap.offset_distance(a, b)
    -- local dx = a.x - b.x
    -- local dy = a.y - b.y
    -- return math.sqrt(dx * dx + dy * dy * 0.75)
    local ac = HexMap.offset_to_cube(a)
    local bc = HexMap.offset_to_cube(b)
    return HexMap.cube_distance(ac, bc)
end

return HexMap
