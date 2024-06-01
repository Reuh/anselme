#!/bin/sh

# Run the test suite accross supported Lua versions.
# Note that the test suite require luafilesystem: `luarocks --lua-version=5.4 install luafilesystem`

echo "/----------------------------\\"
echo "| Running tests with Lua 5.4 |"
echo "\\----------------------------/"
lua5.4 test/run.lua
echo ""

echo "/----------------------------\\"
echo "| Running tests with Lua 5.3 |"
echo "\\----------------------------/"
lua5.3 test/run.lua
echo ""

echo "/---------------------------\\"
echo "| Running tests with LuaJIT |"
echo "\\---------------------------/"
luajit test/run.lua
