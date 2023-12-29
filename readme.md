# Anselme

The overengineered dialog scripting system in pure Lua.

This is version 2, a full rewrite. Currently not stable.

Supported: Lua 5.4, Lua 5.3, LuaJIT (LuaJIT requires the utf8 module: `luarocks --lua-version=5.1 install luautf8`).
Otherwise all needed files are included in the `anselme` directory.

Documentation:

* [Lua API documentation](doc/api.md)
* [Language reference](doc/language.md)
* [Tutorial](doc/tutorial.md)

Development:

* Generate documentation: `lua doc/gendocs.lua`
* Run test for the current Lua version: `lua test/run.lua`
* Run test for every supported Lua version: `./run_tests.sh`
