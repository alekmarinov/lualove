local plpath = require "pl.path"

local Util = {}

Util.splitext = plpath.splitext
Util.basename = plpath.basename
Util.join = plpath.join
Util.dirname = plpath.dirname
Util.splitpath = plpath.splitpath


function Util.loadconfig(luafile)
    local config = {}
    local f, err = love.filesystem.load(luafile)
    if not f then
        return nil, err
    end
    setfenv(f, config)
    f()
    return config
end

return Util
