cmake_minimum_required(VERSION 3.1)
project(love-portable)

ADD_SUBDIRECTORY(submodules/love)

install(CODE "MESSAGE(\"Finished building love library\")")
