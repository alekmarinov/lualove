local love = require "love"
local boot = require "love.boot"
local lfs = require "lfs"

love.boot = function()
    -- getting full path to script directory
    local sep = '/'
    local currentdir = lfs.currentdir()
    if string.sub(currentdir, 1, 1) ~= '/' then
        sep = '\\'
    end
    local function dirname(str)
        return str:match("(.*"..sep..")")
    end
    lfs.chdir(dirname(arg[0]))
    local scriptdir = lfs.currentdir()
    lfs.chdir(currentdir)

    -- initializing love file system
    require("love.filesystem")
    love.filesystem.init(arg[0])
    love.filesystem.setSource(scriptdir)
end

love.loop = function()
    local co = coroutine.create(boot)
    while coroutine.resume(co) do
        -- print("tick")
    end
end

return love
