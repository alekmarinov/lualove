--- Paint module for loading and transforming image pixels to player's color
local PLAYER_COLOR = require "gameon.engine.enums".PLAYER_COLOR
local Paint = {
    COLOR_DETECT_TOLERANCE = 8
}
Paint.__index = Paint

local function isgray(r, g, b)
    r = r * 256
    g = g * 256
    b = b * 256
    return math.abs(r - g) <= Paint.COLOR_DETECT_TOLERANCE and math.abs(r - b) <= Paint.COLOR_DETECT_TOLERANCE and math.abs(g - b) <= Paint.COLOR_DETECT_TOLERANCE
end

function Paint.new()
    return setmetatable({
        images = {}
    }, Paint)
end

function Paint:load(name, imagepath)
    if not self.images[name] then
        print(string.format("Paint:Loading %s from %s", name, imagepath))
        self.images[name] = love.image.newImageData(imagepath)
    end
    return self.images[name]
end

function Paint:create(name, colorname)
    -- check if the image is cached
    local cachefile = string.format("cache/%s-%s.png", name, colorname)
    local imagedata
    if love.filesystem.getInfo(cachefile) then
        -- load from cache
        local filedata = love.filesystem.read("data", cachefile)
        imagedata = love.image.newImageData(filedata)
        return love.graphics.newImage(imagedata)
    end

    local colormask = assert(PLAYER_COLOR[colorname], "No such color "..colorname)
    assert(self.images[name], "Image "..name.." is not loaded")

    print(string.format("Paint:Creating %s as %s", name, colorname))
    imagedata = love.image.newImageData(self.images[name]:getWidth(), self.images[name]:getHeight())
    for i = 0, imagedata:getWidth() - 1 do
        for j = 0, imagedata:getHeight() - 1 do
            local r, g, b, a = self.images[name]:getPixel(i, j)
            if isgray(r, g, b) then
                r = r * colormask[1]
                g = g * colormask[2]
                b = b * colormask[3]
            end
            imagedata:setPixel(i, j, r, g, b, a)
        end
    end

    love.filesystem.createDirectory("cache")
    local outFile = assert(love.filesystem.newFile(cachefile))
    assert(outFile:open('w'))
    assert(outFile:write(imagedata:encode("png")))
    outFile:close()

    return love.graphics.newImage(imagedata)
end

return Paint
