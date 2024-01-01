local ast = require("anselme.ast")
local Boolean = ast.Boolean

return {
	{ "nil", "(x)", function(state, x) return Boolean:new(x.type == "nil") end },
	{ "number", "(x)", function(state, x) return Boolean:new(x.type == "number") end },
	{ "string", "(x)", function(state, x) return Boolean:new(x.type == "string") end },
	{ "boolean", "(x)", function(state, x) return Boolean:new(x.type == "boolean") end },
	{ "symbol", "(x)", function(state, x) return Boolean:new(x.type == "symbol") end },
	{ "anchor", "(x)", function(state, x) return Boolean:new(x.type == "anchor") end },

	{ "text", "(x)", function(state, x) return Boolean:new(x.type == "text") end },

	{ "tuple", "(x)", function(state, x) return Boolean:new(x.type == "tuple") end },
	{ "list", "(x)", function(state, x) return Boolean:new(x.type == "list") end },
	{ "struct", "(x)", function(state, x) return Boolean:new(x.type == "struct") end },
	{ "table", "(x)", function(state, x) return Boolean:new(x.type == "table") end },

	{ "function", "(x)", function(state, x) return Boolean:new(x.type == "function") end },
	{ "overload", "(x)", function(state, x) return Boolean:new(x.type == "overload") end },
	{ "callable", "(x)", function(state, x) return Boolean:new(x.type == "overload" or x.type == "function" or x.type == "lua function" or x.type == "quote") end },
}
