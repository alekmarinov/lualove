package = "love-portable"
version = "0.0-1"
source = {
   url = "https://github.com/alekmarinov/love-portable.git"
}
description = {
   summary = "Loads Love2D library as Lua module",
   detailed = [[
      Module allowing to load the Love2D (https://love2d.org/) module from arbitrary Lua 5.1 interpreter
   ]],
   homepage = "https://github.com/alekmarinov/love-portable.git",
   license = "MIT/X11"
}

build = {
   type = "builtin",
   modules = {
      ["love-portable"] = "lua/love-portable.lua"
   }
}
