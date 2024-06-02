--- The main module.

-- Naming conventions:
-- * Classes
-- * everything_else
-- * (note: "classes" that are not meat to be instancied and are just here to benefit from inheritance fall into everything_else, e.g. parsing classes)

--- Usage:
-- ```lua
-- local anselme = require("anselme")
--
-- -- create a new state
-- local state = anselme.new()
-- state:load_stdlib()
--
-- -- read an anselme script file
-- local f = assert(io.open("script.ans"))
-- local script = anselme.parse(f:read("a"), "script.ans")
-- f:close()
--
-- -- load the script in a new branch
-- local run_state = state:branch()
-- run_state:run(script)
--
-- -- run the script
-- while run_state:active() do
-- 	local e, data = run_state:step()
-- 	if e == "text" then
-- 		for _, l in ipairs(data) do
-- 			print(l:format(run_state))
-- 		end
-- 	elseif e == "choice" then
-- 		for i, l in ipairs(data) do
-- 			print(("%s> %s"):format(i, l:format(run_state)))
-- 		end
-- 		local choice = tonumber(io.read("l"))
-- 		data:choose(choice)
-- 	elseif e == "return" then
-- 		run_state:merge()
-- 	elseif e == "error" then
-- 		error(data)
-- 	end
-- end
-- ```
--
-- If `require("anselme")` fails with an error similar to `module 'anselme' not found`, you might need to redefine `package.path` before the require:
-- ```lua
-- package.path = "path/?/init.lua;path/?.lua;" .. package.path -- where path is the directory where anselme is located
-- require("anselme")
-- ```
-- Anselme expects that `require("anselme.module")` will try loading both `anselme/module/init.lua` and `anselme/module.lua`, which may not be the case without the above code as `package.path`'s default value is system dependent, i.e. not my problem.

local parser, State

local anselme
anselme = {
	--- Global version string. Follow semver.
	version = "2.0.0-beta2",

	--- Table containing per-category version numbers. Incremented by one for any change that may break compatibility.
	versions = {
		--- Version number for language and standard library changes.
		language = 30,
		--- Version number for save/AST format changes.
		save = 7,
		--- Version number for Lua API changes.
		api = 10
	},

	--- Parse a `code` string and return the generated AST.
	--
	-- `source` is an optional string; it will be used as the code source name in error messages.
	--
	-- Usage:
	-- ```lua
	-- local ast = anselme.parse("1 + 2", "test")
	-- ast:eval(state)
	-- ```
	parse = function(code, source)
		return parser(code, source)
	end,
	--- Same as `:parse`, but reads the code from a file.
	-- `source` will be set as the file path.
	parse_file = function(path)
		local f = assert(io.open(path, "r"))
		local block = parser(f:read("a"), path)
		f:close()
		return block
	end,
	--- Generates and return Anselme code (as a string) that can be used as a base for a translation file.
	-- This will include every translatable element found in this code.
	-- `source` is an optional string; it will be used as the code source name in translation contexts.
	generate_translation_template = function(code, source)
		return anselme.parse(code, source):generate_translation_template()
	end,
	--- Same as `:generate_translation_template`, but reads the code from a file.
	-- `source` will be set as the file path.
	generate_translation_template_file = function(path)
		return anselme.parse_file(path):generate_translation_template()
	end,
	--- Return a new [State](#state).
	new = function()
		return State:new()
	end,
}

package.loaded[...] = anselme

parser = require("anselme.parser")
State = require("anselme.state.State")
require("anselme.ast.abstract.Node"):_i_hate_cycles()

return anselme
