local Util = require "gameon.util"

local Cursor = {
    cursorNames = {
        "arrow",
        "attack",
        "protect"
    }
}

function Cursor:load(cursorsdir)
    self.cursor = {}
    for _, cursorname in ipairs(self.cursorNames) do
        local cursorfile = Util.join(cursorsdir, cursorname..".lua")
        local config = assert(Util.loadconfig(cursorfile))
        local imagename = Util.join(cursorsdir, config.file)
        self.cursor[cursorname] = love.mouse.newCursor(imagename, config.x, config.y)
    end
    self:setArrow()
end

function Cursor:setArrow()
    love.mouse.setCursor(self.cursor.arrow)
end

function Cursor:setAttack()
    love.mouse.setCursor(self.cursor.attack)
end

function Cursor:setProtect()
    love.mouse.setCursor(self.cursor.protect)
end

return Cursor
