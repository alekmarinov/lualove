local Sprite = require "gameon.engine.sprite"
local Game = require "gameon.game"

local Archer = require "gameon.engine.unit.archer"
local Doctor = require "gameon.engine.unit.doctor"
local Horseman = require "gameon.engine.unit.horseman"
local Spearman = require "gameon.engine.unit.spearman"
local Swordsman = require "gameon.engine.unit.swordsman"
local Wizard = require "gameon.engine.unit.wizard"

local StructureBase = {
    _NAME = "StructureBase",
    building = {},
    BIRTH_RATE = 0,
    menpower_time = 0
}
StructureBase.__index = StructureBase

function StructureBase.new(options)
    assert(options.tile, "tile options is mandatory")
    return setmetatable(options, StructureBase)
end

function StructureBase:setPlayer(player)
    self.player = player
    if self.flag then
        self.flag:destroy()
    end
    self.flag = Sprite.new{
        color = self.player.color,
        type = "flag",
        scale_x = 0.5,
        scale_y = 0.5
    }
    self.player.map:spawnSprite(self.flag, self.tile)
end

function StructureBase:isAllied()
    return self.player.team == Game.currentPlayer.team
end

function StructureBase:isFriendly(unit)
    return self.player.team == unit.player.team
end

function StructureBase:setOpacity(opacity)
    self.flag:setOpacity(opacity)
end

function StructureBase:update(dt)
    self.menpower_time = self.menpower_time + dt
    if self.menpower_time >= self.BIRTH_RATE then
        self.player:addManpower(1)
        self.menpower_time = 0
    end
end

function StructureBase:keypressed(key)
    if key == "a" and self.building.archer then
        self.player:build(Archer, self.tile)
        return true
    elseif key == "p" and self.building.spearman then
        self.player:build(Spearman, self.tile)
        return true
    elseif key == "s" and self.building.swordsman then
        self.player:build(Swordsman, self.tile)
        return true
    elseif key == "h" and self.building.horseman then
        self.player:build(Horseman, self.tile)
        return true
    elseif key == "w" and self.building.wizard then
        self.player:build(Wizard, self.tile)
        return true
    end
    return false
end

return StructureBase
