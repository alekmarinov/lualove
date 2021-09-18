local love = require "love"
local boot = require "love.boot"

-- In case the environment don't provide arg
arg = arg or {
    [0] = './'
}

love.boot = function()
    -- initializing love file system
    require("love.filesystem")
    love.filesystem.init(arg[0] or '.')
    love.filesystem.setSource(arg[0]:match("(.*/)") or ".")
end

local loveco = coroutine.create(boot)
-- initializes love, calls boot.lua:earlyinit
coroutine.resume(loveco)

love.loop = function()
    -- love.load was not defined at time of earlyinit so calling it now
    if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

    -- let the game begin
    while coroutine.resume(loveco) do
    end
end

return love
