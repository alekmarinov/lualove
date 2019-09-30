local love = require "love"
local boot = require "love.boot"

love.boot = function()
    -- initializing love file system
    require("love.filesystem")
    arg = arg or {
        [0] = './'
    }
    love.filesystem.init(arg[0])

    local scriptdir = arg[0]:match("(.*/)")
    love.filesystem.setSource(scriptdir)
end

love.loop = function()
    local co = coroutine.create(boot)
    while coroutine.resume(co) do
        -- print("tick")
    end
end

return love
