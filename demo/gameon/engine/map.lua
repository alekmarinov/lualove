--- Map module
-- @module gameon.engine.Map

local thispackage = (...):match("(.-)[^%.]+$")

local pltablex = require "pl.tablex"
local sti = require "sti"
local Animation = require (thispackage..".animation")
local SpriteSheet = require (thispackage..".spritesheet")
local Sprite = require (thispackage..".sprite")
local Unit = require (thispackage..".unit")
local Draw = require (thispackage..".draw")

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
        offset_y = 0,
        scrollto_x = 0 ,
        scrollto_y = 0,
        scrollfrom_x = 0,
        scrollfrom_y = 0
    }, Map)
    o.sti = sti(params.mapfile)
    local layer = o.sti:addCustomLayer("Sprites", 2)

    for _, spritesheetfile in ipairs(params.spritesheets or {}) do
        local spritesheet = SpriteSheet.load(spritesheetfile)
        table.insert(o.spritesheets, spritesheet)
        o.spritesheets[spritesheet.name] = spritesheet
    end

    -- Draw Sprites layer
    layer.draw = function(self)
        -- draw sprites
        for _, spritesheet in ipairs(o.spritesheets) do
            spritesheet:draw()
        end

        -- draw cursor
        if o.cursor then
            local px, py = o.sti:convertTileToPixel(o.cursor.x, o.cursor.y)
            love.graphics.setColor(o.color_cursor)
            Draw.hexagon(px, py, o.sti.hexsidelength)
        end
    end

    return o
end

function Map:tileinfoat(tx, ty, default)
    self.tilesinfo[ty] = self.tilesinfo[ty] or {}
    self.tilesinfo[ty][tx] = self.tilesinfo[ty][tx] or default
    return self.tilesinfo[ty][tx]
end

function Map:getUnitPixelCoords(unit, tx, ty)
    local spritesheet = self.spritesheets[unit.typename]
    local x, y = self.sti:convertTileToPixel(tx, ty)
    x = x - spritesheet.max_width / 2
    y = y - spritesheet.max_height / 2
    return x, y
end

function Map:moveunit(unit, tx, ty)
    -- remove unit from current tile
    local tile = self:tileinfoat(unit.tx, unit.ty, {})
    local idx = pltablex.find(tile.units or {}, unit)
    if idx then
        table.remove(tile.units, idx)
    end

    -- add unit to the new tile
    tile = self:tileinfoat(tx, ty, {})
    tile.units = tile.units or {}
    table.insert(tile.units, unit)

    unit.tx, unit.ty = tx, ty
    local px, py = self:getUnitPixelCoords(unit, tx, ty)
    unit:moveto(px, py)
end

function Map:spawnunit(unit, tx, ty)
    local spritesheet = self.spritesheets[unit.typename]
    unit.x, unit.y = self:getUnitPixelCoords(unit, tx, ty)   
    unit.tx, unit.ty = tx, ty
    spritesheet:createSprite(unit)

    -- add unit to tile
    local tile = self:tileinfoat(tx, ty, {})
    tile.units = tile.units or {}
    table.insert(tile.units, unit)
end

function Map:setcursor(x, y)
    -- set cursor
    self.cursor = self.cursor or {}
    self.cursor.x = x
    self.cursor.y = y

    -- select the first unit on tile
    local tile = self:tileinfoat(x, y)
    local unit = tile and tile.units and tile.units[1]
    if unit then
        self:selectunit(unit)
    end
end

function Map:unsetcursor()
    self.cursor = nil
    self.selected_unit = nil
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

function Map:mousepressed(x, y, b)
    if b == 1 then
        -- select tile 
        local tile_x, tile_y = self.sti:convertPixelToTile(x / self.zoom - self.offset_x, y / self.zoom - self.offset_y)
        self:setcursor(tile_x, tile_y)

        -- center the selected tile
        local tile_px, tile_py = self.sti:convertTileToPixel(tile_x, tile_y)
        local tile_px, tile_py = tile_px + self.offset_x, tile_py + self.offset_y

        -- centering the selected tile by smooth scroll the map
        self.animation = Animation.new{
            duration = self.scrolltime,
            varlist = { "offset_x", "offset_y" },
            varsto = {
                offset_x = self.offset_x + love.graphics.getWidth() / 2 / self.zoom - tile_px,
                offset_y = self.offset_y + love.graphics.getHeight() / 2 / self.zoom - tile_py
            },
            object = self,
            callback_finished = function()
                self.animation = nil
            end
        }
    elseif b == 2 then
        if self.selected_unit then
            local tile_x, tile_y = self.sti:convertPixelToTile(x / self.zoom - self.offset_x, y / self.zoom - self.offset_y)
            self:setcursor(tile_x, tile_y)
            self:moveunit(self.selected_unit, tile_x, tile_y)
        end
    end
end

function Map:mousemoved(x, y, dx, dy, istouch)
end

function Map:keypressed(key)
    if key == "escape" then
        if self.cursor then
            self:unsetcursor()
            return true
        end
    end
end

return Map
