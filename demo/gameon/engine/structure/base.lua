local Sprite = require "gameon.engine.sprite"
local Game = require "gameon.game"

local StructureBase = {
    _NAME = "StructureBase"
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

function StructureBase:setOpacity(opacity)
    self.flag:setOpacity(opacity)
end

return StructureBase
