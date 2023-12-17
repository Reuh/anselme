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
-- local script = anselme.parse(f:read("*a"), "script.ans")
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
-- 		local choice = tonumber(io.read("*l"))
-- 		data:choose(choice)
-- 	elseif e == "return" then
-- 		run_state:merge()
-- 	elseif e == "error" then
-- 		error(data)
-- 	end
-- end
-- ```

local parser = require("parser")
local State = require("state.State")
require("ast.abstract.Node"):_i_hate_cycles()

return {
	--- Global version string. Follow semver.
	version = "2.0.0-alpha",

	--- Table containing per-category version numbers. Incremented by one for any change that may break compatibility.
	versions = {
		--- Version number for languages and standard library changes.
		language = 27,
		--- Version number for save/AST format changes.
		save = 4,
		--- Version number for Lua API changes.
		api = 8
	},

	--- Parse a `code` string and return the generated AST.
	--
	-- `source` is an optional string; it will be used as the code source name in error messages.
	--
	-- Usage:
	-- ```lua
	-- local ast = anselme.parse("1 + 2", "test")
	-- ast:eval()
	-- ```
	parse = function(code, source)
		return parser(code, source)
	end,
	--- Return a new [State](#state).
	new = function()
		return State:new()
	end,
}
