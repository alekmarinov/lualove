
# lualove

This projects makes Love2D library (https://love2d.org/) requirable with standard Lua 5.1 interpreter.

## Building Love2D

### Windows
Check this project for instructions https://github.com/love2d/megasource

### Unix

Install library dependencies and tools

#### Ubuntu

```
sudo apt-get update
sudo apt-get -y install cmake \
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

### Build Love2D from source

Follow the instructions from the official repository https://github.com/love2d/love

### Install luarocks

Follow the [installation-instructions-for-unix](https://github.com/luarocks/luarocks/wiki/installation-instructions-for-unix)

```
luarocks make --local
```

## Test

```
lua -llualove
```
