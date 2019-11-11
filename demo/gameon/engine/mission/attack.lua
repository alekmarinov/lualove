
local thispackage = (...):match("(.-)[^%.]+$")
local MissionMove = require (thispackage..".move")
local HexMap = require ("gameon.engine.algo.hexmap")
local Animation = require "gameon.engine.animation"

local MissionAttack = setmetatable({
    _NAME = "MissionAttack"
}, MissionMove)
MissionAttack.__index = MissionAttack

function MissionAttack.new(unit, otherUnit)
    local tileto = unit.map:getTileOfUnit(otherUnit)
    local o = setmetatable(MissionMove.new(unit, tileto), MissionAttack)
    o.otherUnit = otherUnit
    o.map = unit.map
    o.attackTo = { x = 0, y = 0 }
    return o
end

function MissionAttack:update(dt)
    local otherUnitTile = self.map:getTileOfUnit(self.otherUnit)
    if not otherUnitTile or otherUnitTile ~= self.tileto then
        self.tileto = otherUnitTile
        -- delete all steps to find new route quickly
        for i = 1, #self.movesteps do
            self.movesteps[i] = nil
        end
    end
    if not self.tileto then
        -- the target unit disappeared
        print(self.unit, "The target unit disappeared, alive = ", self.otherUnit:isAlive())
        self:abort(true)
        return true
    end
    local currentTile = self.unit:getCurrentTile()
    if HexMap.offset_distance(currentTile, self.tileto) == 1 then
        -- FIXME: Implement method look toward tile
        local from_x, from_y = self.unit:getPositionAtTile(currentTile)
        local attack_x, attack_y = self.otherUnit:getPositionAtTile(self.tileto)
        if from_x ~= attack_x then
            self.unit.flipped = attack_x < from_x
        end
        if self.unit.action ~= "Attacking" then
            self.unit:setAction("Attacking")
        end
    else
        if MissionMove.update(self, dt) then
            -- move mission has been aborted
        end
    end
    return false
end

function MissionAttack:onFrameChanged(cycle, prevFrame, nextFrame)
    if self.unit.action == "Attacking" then
        if not self.attackAtCycle or self.attackAtCycle ~= cycle then
            local attack_hit_frame = self.unit.spriteSheet.frames[self.unit.action].attack_hit_frame
            if prevFrame <= attack_hit_frame and nextFrame >= attack_hit_frame then
                self.attackAtCycle = cycle
                -- check if enemy is in range and get some blood
                local otherUnitTile = self.map:getTileOfUnit(self.otherUnit)
                if HexMap.offset_distance(self.unit:getCurrentTile(), otherUnitTile) == 1 then
                    self.otherUnit:hit(self.unit)
                else
                    self.otherUnit:miss(self.unit)
                end
            end
        end
    end
end

function MissionAttack:abort(completed)
    MissionMove.abort(self, completed)
end

function MissionAttack:isCompleted()
    return self.otherUnit:isAlive()
end

function MissionAttack:showHideFlag(showing)
    -- not showing flags when attacking unit
end

return MissionAttack
