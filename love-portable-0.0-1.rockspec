package = "love-portable"
version = "0.0-1"
source = {
   url = "https://github.com/alekmarinov/love-portable.git"
}
description = {
   summary = "Builds Love2D library as Lua module",
   detailed = [[
      Sets up Love2D library (https://love2d.org/) to be used as a module from standalone Lua binary.
   ]],
   homepage = "https://github.com/alekmarinov/love-portable",
   license = "MIT/X11"
}
dependencies = {
   "dkjson"
}
build = {
   type = "cmake",
   install = {
      lib = { liblove = "build.luarocks/submodules/love/libliblove.so" },
      lua = { 
         love = "src/lua/love.lua",
         ["love-portable"] = "src/lua/love-portable.lua",
         ["sti.init"] = "submodules/Simple-Tiled-Implementation/sti/init.lua",
         ["sti.graphics"] = "submodules/Simple-Tiled-Implementation/sti/graphics.lua",
         ["sti.utils"] = "submodules/Simple-Tiled-Implementation/sti/utils.lua",
         ["sti.plugins.box2d"] = "submodules/Simple-Tiled-Implementation/sti/plugins/box2d.lua",
         ["sti.plugins.bump"] = "submodules/Simple-Tiled-Implementation/sti/plugins/bump.lua"
      }
   }
}
