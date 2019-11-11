local pltablex = require "pl.tablex"
local thispackage = (...):match("(.-)[^%.]+$")
local MissionMove = require (thispackage..".move")
local Sprite = require "gameon.engine.sprite"
local DrawableText = require "gameon.engine.drawable.text"

local MissionPatrol = setmetatable({
    _NAME = "MissionPatrol",
}, MissionMove)
MissionPatrol.__index = MissionPatrol

function MissionPatrol.new(unit, tileto)
    local o = setmetatable(MissionMove.new(unit, tileto), MissionPatrol)
    o.patrolTiles = { tileto }
    o.currentPatrolTile = 1
    o.map = unit.map
    o.flagSprites = {}
    o.flagDrawables = {}
    return o
end

function MissionPatrol:togglePatrolTile(tile)
    self:showHideFlags(false)
    local idx = pltablex.find(self.patrolTiles, tile)
    if idx then
        if idx == self.currentPatrolTile then
            self.currentPatrolTile = self.currentPatrolTile - 1
            self:abort(true)
        end
        table.remove(self.patrolTiles, idx)
    else
        table.insert(self.patrolTiles, tile)
    end
    if self.unit:isSelected() then
        self:showHideFlags(true)
    end
end

function MissionPatrol:update(dt)
    if MissionMove.update(self, dt) then
        self.completed = false
        -- move mission finished, go to next patrol tile
        print(self.unit, "Patrol tile "..self.currentPatrolTile.." reached, go to next", #self.patrolTiles)
        if #self.patrolTiles <= 1 then
            self:abort()
            return true
        else
            self.currentPatrolTile = self.currentPatrolTile + 1
            if self.currentPatrolTile > #self.patrolTiles then
                self.currentPatrolTile = 1
            end
            self.tileto = self.patrolTiles[self.currentPatrolTile]
        end
    end
    return false
end

function MissionPatrol:abort(completed)
    MissionMove.abort(self, completed)
    -- completed is true when MissionMove reaches the current destination
    -- we hide the flags if abort was not called by MissionMove
    if not completed then
        self:showHideFlags(false)
    end
end

function MissionPatrol:isCompleted()
    -- patrol mission never completes
    return false
end

function MissionPatrol:onSelected(selected)
    self:showHideFlags(selected)
end

function MissionPatrol:showHideFlags(showing)
    if showing then
        if #self.flagSprites == 0 then
            for i, tile in ipairs(self.patrolTiles) do
                local flag = Sprite.new{
                    color = self.unit.color,
                    typename = "flag"
                }
                self.unit.map:spawnSprite(flag, tile.x, tile.y)
                table.insert(self.flagSprites, flag)

                local x, y = self.unit.map:convertTileToPixel(tile.x, tile.y)
                local text = DrawableText.new{
                    text = tostring(i),
                    x = x,
                    y = y
                }
                self.unit.map:addDrawable(text)
                table.insert(self.flagDrawables, text)
            end
        end
    else
        if #self.flagSprites > 0 then
            for i = #self.flagSprites, 1, -1 do
                local flag = self.flagSprites[i]
                flag:destroy()
                self.flagSprites[i] = nil
            end
            for i = #self.flagDrawables, 1, -1 do
                local text = self.flagDrawables[i]
                self.unit.map:removeDrawable(text)
                self.flagDrawables[i] = nil
            end
        end
    end
end

return MissionPatrol
