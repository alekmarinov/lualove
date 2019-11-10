--- Map module
-- @module gameon.engine.Map

local thispackage = (...):match("(.-)[^%.]+$")

local pltablex = require "pl.tablex"
local sti = require "sti"
local Animation = require (thispackage..".animation")
local AStar = require (thispackage..".algo.astar")
local HexMap = require (thispackage..".algo.hexmap")
local SpriteSheet = require (thispackage..".spritesheet")
local Sprite = require (thispackage..".sprite")
local Unit = require (thispackage..".unit")
local Draw = require (thispackage..".draw")
local Selector = require (thispackage..".selector")
local Game = require "gameon.game"

--- Base Map table
-- @table Map
local Map = {
    color_background = {0.25, 0.25, 0.75, 1},
    color_cursor = {1, 1, 1, 1},
    zoom_step = 0.1,
    offset_x = 0,
    offset_y = 0,
    zoom = 1,
    scrolltime = 0.5
}
Map.__index = Map

function Map.load(params)
    local o = setmetatable({
        spritesheets = {},
        tilesinfo = {},
        cursor = nil,
        offset_x = 0,
        offset_y = 0
    }, Map)
    o.sti = sti(params.mapfile)

    for j = 1, o.sti.layers["Ground"].height do
        o.tilesinfo[j] = {}
        for i = 1, o.sti.layers["Ground"].width do
            o.tilesinfo[j][i] = {
                x = i,
                y = j
            }
        end
    end
    local layer = o.sti:addCustomLayer("Sprites", 2)

    for _, spritesheetfile in ipairs(params.spritesheets or {}) do
        local spritesheet = SpriteSheet.load(spritesheetfile)
        table.insert(o.spritesheets, spritesheet)
        o.spritesheets[spritesheet.name] = spritesheet
    end

    -- Draw Sprites layer
    layer.draw = function(self)

        Selector:drawSelectedItems()

        -- draw sprites
        for _, spritesheet in ipairs(o.spritesheets) do
            -- for _, sprite in ipairs(spritesheet.sprites) do
            --     local frameinfo = spritesheet.frames[sprite.action][sprite.frame_index].frame
            --     love.graphics.setColor(1, 1, 1, 1)
            --     love.graphics.setLineWidth(2)
            --     love.graphics.setLineStyle("smooth")
            --     love.graphics.ellipse( "line", sprite.x + frameinfo.w / 2, sprite.y + frameinfo.h - o.sti.hexsidelength / 4, o.sti.hexsidelength, o.sti.hexsidelength / 2)
            -- end
            spritesheet:draw()
        end

        -- draw cursor
        if o.show_cursor and o.cursor then
            local px, py = o.sti:convertTileToPixel(o.cursor.x, o.cursor.y)
            love.graphics.setColor(o.color_cursor)
            Draw.hexagon(px, py, o.sti.hexsidelength)
            love.graphics.printf(string.format("%d %d", o.cursor.x, o.cursor.y), px - o.sti.hexsidelength, py - o.sti.hexsidelength/2, 2 * o.sti.hexsidelength, "center")
        end

        -- draw visited nodes
        if o.show_visited and o.visited_nodes then
            for _, visited_node in ipairs(o.visited_nodes) do
                local node = visited_node[1]
                local cost = visited_node[2]
                local px, py = o.sti:convertTileToPixel(node.x, node.y)
                love.graphics.setColor(1, 0, 0, 1)
                Draw.hexagon(px, py, o.sti.hexsidelength)
                love.graphics.setColor(1, 1, 1, 0.8)
                love.graphics.printf(string.format("%.2f", cost), px - o.sti.hexsidelength, py - o.sti.hexsidelength/2, 2 * o.sti.hexsidelength, "center")
            end
        end

        -- draw selected path
        if o.show_path and o.selected_path_to then
            for i, node in ipairs(o.selected_path_to) do
                local px, py = o.sti:convertTileToPixel(node.x, node.y)
                love.graphics.setColor(o.color_cursor)
                Draw.hexagon(px, py, o.sti.hexsidelength)
                love.graphics.printf(string.format("%d", i), px - o.sti.hexsidelength, py - o.sti.hexsidelength/2, 2 * o.sti.hexsidelength, "center")
            end
        end

        -- draw neighbours
        if o.show_neighbours and o.neighbours then
            for i, node in ipairs(o.neighbours) do
                local px, py = o.sti:convertTileToPixel(node.x, node.y)
                love.graphics.setColor(1, 0, 0, 1)
                Draw.hexagon(px, py, o.sti.hexsidelength)
                love.graphics.printf(string.format("%d", i), px - o.sti.hexsidelength, py - o.sti.hexsidelength/2, 2 * o.sti.hexsidelength, "center")
            end
        end

        Selector:draw()

        love.graphics.setColor(1, 1, 1, 1)
    end

    o.astar = AStar.new{
        callback_neighbours = function (node)
            return o:neighboursIterator(node)
        end,
        callback_distance = HexMap.offset_distance,
        callback_cost = function(node1, node2)
            local props = o.sti:getTileProperties("Ground", node2.x, node2.y)
            return tonumber(props.move_points)
        end
    }

    return o
end

function Map:neighboursIterator(tile)
    local nextiter = HexMap.neighbours(tile)
    return function()
        local i, next, tile
        repeat
            i, next = nextiter()
            if next then
                tile = self:getTileInfoAt(next.x, next.y)
                local props = self:getTileProperties(next.x, next.y)
                if tonumber(props.move_points) < 0 then
                    tile = nil
                end
                if tile and tile.units and tile.units[1] then
                    -- surround only friendly units
                    local unitAtTile = tile.units[1]
                    if unitAtTile.action == "Idle" then
                        tile = nil
                    end
                end
            end
        until not next or tile
        return tile
    end
end

function Map:getHexSideLength()
    return self.sti.hexsidelength
end

function Map:getTileInfoAt(tx, ty)
    if self.tilesinfo[ty] then
        return self.tilesinfo[ty][tx]
    end
end

function Map:getTileProperties(tx, ty)
    return self.sti:getTileProperties("Ground", tx, ty)
end

function Map:convertPixelToTile(mx, my)
    return self.sti:convertPixelToTile(mx, my)
end

function Map:convertTileToPixel(tx, ty)
    return self.sti:convertTileToPixel(tx, ty)
end

function Map:removeUnitFromTile(unit, tile)
    -- remove unit from tile
    local idx = pltablex.find(tile.units or {}, unit)
    assert(idx, string.format("Can't find unit at tile %d %d", tile.x, tile.y))
    table.remove(tile.units, idx)
end

function Map:addUnitToTile(unit, tile)
    assert(not pltablex.find(tile.units or {}, unit))
    tile.units = tile.units or {}
    table.insert(tile.units, unit)
end

function Map:spawnunit(unit, tx, ty)
    unit.map = self
    local spritesheet = self.spritesheets[unit.typename]
    spritesheet:createSprite(unit)
    
    unit:setPos(unit:getPositionAtTile(tx, ty))

    -- -- add unit to tile
    -- self:addUnitToTile(unit)
end

function Map:setcursor(x, y)
    -- set cursor
    self.cursor = self.cursor or {}
    self.cursor.x = x
    self.cursor.y = y

    -- select the first unit on tile
    local tile = self:getTileInfoAt(x, y)
    local unit = tile and tile.units and tile.units[1]
    if unit then
        self:selectunit(unit)
    end

    self.neighbours = {}
    self.nbidx = self.nbidx or 1
    for _, next in HexMap.neighbours({x = x, y = y}) do
        table.insert(self.neighbours, next)
    end
end

function Map:unsetcursor()
    self.cursor = nil
    self.selected_unit = nil
    self.visited_nodes = nil
    self.neighbours = nil
end

function Map:selectunit(unit)
    self.selected_unit = unit
end

function Map:draw()
    love.graphics.setBackgroundColor(self.color_background)
    self.sti:draw(self.offset_x, self.offset_y, self.zoom, self.zoom)
end

function Map:update(dt)
    self.sti:update(dt)

    -- update sprite animations
    for _, spritesheet in ipairs(self.spritesheets) do
        spritesheet:update(dt)
    end

    -- smooth map positioning
    if self.animation then
        self.animation:update(dt)
    end
end

function Map:wheelmoved(x, y)
    self.zoom = self.zoom + y * self.zoom_step
    if self.zoom < 1 then
        self.zoom = 1
    elseif self.zoom > 2 then
        self.zoom = 2
    end
end

function Map:smoothcentertile(tx, ty)
    -- centering the tile by smooth scroll the map
    local tile_px, tile_py = self.sti:convertTileToPixel(tx, ty)
    self.animation = Animation.new{
        duration = self.scrolltime,
        varlist = { "offset_x", "offset_y" },
        varsto = {
            offset_x = love.graphics.getWidth() / 2 / self.zoom - tile_px,
            offset_y = love.graphics.getHeight() / 2 / self.zoom - tile_py
        },
        object = self,
        callback_finished = function()
            self.animation = nil
        end,
        callback_update = function (offset_x, offset_y)
            self.offset_x, self.offset_y = offset_x, offset_y
        end
    }
end

function Map:convertPixelToMapCoord(x, y)
    return x / self.zoom - self.offset_x, y / self.zoom - self.offset_y
end

function Map:mappressed(x, y, b)
    if Selector:mappressed(x, y, b) then
        return true
    end
    if b == 1 then
        -- select tile 
        -- local tile_x, tile_y = self.sti:convertPixelToTile(x / self.zoom - self.offset_x, y / self.zoom - self.offset_y)
        -- self:setcursor(tile_x, tile_y)
        -- center the selected tile
        -- self:smoothcentertile(tile_px, tile_py)
    elseif b == 2 then
        self.selected_path_to = nil
        if #Selector.selected_units > 0 then
            local tile_x, tile_y = self.sti:convertPixelToTile(x, y)
            -- self:setcursor(tile_x, tile_y)

            -- -- find path
            -- local tilestart = self:getTileInfoAt(self.selected_unit.tx, self.selected_unit.ty)
            -- local tilegoal = self:getTileInfoAt(tile_x, tile_y)
            -- if tilestart and tilegoal then
            --      self.visited_nodes = {}
            --     local path = self.astar:find(tilestart, tilegoal, function (node, cost)
            --         table.insert(self.visited_nodes, {node, cost})
            --     end)
            --     self.selected_path_to = path
            -- end

            self:setcursor(tile_x, tile_y)
            for _, unit in ipairs(Selector.selected_units) do
                -- move unit
                unit:moveto(x, y)
                -- self:moveunit(unit, tile_x, tile_y)
            end
        end
    elseif b == 3 then
        local tile_x, tile_y = self.sti:convertPixelToTile(x, y)
        map:spawnunit(Unit.new(Game.currentPlayer, "barbarian1"), tile_x, tile_y)
    end
end

function Map:mapreleased(x, y, b)
    if Selector:mapreleased(x, y, b) then
        return true
    end

    self.drag_from_x = nil
    self.drag_from_y = nil
end

function Map:mapmoved(x, y, dx, dy, istouch)
    if Selector:mapmoved(x, y, dx, dy, istouch) then
        return true
    end
end

function Map:mousepressed(x, y, b)
    x, y = self:convertPixelToMapCoord(x, y)
    return self:mappressed(x, y, b)
end

function Map:mousereleased(x, y, b)
    x, y = self:convertPixelToMapCoord(x, y)
    return self:mapreleased(x, y, b)
end

function Map:mousemoved(x, y, dx, dy, istouch)
    x, y = self:convertPixelToMapCoord(x, y)
    return self:mapmoved(x, y, dx, dy, istouch)
end

function Map:keypressed(key)
    if Selector:keypressed(key) then
        return true
    end

    if key == "up" then
        self.offset_y = self.offset_y + self.sti.hexsidelength
    elseif key == "down" then
        self.offset_y = self.offset_y - self.sti.hexsidelength
    elseif key == "left" then
        self.offset_x = self.offset_x + self.sti.hexsidelength
    elseif key == "right" then
        self.offset_x = self.offset_x - self.sti.hexsidelength
    elseif key == "p" then
            self.show_path = not self.show_path
    elseif key == "v" then
        self.show_visited = not self.show_visited
    elseif key == "n" then
        self.show_neighbours = not self.show_neighbours
    elseif key == "c" then
        self.show_cursor = not self.show_cursor
    elseif key == "delete" then
        -- delete selected object
        for i = #Selector.selected_units, 1, -1 do
            local unit = Selector.selected_units[i]
            unit:destroy()
            table.remove(Selector.selected_units)
        end
    end
end

return Map
