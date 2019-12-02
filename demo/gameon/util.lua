local Util = {}

local sub = string.sub

local function at(s,i)
    return sub(s,i,i)
end

function Util.splitext(P)
    local i = #P
    local ch = at(P,i)
    while i > 0 and ch ~= '.' do
        if ch == '/' then
            return P,''
        end
        i = i - 1
        ch = at(P,i)
    end
    if i == 0 then
        return P,''
    else
        return sub(P,1,i-1),sub(P,i)
    end
end

function Util.splitpath(P)
    local i = #P
    local ch = at(P,i)
    while i > 0 and ch ~= '/' do
        i = i - 1
        ch = at(P,i)
    end
    if i == 0 then
        return '',P
    else
        return sub(P,1,i-1), sub(P,i+1)
    end
end

function Util.basename(P)
    local _,p2 = Util.splitpath(P)
    return p2
end

function Util.isabs(P)
    return at(P,1) == '/'
end

function Util.join(p1,p2,...)
    if select('#',...) > 0 then
        local p = Util.join(p1,p2)
        local args = {...}
        for i = 1,#args do
            p = Util.join(p,args[i])
        end
        return p
    end
    if Util.isabs(p2) then return p2 end
    local endc = at(p1,#p1)
    if endc ~= '/' and endc ~= "" then
        p1 = p1..'/'
    end
    return p1..p2
end

function Util.dirname(P)
    local p1 = Util.splitpath(P)
    return p1
end

function Util.find(t,val,idx)
    idx = idx or 1
    if idx < 0 then idx = #t + idx + 1 end
    for i = idx,#t do
        if t[i] == val then return i end
    end
    return nil
end

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
