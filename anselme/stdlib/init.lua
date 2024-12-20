local parser = require("anselme.parser")

local function define_lua(state, list)
	for _, fn in ipairs(list) do
		state.scope:define_lua("@"..fn[1], fn[2], fn[3], true)
		if fn.alias then
			for _, alias in ipairs(fn.alias) do
				state.scope:define_lua("@"..alias, fn[2], fn[3], true)
			end
		end
	end
end
local function load(state, l)
	for _, m in ipairs(l) do
		local mod = require("anselme.stdlib."..m)
		if type(mod) == "string" then
			parser(mod, "stdlib/"..m..".ans"):eval(state)
		else
			define_lua(state, mod)
		end
	end
end

return function(main_state)
	load(main_state, {
		"boolean",
		"tag",
		"conditionals",
		"base",
		"typed",
		"assignment",
		"value check",
		"number",
		"string",
		"symbol",
		"text",
		"pair",
		"structures",
		"wrap",
		"attached block",
		"environment",
		"function",
		"resume",
		"persist",
		"for",
		"script"
	})
end
