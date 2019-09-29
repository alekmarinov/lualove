
# love-portable

This projects sets up Love2D library (https://love2d.org/) to be used as a module from standalone Lua binary.

## Building

### Install libraries and tools

#### Ubuntu

```
apt update
apt install cmake \
	make \
	g++ \
	libglu1-mesa-dev \
	libfreetype6-dev \
	libmodplug-dev \
	libopenal-dev \
	libsdl2-dev \
	libtheora-dev \
	libvorbis-dev \
	libmpg123-dev \
	libluajit-5.1-dev \
	luarocks
```

#### Alpine

```
apk add --no-cache \
	cmake \
	make \
	g++ \
	mesa-dev \
	freetype-dev \
	libmodplug-dev \
	openal-soft-dev \
	sdl2-dev \
	libtheora-dev \
	libvorbis-dev \
	mpg123-dev \
	directfb-dev \
	luajit-dev
```
Note: luarocks need to be installed from source.
Follow the [installation-instructions-for-unix](https://github.com/luarocks/luarocks/wiki/installation-instructions-for-unix)


### Set no sudo environment

```
eval $(luarocks path --bin)
export LD_LIBRARY_PATH=$HOME/.luarocks/lib/lua/5.1
luarocks make --local
```
### Build with luarocks

```
luarocks make --local
```

## Test

```
lua demo/demo.lua
```
