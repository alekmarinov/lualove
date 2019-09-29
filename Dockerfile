FROM akorn/luarocks:luajit2.1-alpine

RUN set -ex \
    apk add --no-cache --virtual .build-deps \
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
    directfb-dev
