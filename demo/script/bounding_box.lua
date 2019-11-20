local plpath = require "pl.path"
local love = require "love-portable"
local unpack = unpack or table.unpack

function dirtree(dir)
    assert(dir and dir ~= "", "directory parameter is missing or empty")
    if string.sub(dir, -1) == "/" then
        dir = string.sub(dir, 1, -2)
    end

    local function yieldtree(dir)
        for entry in plpath.dir(dir) do
            if entry ~= "." and entry ~= ".." then
                entry = dir .. "/" .. entry
                local isdir = plpath.isdir(entry)
                coroutine.yield(entry, attr)
                if isdir then
                    yieldtree(entry)
                end
            end
        end
    end

    return coroutine.wrap(
        function()
            yieldtree(dir)
        end
    )
end

local function findLeftBorder(imagedata)
    for x = 0, imagedata:getWidth() - 1 do
        for y = 0, imagedata:getHeight() - 1 do
            local r, g, b, a = imagedata:getPixel(x, y)
            if r + g + b + a > 0 then
                return x - 1
            end
        end
    end
end

local function findRightBorder(imagedata)
    for x = imagedata:getWidth() - 1, 0, -1 do
        for y = 0, imagedata:getHeight() - 1 do
            local r, g, b, a = imagedata:getPixel(x, y)
            if r + g + b + a > 0 then
                return x + 1
            end
        end
    end
end

local function findTopBorder(imagedata)
    for y = 0, imagedata:getHeight() - 1 do
        for x = 0, imagedata:getWidth() - 1 do
            local r, g, b, a = imagedata:getPixel(x, y)
            if r + g + b + a > 0 then
                return y - 1
            end
        end
    end
end

local function findBottomBorder(imagedata)
    for y = imagedata:getHeight() - 1, 0, -1 do
        for x = 0, imagedata:getWidth() - 1 do
            local r, g, b, a = imagedata:getPixel(x, y)
            if r + g + b + a > 0 then
                return y + 1
            end
        end
    end
end

local function findMinRect(imagedata)
    return findLeftBorder(imagedata), findTopBorder(imagedata), findRightBorder(imagedata), findBottomBorder(imagedata)
end

local function isHorizontalEmpty(imagedata, y)
    for x = 0, imagedata:getWidth() - 1 do
        local r, g, b, a = imagedata:getPixel(x, y)
        if r + g + b + a > 0 then
            return false
        end
    end
    return true
end

local function isVerticalEmpty(imagedata, x)
    for y = 0, imagedata:getHeight() - 1 do
        local r, g, b, a = imagedata:getPixel(x, y)
        if r + g + b + a > 0 then
            return false
        end
    end
    return true
end

local function findMinRect2(imagedata)
    local l, r = 0, imagedata:getWidth() - 1
    repeat
        if not isVerticalEmpty(imagedata, l) or not isVerticalEmpty(imagedata, r) then
            break
        end
        l = l + 1
        r = r - 1
    until l >= r

    local t, b = 0, imagedata:getHeight() - 1
    repeat
        if not isHorizontalEmpty(imagedata, t) or not isHorizontalEmpty(imagedata, b) then
            break
        end
        t = t + 1
        b = b - 1
    until t >= b
    return l, t, r, b
end

local function numstr(n)
    local sign = n >= 0 and "+" or "-"
    return string.format("%s%d", sign, math.abs(n))
end

-- Directory with *.png images or multiple directories with *.png image into each
local SRC_DIR = assert(arg[1], "SRC_DIR expected")
-- local SRC_DIR = "assets/source/sprite/spearman"

print("Finding minimum bounding box of images in " .. SRC_DIR)

local surrounding_rect = {
    l = 2 ^ 52,
    t = 2 ^ 52,
    r = 0,
    b = 0
}
local files = {}
for filename in dirtree(SRC_DIR) do
    if plpath.extension(filename) == ".png" then
        -- local imageFile = plpath.join(SRC_DIR, fileOrDir)
        local imageFile = filename
        local imageData = love.image.newImageData(imageFile)

        local l, t, r, b = findMinRect(imageData)
        if l < surrounding_rect.l then
            surrounding_rect.l = l
        end
        if t < surrounding_rect.t then
            surrounding_rect.t = t
        end
        if r > surrounding_rect.r then
            surrounding_rect.r = r
        end
        if b > surrounding_rect.b then
            surrounding_rect.b = b
        end

        local w = r - l
        local h = b - t
        table.insert(files, {name = imageFile, w = imageData:getWidth(), h = imageData:getHeight()})
    end
end

for i, file in ipairs(files) do
    local cl, ct = surrounding_rect.l, surrounding_rect.t
    local cw = surrounding_rect.r - surrounding_rect.l
    local ch = surrounding_rect.b - surrounding_rect.t
    local cropstr = "%dx%d"
    if cl + cw >= file.w then
        cw = file.w - cl
    end
    if ct + ch >= file.h then
        ch = file.h - ct
    end
    local cropargs = {cw, ch}
    if cl > 0 or ct > 0 then
        cropstr = cropstr .. "+%d+%d"
        table.insert(cropargs, cl)
        table.insert(cropargs, ct)
    end
    if cl == 0 and ct == 0 and cw == file.w and ch == file.h then
        -- no area to crop
        print(string.format("Crop area covers all image area %s", file.name))
    else
        table.insert(cropargs, file.name)
        local cmd = string.format("mogrify -crop " .. cropstr .. " %s", unpack(cropargs))
        print(cmd)
        os.execute(cmd)
    end
end
