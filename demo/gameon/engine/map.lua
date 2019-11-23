--- Map module
-- @module gameon.engine.Map

local thispackage = (...):match("(.-)[^%.]+$")

local pltablex = require "pl.tablex"
local sti = require "sti"
local Animation = require (thispackage..".animation")
local DrawableText = require (thispackage..".drawable.text")
local AStar = require (thispackage..".algo.astar")
local HexMap = require (thispackage..".algo.hexmap")
local SpriteSheet = require (thispackage..".spritesheet")
local Sprite = require (thispackage..".sprite")
local Unit = require (thispackage..".unit")
local Draw = require (thispackage..".draw")
local Paint = require (thispackage..".paint")
local Selector = require (thispackage..".selector")
local Game = require "gameon.game"
local PLAYER_COLOR = require (thispackage..".enums").PLAYER_COLOR

local Archer = require (thispackage..".unit.archer")
local Doctor = require (thispackage..".unit.doctor")
local Horseman = require (thispackage..".unit.horseman")
local Spearman = require (thispackage..".unit.spearman")
local Swordsman = require (thispackage..".unit.swordsman")
local Wizard = require (thispackage..".unit.wizard")

local Castle = require (thispackage..".structure.castle")
local Camp = require (thispackage..".structure.camp")

--- Base Map table
-- @table Map
local Map = {
    color_background = {0, 0, 0, 1},
    color_cursor = {1, 1, 1, 1},
    zoom_step = 0.1,
    offset_x = 0,
    offset_y = 0,
    zoom = 1,
    scrolltime = 0.5,
    visibility_masks = {
        visible = {1, 1, 1, 1},
        invisible = {0, 0, 0, 1},
        semivisible = {0.7, 0.7, 0.7, 1},
    }
}
Map.__index = Map

function Map.load(params)
    local o = setmetatable({
        spritesheets = {},
        images = {},
        tiles = {},
        offset_x = 0,
        offset_y = 0,
        debug_selected_tiles = {},
        enable_fog = false,
        drawables = {},
        cross = nil,
        debug = true
    }, Map)

    Selector.map = o

    o.sti = sti(params.mapfile)

    -- create map tiles
    for j = 1, o.sti.layers["Ground"].height do
        o.tiles[j] = {}
        for i = 1, o.sti.layers["Ground"].width do
            o.tiles[j][i] = {
                x = i,
                y = j
            }
            if o.enable_fog then
                o:setTileVisibility(j, i, "invisible")
            end
        end
    end

    -- create spritesheets
    local paint = Paint.new()
    for spritesheetfile, colors in pairs(params.spritesheets or {}) do
        local spritesheet = SpriteSheet.load(paint, spritesheetfile, o:getHexSideLength())
        for _, color in ipairs(colors) do
            spritesheet:createForColor(color)
        end
        table.insert(o.spritesheets, spritesheet)
        o.spritesheets[spritesheet.name] = spritesheet
    end

    -- create images
    for name, imagefile in pairs(params.images or {}) do
        o.images[name] = love.graphics.newImage(imagefile)
    end

    -- Draw Sprites layer
    local layer = o.sti:addCustomLayer("Sprites")
    layer.draw = function(self)

        Selector:drawSelectedItems()

        -- draw sprites
        for _, spritesheet in ipairs(o.spritesheets) do
            -- for _, sprite in ipairs(spritesheet.sprites.MAGENTA or {}) do
            --     local frameinfo = spritesheet.frames[sprite.action][sprite.frame_index].frame
            --     local endpt = {
            --         x = sprite.x + frameinfo.w,
            --         y = sprite.y + frameinfo.h
            --     }
            --     Draw.dashrect(sprite, endpt, 3, 3)
                -- love.graphics.setColor(1, 1, 1, 1)
                -- love.graphics.setLineWidth(1)
                -- love.graphics.setLineStyle("rough")
                -- love.graphics.ellipse( "line", sprite.x + frameinfo.w / 2, sprite.y + frameinfo.h - o.sti.hexsidelength / 4, o.sti.hexsidelength, o.sti.hexsidelength / 2)
            -- end
            spritesheet:draw()
        end

        -- draw drawables
        for _, drawable in ipairs(o.drawables) do
            drawable:draw()
        end

        -- draw visited nodes
        if o.debug and #o.debug_selected_tiles > 0 then
            for _, tile in ipairs(o.debug_selected_tiles) do
                local px, py = o.sti:convertTileToPixel(tile.x, tile.y)
                love.graphics.setColor(1, 0, 0, 1)
                Draw.hexagon(px, py, o.sti.hexsidelength)
            end
        end

        -- draw selected path
        if o.debug and o.debug_path then
            for i, node in ipairs(o.debug_path) do
                local px, py = o.sti:convertTileToPixel(node.x, node.y)
                love.graphics.setColor(1, 1, 1, 1)
                Draw.hexagon(px, py, o.sti.hexsidelength)
                love.graphics.printf(string.format("%d", i), px - o.sti.hexsidelength, py - o.sti.hexsidelength/2, 2 * o.sti.hexsidelength, "center")
            end
        end

        -- draw neighbours
        -- if o.show_neighbours and o.neighbours then
        --     for i, node in ipairs(o.neighbours) do
        --         local px, py = o.sti:convertTileToPixel(node.x, node.y)
        --         love.graphics.setColor(1, 0, 0, 1)
        --         Draw.hexagon(px, py, o.sti.hexsidelength)
        --         love.graphics.printf(string.format("%d", i), px - o.sti.hexsidelength, py - o.sti.hexsidelength/2, 2 * o.sti.hexsidelength, "center")
        --     end
        -- end

        if o.debug and o.cross then
            love.graphics.setColor(1, 1, 1, 1)
            Draw.hexagon(o.cross.x, o.cross.y, o.sti.hexsidelength)
            love.graphics.setColor(1, 0, 0, 1)
            Draw.cross(o.cross, o.sti.hexsidelength / 2)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf(string.format("%d %d", o.cross.tx, o.cross.ty), o.cross.x - o.sti.hexsidelength, o.cross.y - o.sti.hexsidelength/2, 2 * o.sti.hexsidelength, "center")
        end

        Selector:draw()
    end

    o.astar = AStar.new{
        callback_distance = HexMap.offset_distance,
        callback_cost = function(node1, node2)
            local props = o:getTileProperties(node2)
            return tonumber(props.move_points)
        end
    }

    Game.currentPlayer.map = o

    -- Process map objects
    for _, object in ipairs(o.sti.layers.Objects.objects) do
        local tile = o:getTileAt(o:convertPixelToTile(object.x, object.y))
        if object.name == "Player" then
            local player = Game:getPlayers{race = object.type}[1]
            if not player then
                player = Game:createPlayer{
                    type = "AI",
                    race = object.type,
                    map = o
                }
            end
            local castle = Castle.new{ tile = tile }
            player:addStructure(castle)
            o:setStructureToTile(castle, tile)
        elseif object.type == "Unit" then
                local unitclasses = {
                Archer = Archer,
                Doctor = Doctor,
                Horseman = Horseman,
                Spearman = Spearman,
                Swordsman = Swordsman,
                Wizard = Wizard
            }

            if not Game.neutralPlayer then
                -- Create the neutral player
                Game:createNeutralPlayer{ map = o }
            end
            o:spawnSprite(unitclasses[object.name].new{ player = Game.neutralPlayer }, tile)
        elseif object.type == "Camp" then
            local camp = Camp.new{ tile = tile }
            if object.name == "Horsemen" then
                camp.building.horseman = true
            elseif object.name == "Wizards" then
                camp.building.wizard = true
            else
                assert(nil, "Camp "..object.name.." is not supported")
            end
            Game.neutralPlayer:addStructure(camp)
            o:setStructureToTile(camp, tile)
        end
    end

    return o
end

function Map:reserveTileForUnit(unit, tile)
    tile.reservedBy = unit
end

function Map:unreserveTileFromUnit(unit, tile)
    tile.reservedBy = nil
end

function Map:getTileReservedBy(tile)
    return tile.reservedBy
end

function Map:isTileReserved(tile)
    return tile.reservedBy ~= nil
end

function Map:neighboursIterator(unit, tile, callback_is_tile_walkable)
    local nextiter = HexMap.neighbours(tile)
    return function()
        local i, next, tile
        repeat
            i, nx, ny = nextiter()
            if nx then
                tile = self:getTileAt(nx, ny)
                if tile and (not unit:canStepOnTile(tile) or not callback_is_tile_walkable(tile)) then
                    tile = nil
                end
            end
        until not nx or tile
        return tile
    end
end

function Map:findPath(options)
    local unit = options.unit
    local start = options.start
    local stop =  options.stop
    local isfast = options.isfast
    local callback_is_tile_walkable = options.callback_is_tile_walkable
    
    self.debug_selected_tiles = {}
    local path = self.astar:find(start, stop, {
        callback_neighbours = function (node)
            return self:neighboursIterator(unit, node, callback_is_tile_walkable)
        end,
        depth_limit = isfast and AStar.DEPTH_LIMIT_FAST or AStar.DEPTH_LIMIT,
        callback_visited = function(next, priority)
            table.insert(self.debug_selected_tiles, next)
        end
    }) or {}
    if not unit:canStepOnTile(stop) or not callback_is_tile_walkable(stop) then
        -- remove stop point as it's not walkable
        table.remove(path)
    end
    self.debug_path = path
    return path
end

function Map:getTileMovingPoints(tile)
    local props = self:getTileProperties(tile)
    return tonumber(props.move_points)
end

function Map:getUnitAtTile(tile)
    return tile.units and tile.units[1] and tile.units[1]:isAlive() and tile.units[1]
end

function Map:getTileOfUnit(unit)
    local tile = unit.tile
    tile = tile and tile.units and pltablex.find(tile.units, unit) and tile
    return tile
end

function Map:enemiesInRange(unit)
    local center = unit.tile

    return coroutine.wrap(function()
        for x, y in HexMap.range(center, unit.range) do
            local tile = self:getTileAt(x, y)
            if tile and tile.units then
                for _, aunit in ipairs(tile.units) do
                    if not unit:isFriendly(aunit) and aunit:isAlive() then
                        coroutine.yield(aunit)
                    end
                end
            end
        end
    end)
end

function Map:getHexSideLength()
    return self.sti.hexsidelength
end

function Map:getTileAt(tx, ty)
    if self.tiles[ty] then
        return self.tiles[ty][tx]
    end
end

function Map:getTileProperties(tile)
    return self.sti:getTileProperties("Ground", tile.x, tile.y)
end

function Map:getTileAtPixel(x, y)
    local tx, ty = self:convertPixelToTile(x, y)
    return self:getTileAt(tx, ty)
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

    if unit:isAllied() then
        self:enlightTile(tile.x, tile.y, false)
    end
end

function Map:addUnitToTile(unit, tile)
    tile.units = tile.units or {}
    assert(not pltablex.find(tile.units, unit))
    table.insert(tile.units, unit)

    if unit:isAllied() then
        self:enlightTile(tile.x, tile.y, true)
    else
        if self.enable_fog and (not tile.visibility or tile.visibility == 0) then
            unit:setOpacity(1)
        else
            unit:setOpacity(0)
        end
    end
end

function Map:setStructureToTile(structure, tile)
    tile.structure = structure

    if structure:isAllied() then
        self:enlightTile(tile.x, tile.y, true)
    else
        if self.enable_fog and (not tile.visibility or tile.visibility == 0) then
            structure:setOpacity(1)
        else
            structure:setOpacity(0)
        end
    end
end

function Map:spawnSprite(sprite, tile)
    sprite.map = self
    local spritesheet = self.spritesheets[sprite.type]
    spritesheet:createSprite(sprite)
    sprite:setPos(sprite:getPositionAtTile(tile))
end

function Map:addDrawable(drawable)
    if not pltablex.find(self.drawables, drawable) then
        table.insert(self.drawables, drawable)
    end
end

function Map:removeDrawable(drawable)
    local idx = pltablex.find(self.drawables, drawable)
    if idx then
        table.remove(self.drawables, idx)
    end
end

function Map:draw()
    love.graphics.setBackgroundColor(self.color_background)
    self.sti:draw(self.offset_x, self.offset_y, self.zoom, self.zoom)
end

function Map:addFloatingTextAtTile(tile, text, color)
    local x, y = self:convertTileToPixel(tile.x, tile.y)
    local drtext = DrawableText.new{
        text = text,
        color = color,
        x = x,
        y = y
    }
    drtext.animation = Animation.new{
        duration = 1,
        fields = { "y" },
        varsto = { y = y - self:getHexSideLength() },
        object = drtext,
        callback_finished = function()
            self:removeDrawable(drtext)
        end
    }
    self:addDrawable(drtext)
end

function Map:throwObject(options)
    local unit1 = assert(options.unit1, "unit1 options is mandatory")
    local unit2 = assert(options.unit2, "unit2 options is mandatory")
    local drawable = assert(options.drawable, "drawable options is mandatory")

    local o1x, o1y = unit1:getOrigin()
    local o2x, o2y = unit1:getOrigin()
    local x1 = unit1.x + o1x
    local y1 = unit1.y + o1y
    local x2 = unit2.x + o2x
    local y2 = unit2.y + o2y

    local dy, dx = y2 - y1, x2 - x1
    drawable.x, drawable.y = x1, y1
    drawable.rotation = math.atan2( dy, dx )
    drawable.animation = Animation.new{
        duration = options.duration or 1,
        fields = { "x", "y" },
        varsto = { x = x2, y = y2 },
        object = drawable,
        callback_finished = function()
            self:removeDrawable(drawable)
            if options.callback then
                options.callback(unit1, unit2, drawable)
            end
        end
    }
    self:addDrawable(drawable)
end

function Map:enlightTile(x, y, enlight)
    if not self.enable_fog then
        return 
    end
    local tile = self:getTileAt(x, y)
    for tx, ty in HexMap.range(tile, 3, true) do
        local t = self:getTileAt(tx, ty)
        if t then
            local visibility = t.visibility or 0
            if enlight then
                visibility = visibility + 1
            else
                visibility = visibility - 1
                if visibility < 0 then
                    visibility = 0
                end
            end
            local visibility_changed = false
            if visibility >= 1 then
                if not t.visibility or t.visibility == 0 then
                    self:setTileVisibility(tx, ty, "visible")
                    visibility_changed = true
                end
            else
                if not t.visibility or t.visibility > 0 then
                    self:setTileVisibility(tx, ty, "semivisible")
                    visibility_changed = true
                end
            end
            t.visibility = visibility
            if visibility_changed then
                if t.units then
                    -- englight units
                    for _, unit in ipairs(t.units) do
                        if not unit:isAllied() then
                            if visibility > 0 then
                                unit:setOpacity(0)
                            else
                                unit:setOpacity(1)
                            end
                        end
                    end
                end
                if t.structure then
                    -- englight structures
                    if not t.structure:isAllied() then
                        if visibility > 0 then
                            t.structure:setOpacity(0)
                        else
                            t.structure:setOpacity(1)
                        end
                    end
                end
            end
        end
    end
end

function Map:setTileVisibility(x, y, visibility)
    local stile = self.sti.layers.Ground.data[y][x]
    local instance = self.sti.instances[y][x]
    if visibility == "invisible" then
        instance.batch:setColor(self.visibility_masks.invisible)
    elseif visibility == "semivisible" then
        instance.batch:setColor(self.visibility_masks.semivisible)
    else
        assert(visibility == "visible")
        instance.batch:setColor(self.visibility_masks.visible)
    end
    instance.batch:set(
        instance.id,
        stile.quad,
        instance.x,
        instance.y,
        stile.r,
        stile.sx,
        stile.sy
    )
    instance.batch:setColor(1, 1, 1, 1)
end

function Map:update(dt)
    self.sti:update(dt)

    -- update sprite animations
    for _, spritesheet in ipairs(self.spritesheets) do
        spritesheet:update(dt)
    end

    -- update sprite event boxes
    for _, spritesheet in ipairs(self.spritesheets) do
        spritesheet:updateEventBoxes(dt)
    end

    -- update drawable animations
    for _, drawable in ipairs(self.drawables) do
        drawable:update(dt)
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

function Map:tileAtCenter()
    local tile_x, tile_y = self:convertPixelToTile(
        love.graphics.getWidth() / 2 / self.zoom - self.offset_x,
        love.graphics.getHeight() / 2 / self.zoom - self.offset_y
    )
    return self:getTileAt(tile_x, tile_y)
end

function Map:centerAtTile(tile)
    if not tile then
        return
    end
    self.offset_x, self.offset_y = self:convertTileToPixel(tile.x, tile.y)
    self.offset_x, self.offset_y =
        love.graphics.getWidth() / 2 / self.zoom - self.offset_x,
        love.graphics.getHeight() / 2 / self.zoom - self.offset_y
end

function Map:smoothcentertile(tx, ty)
    -- centering the tile by smooth scroll the map
    local tile_px, tile_py = self.sti:convertTileToPixel(tx, ty)
    self.animation = Animation.new{
        duration = self.scrolltime,
        fields = { "offset_x", "offset_y" },
        varsto = {
            offset_x = love.graphics.getWidth() / 2 / self.zoom - tile_px,
            offset_y = love.graphics.getHeight() / 2 / self.zoom - tile_py
        },
        object = self,
        callback_finished = function()
            self.animation = nil
        end,
        callback_update = function (animation, offset_x, offset_y)
            self.offset_x, self.offset_y = offset_x, offset_y
        end
    }
end

function Map:convertPixelToMapCoord(x, y)
    return x / self.zoom - self.offset_x, y / self.zoom - self.offset_y
end

function Map:mappressed(x, y, b)
    if b == 1 then
        self.cross = {}
        self.cross.tx, self.cross.ty = self:convertPixelToTile(x, y)
        local tile = self:getTileAt(self.cross.tx, self.cross.ty)
        self.cross.x, self.cross.y = self:convertTileToPixel(self.cross.tx, self.cross.ty)

        self.debug_selected_tiles = {}
        if tile then
            for x, y in HexMap.range(tile, 3) do
                local tile = self:getTileAt(x, y)
                if tile then
                    table.insert(self.debug_selected_tiles, tile)
                end
            end
        end
    end

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
        self.debug_path = nil
        for unit in Selector:selectedUnits() do
            -- move unit
            if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
                unit:patrolTo(x, y)
            elseif love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") then
                unit:attackTo(x, y)
            else
                unit:moveTo(x, y)
            end
        end
    elseif b == 3 then
        if not Game.currentPlayer then
        end
        local tile_x, tile_y = self:convertPixelToTile(x, y)
        local sprites = {Doctor, Horseman, Archer, Spearman, Swordsman, Wizard}
        local idx = math.random(2)
        local sprite = sprites[idx]
        local tile = self:getTileAt(tile_x, tile_y)
        if tile then
            map:spawnSprite(Horseman.new{player = Game.currentPlayer}, tile)
        end
    end
end

function Map:mapreleased(x, y, b)
    if Selector:mapreleased(x, y, b) then

        if self.debug then
            if Selector:selectedUnitsCount() == 1 then
                local unit = Selector:selectedUnits()()
                local text = unit.mission._NAME
                if unit.mission._NAME == "MissionMove" then
                    text = text.." "..unit.mission.state._NAME
                end
                self:addFloatingTextAtTile(unit.tile, text, PLAYER_COLOR[unit.color])
            end
        end

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
    elseif key == "home" then
        if not Game.currentPlayer then
            return
        end
        local tile = self:tileAtCenter()
        local selected_structure = Game.currentPlayer.structures[1]
        for i, structure in ipairs(Game.currentPlayer.structures) do
            if tile == structure.tile then
                if i == #Game.currentPlayer.structures then
                    i = 1
                else
                    i = i + 1
                end
                selected_structure = Game.currentPlayer.structures[i]
                break
            end
        end
        if selected_structure then
            self:centerAtTile(selected_structure.tile)
            Selector:selectStructure(selected_structure)
        end
    elseif key == "d" then
        self.debug = not self.debug
    elseif key == "f" then
        if self.enable_fog then
            -- enligh all tiles
            for j = 1, #self.tiles do
                for i = 1, #self.tiles[j] do
                    self:setTileVisibility(i, j, "visible")
                end
            end
        end
        self.enable_fog = not self.enable_fog
    elseif key == "delete" then
        -- delete selected object
        for unit in Selector:selectedUnits() do
            unit:destroy()
        end
        Selector:clearSelection()
    end
end

return Map
