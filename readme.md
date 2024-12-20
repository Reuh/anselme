# Anselme

The overengineered game dialog scripting system in pure Lua.

```
:money = 10
:health points = 5

"from": "barista" #
	| Hi, what can I do for you?

*| a latte with a bunch of sugar and a pretty sprinkles please
	from: "barista" #
		| Good choice. Here you go. Have a colorful day.
	money -= 10
*| triple expresso
	from: "barista" #
		| Here. Have a nice day.
	money -= 2
*| a slap
	from: "barista" #
		| With pleasure.

	type: "sfx" #
		| SLAP
	health points -= 2

	| Thanks, I feel much better.
```

This is version 2, a full rewrite. Version 1 is still available in the v1 branch.

Supported: Lua 5.4, Lua 5.3, LÖVE, LuaJIT (LuaJIT requires the utf8 module: `luarocks --lua-version=5.1 install luautf8`).
Otherwise all needed files are included in the `anselme` directory.

Anselme is licensed under the ISC license, meaning you can basically use it for anything as long as you make the content of the [license file](license) appear somewhere. I would appreciate it if you don't use Anselme to commit war crimes though. If that's not enough for you or want better support, feel free to contact me, my integrity can be bought.

## Documentation

* [Tutorial](doc/tutorial.md) for a collection of code examples
* [Lua API documentation](doc/api.md) for how to use Anselme in your game
* [Standard library](doc/standard_library.md) for a description of all built-in functions
* [Language reference](doc/language.md) for a description of all language features

## Related projects

* [sublime-anselme](https://github.com/Reuh/sublime-anselme) for syntax highlighting of Anselme scripts in Sublime Text 4.

## Development

* Generate documentation: `lua doc/gendocs.lua`
* Run test for the current Lua version: `lua test/run.lua` (require luafilesystem `luarocks install luautf8`)
* Run test for every supported Lua version: `sh test/run_all.sh` (require luafilesystem for LuaJIT, Lua 5.3 and Lua 5.4)
