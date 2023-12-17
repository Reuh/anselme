local ast = require("ast")
local Boolean = ast.Boolean

return {
	{ "number", "(x)", function(state, x) return Boolean:new(x.type == "number") end },
	{ "string", "(x)", function(state, x) return Boolean:new(x.type == "string") end },
	{ "boolean", "(x)", function(state, x) return Boolean:new(x.type == "boolean") end },
	{ "symbol", "(x)", function(state, x) return Boolean:new(x.type == "symbol") end },

	{ "text", "(x)", function(state, x) return Boolean:new(x.type == "text") end },

	{ "tuple", "(x)", function(state, x) return Boolean:new(x.type == "tuple") end },
	{ "list", "(x)", function(state, x) return Boolean:new(x.type == "list") end },
	{ "struct", "(x)", function(state, x) return Boolean:new(x.type == "struct") end },
	{ "table", "(x)", function(state, x) return Boolean:new(x.type == "table") end },

	{ "closure", "(x)", function(state, x) return Boolean:new(x.type == "closure") end },
	{ "overload", "(x)", function(state, x) return Boolean:new(x.type == "overload") end },
	{ "function", "(x)", function(state, x) return Boolean:new(x.type == "overload" or x.type == "closure" or x.type == "funciton" or x.type == "lua function") end },
}
