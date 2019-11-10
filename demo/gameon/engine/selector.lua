--- Selector module
-- @module gameon.engine.Selector

local thispackage = (...):match("(.-)[^%.]+$")
local Draw = require (thispackage..".draw")
local Game = require ("gameon.game")

--- Base Selector table
-- @table Selector
local Selector = {
    selected_units = {},
    drag_from = nil,
    drag_to = nil,
    selection_dash_size = 2,
    selection_gap_size = 2,
    selection_line_style = "rough",
    selection_line_width = 1,
    selection_line_color = {1, 1, 1, 1},
    selected_unit_line_style = "smooth",
    selected_unit_line_color = {1, 1, 1, 1},
    selected_unit_line_width = 1
}
Selector.__index = Selector

function Selector:collect_selected_units()
    assert(self.drag_from, "Missing selected area")

    self.selected_units = {}
    local tile_from_tx, tile_from_ty = Game.map:convertPixelToTile(self.drag_from.x, self.drag_from.y)
    local tile_to_tx, tile_to_ty = Game.map:convertPixelToTile(self.drag_to.x, self.drag_to.y)
    if tile_from_tx > tile_to_tx then
        tile_from_tx, tile_to_tx = tile_to_tx, tile_from_tx
    end
    if tile_from_ty > tile_to_ty then
        tile_from_ty, tile_to_ty = tile_to_ty, tile_from_ty
    end
    for tx = tile_from_tx, tile_to_tx do
        for ty = tile_from_ty, tile_to_ty do
            local tileInfo = Game.map:getTileAt(tx, ty)
            if tileInfo and tileInfo.units then
                for _, unit in ipairs(tileInfo.units) do
                    if unit.player == Game.currentPlayer then
                        table.insert(self.selected_units, unit)
                    end
                end
            end
        end
    end
end

function Selector:reset()
    self.drag_from = nil
    self.drag_to = nil
end

function Selector:mappressed(x, y, b)
    if b ~= 1 then
        return false
    end
    self:reset()
    self.drag_from = {x = x, y = y}
    self.drag_to = {x = x, y = y}
    self.selected_units = {}
    return true
end

function Selector:mapreleased(x, y, b)
    if self.drag_from and self.drag_from then
        -- check what is selected
        self:collect_selected_units()
        self:reset()
    end
end

function Selector:mapmoved(x, y, dx, dy, istouch)
    if self.drag_from then
        self.drag_to.x = x
        self.drag_to.y = y
    end
end

function Selector:keypressed(key)
    if not self.drag_from then
        return false
    end
    if key == "escape" then
        self:reset()
        return true
    end
end

function Selector:drawSelectedItems()
    if #self.selected_units > 0 then
        love.graphics.push("all")
        love.graphics.setColor(self.selected_unit_line_color)
        love.graphics.setLineWidth(self.selected_unit_line_width)
        love.graphics.setLineStyle(self.selected_unit_line_style)
        for _, unit in ipairs(self.selected_units) do
            local frameinfo = unit.spriteSheet.frames[unit.action][unit.frame_index].frame
            Draw.dashrect(
                unit,
                { x = unit.x + frameinfo.w - 1, y = unit.y + frameinfo.h - 1},
                self.selection_dash_size,
                self.selection_gap_size
            )

            -- love.graphics.ellipse("line", 
            --     unit.x + frameinfo.w / 2,
            --     unit.y + frameinfo.h - map:getHexSideLength() / 4, 
            --     map:getHexSideLength(),
            --     map:getHexSideLength() / 2)
        end
        love.graphics.pop()
    end
end

function Selector:draw()
    if self.drag_from then
        -- draw selection rectangle
        love.graphics.push("all")
        love.graphics.setColor(self.selection_line_color)
        love.graphics.setLineWidth(self.selection_line_width)
        love.graphics.setLineStyle(self.selection_line_style)
        Draw.dashrect(
            self.drag_from,
            self.drag_to,
            self.selection_dash_size,
            self.selection_gap_size
        )
        love.graphics.pop()
    end
end

return Selector
