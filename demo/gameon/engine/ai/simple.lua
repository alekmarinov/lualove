
local Archer = require "gameon.engine.unit.archer"
local Doctor = require "gameon.engine.unit.doctor"
local Horseman = require "gameon.engine.unit.horseman"
local Spearman = require "gameon.engine.unit.spearman"
local Swordsman = require "gameon.engine.unit.swordsman"
local Wizard = require "gameon.engine.unit.wizard"

local SimpleAI = {}
SimpleAI.__index = SimpleAI

function SimpleAI.new(options)
    assert(options.player, "player option is mandatory")
    return setmetatable(options, SimpleAI)
end

function SimpleAI:update(dt)
    if not self.player.game.currentPlayer then
        return 
    end
    if #self.player.structures > 0 then
        if self.player.resources.menpower > 0 and self.player.resources.gold > Archer.gold then
            local structure = self.player.structures[1]
            local archer = self.player:build(Archer, structure.tile)
            if archer then
                if #self.player.game.currentPlayer.structures > 0 then
                    local tile = self.player.game.currentPlayer.structures[1].tile
                    local x, y = self.player.map:convertTileToPixel(tile.x, tile.y)
                    archer:attackTo(x, y)
                end
            end
        end
    end
end

return SimpleAI
