--- Unit base module for all units in the game
-- @module gameon.engine.Unit

local thispackage = (...):match("(.-)[^%.]+$")

local pltablex = require "pl.tablex"
local Sprite = require (thispackage..".sprite")
local Animation = require (thispackage..".animation")
local Game = require "gameon.game"

--- Base Unit table
-- @table Unit
local Unit = setmetatable({
    moveduration = 1
}, Sprite)
Unit.__index = Unit

function Unit.new(player, typename)
    local o = setmetatable(Sprite.new{
        player = player,
        typename = typename,
        action = "Idle"
    }, Unit)
    return o
end

function Unit:isFriendly(unit)
    return self.player.team == unit.player.team
end

function Unit:moveto(x, y)
    local tx, ty = self.map:convertPixelToTile(x, y)
    local currentTile = self:getCurrentTile()
    local goalTile = self.map:getTileInfoAt(tx, ty)
    self.path = {}
    self.map.visited_nodes = {}
    self.map.selected_path_to = {}
    if goalTile then
        if goalTile ~= currentTile then
            local goalProps = self.map:getTileProperties(goalTile.x, goalTile.y)
            if tonumber(goalProps.move_points) > 0 then
                self.path = self.map.astar:find(currentTile, goalTile, {
                    callback_visited = function (node, cost)
                        table.insert(self.map.visited_nodes, {node, cost})
                    end}) or {}
                self.map.selected_path_to = pltablex.copy(self.path)
                if self.path then
                    self:walkThrough()
                end
            end
        end
    end
end

function Unit:walkThrough(come_from)
    if #self.path > 1 then
        self:setaction("Walking")
        local nextTile = self.path[2]
        local px, py = self:getPositionAtTile(nextTile.x, nextTile.y)
        if px ~= self.x then
            self.flipped = px < self.x
        end
        if #(nextTile.units or {}) > 0 then
            local otherUnit = nextTile.units[1]
            print("Have units in the destination tile!")
            if #self.path == 2 then
                -- nextTile is the last tile in the path
                if self:isFriendly(otherUnit) then
                    -- stop next to the friendly unit
                    self:setaction("Idle")
                else
                    -- attack the enemy
                    self:setaction("Attacking")
                end
            else
                -- seek surrounding path omitting occupied surrounding tiles
                local excluded = {}
                if come_from then
                    excluded[come_from] = true
                end
                for next in self.map:neighboursIterator(self.path[1]) do
                    if #(next.units or {}) > 0 then
                        excluded[next] = true
                    end
                end
                self.path = self.map.astar:find(self.path[1], self.path[#self.path], {
                    excluded = excluded,
                    callback_visited = function (node, cost)
                        table.insert(self.map.visited_nodes, {node, cost})
                    end}) or {}
                self.map.selected_path_to = pltablex.copy(self.path)
                if #self.path > 0 then
                    self:walkThrough()
                else
                    -- unit blocked, stop
                    self:setaction("Idle")
                end
            end
            return
        end
        local props = self.map:getTileProperties(nextTile.x, nextTile.y)
        self:setanimation(Animation.new{
            duration = props.move_points * self.moveduration,
            varlist = { "x", "y" },
            varsto = { x = px, y = py },
            object = self,
            callback_finished = function ()
                local come_from = table.remove(self.path, 1)
                self:walkThrough(come_from)
            end,
            callback_update = function (x, y)
                self:setPos(x, y)
            end
        })
    else
        self:setaction("Idle")
    end
end

return Unit
