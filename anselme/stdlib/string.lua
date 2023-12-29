local ast = require("anselme.ast")
local String = ast.String

return {
	{ "_+_", "(a::string, b::string)", function(state, a, b) return String:new(a.string .. b.string) end }
}
