package = "love-portable"
version = "0.0-1"
source = {
   url = "..." -- We don't have one yet
}
description = {
   summary = "An example for the LuaRocks tutorial.",
   detailed = [[
      This is an example for the LuaRocks tutorial.
      Here we would put a detailed, typically
      paragraph-long description.
   ]],
   homepage = "http://...", -- We don't have one yet
   license = "MIT/X11" -- or whatever you like
}
dependencies = {
   -- If you depend on other rocks, add them here
}
build = {
   type = "cmake",
   install = {
      lib = { liblove = "build.luarocks/submodules/love/libliblove.so" },
      lua = { 
         love = "src/lua/love.lua",
         ["love-portable"] = "src/lua/love-portable.lua",
         ["love.boot"] = "submodules/love/src/scripts/boot.lua"
      }
   }
}
