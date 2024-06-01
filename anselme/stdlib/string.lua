--- # Strings
-- @titlelevel 3

local utf8 = utf8 or require("lua-utf8")
local ast = require("anselme.ast")
local String, Number = ast.String, ast.Number

return {
	--- Concatenate two strings and return the result as a new string.
	{ "_+_", "(a::is string, b::is string)", function(state, a, b) return String:new(a.string .. b.string) end },
	{
		--- Returns the length of the string `s`.
		"len", "(s::is string)",
		function(state, s)
			return Number:new(utf8.len(s.string))
		end
	},
	{
		--- Return the same string.
		-- See [format](#format-val) for details on the format function.
		"format", "(val::is string)",
		function(state, val)
			return val
		end
	}
}
