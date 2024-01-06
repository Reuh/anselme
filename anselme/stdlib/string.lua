local utf8 = utf8 or require("lua-utf8")
local ast = require("anselme.ast")
local String, Number = ast.String, ast.Number

return {
	{ "_+_", "(a::is string, b::is string)", function(state, a, b) return String:new(a.string .. b.string) end },
	{
		"len", "(s::is string)",
		function(state, s)
			return Number:new(utf8.len(s.string))
		end
	}
}
