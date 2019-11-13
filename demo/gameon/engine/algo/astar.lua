--- A* algorithm
-- @module gameon.engine.algo.astar

local thispackage = (...):match("(.-)[^%.]+$")

local PriorityQueue = require (thispackage..".priorityqueue")
local List = require 'pl.List'

local AStar = {
    DEPTH_LIMIT = 200,
    DEPTH_LIMIT_FAST = 10
}
AStar.__index = AStar

function AStar.new(params)
    local o = setmetatable({
        callback_neighbours = params.callback_neighbours,
        callback_distance = params.callback_distance,
        callback_cost = params.callback_cost
    }, AStar)

    return o
end

function AStar:find(start, goal, options)
    options = options or {}
    local callback_neighbours = options.callback_neighbours or self.callback_neighbours
    local callback_visited = options.callback_visited
    local excluded = options.excluded or {}
    local depth_limit = options.depth_limit or AStar.DEPTH_LIMIT
    local frontier = PriorityQueue()
    local came_from = {
        [start] = nil
    }
    local cost_so_far = {
        [start] = 0
    }

    frontier:put(start, 0)
    local found = false
    local depth = 0
    local closest = nil
    local closest_distance = 2^53
    while not frontier:empty() do
        local current = frontier:pop()
    
        local distance = self.callback_distance(current, goal)
        -- set the closest tile so far
        if distance < closest_distance then
            closest = current
            closest_distance = distance
        end

        if distance == 0 then
            break
        elseif distance == 1 then
            came_from[goal] = closest
            closest = goal
            break
        end

        -- depth limit
        if depth == depth_limit then
            break
        end

        for next in callback_neighbours(current) do
            if not excluded[next] then
                local new_cost = cost_so_far[current] + self.callback_cost(current, next)
                if not cost_so_far[next] or new_cost < cost_so_far[next] then
                    cost_so_far[next] = new_cost
                    local priority = new_cost + self.callback_distance(goal, next)
                    frontier:put(next, priority)
                    if callback_visited then
                        callback_visited(next, priority)
                    end
                    came_from[next] = current
                end
            end
        end

        depth = depth + 1
    end

    -- retrieve path to the closest tile found
    local current = closest
    local path = List()
    while self.callback_distance(current, start) ~= 0 do
        path:append(current)
        current = came_from[current]
    end
    path:reverse()
    return path
end

return AStar
