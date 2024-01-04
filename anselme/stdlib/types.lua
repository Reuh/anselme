local ast = require("anselme.ast")
local ArgumentTuple, Boolean, String, Typed = ast.ArgumentTuple, ast.Boolean, ast.String, ast.Typed

return {
	{
		"_::_", "(value, check)",
		function(state, value, check)
			local r = check:call(state, ArgumentTuple:new(value))
			if r:truthy() then
				return value
			else
				error(("type check failure: %s does not satisfy %s"):format(value:format(state), check:format(state)), 0)
			end
		end
	},

	{
		"type", "(value)",
		function(state, v)
			if v.type == "typed" then
				return v.type_expression
			else
				return String:new(v.type)
			end
		end
	},
	{
		"type", "(value, type)",
		function(state, v, t)
			return Typed:new(v, t)
		end
	},
	{
		"value", "(value)",
		function(state, v)
			if v.type == "typed" then
				return v.expression
			else
				return v
			end
		end
	},

	{ "nil", "(x)", function(state, x) return Boolean:new(x.type == "nil") end },
	{ "number", "(x)", function(state, x) return Boolean:new(x.type == "number") end },
	{ "string", "(x)", function(state, x) return Boolean:new(x.type == "string") end },
	{ "boolean", "(x)", function(state, x) return Boolean:new(x.type == "boolean") end },
	{ "symbol", "(x)", function(state, x) return Boolean:new(x.type == "symbol") end },
	{ "anchor", "(x)", function(state, x) return Boolean:new(x.type == "anchor") end },

	{ "text", "(x)", function(state, x) return Boolean:new(x.type == "text") end },

	{ "pair", "(x)", function(state, x) return Boolean:new(x.type == "pair") end },
	{ "tuple", "(x)", function(state, x) return Boolean:new(x.type == "tuple") end },
	{ "list", "(x)", function(state, x) return Boolean:new(x.type == "list") end },
	{ "struct", "(x)", function(state, x) return Boolean:new(x.type == "struct") end },
	{ "table", "(x)", function(state, x) return Boolean:new(x.type == "table") end },

	{ "function", "(x)", function(state, x) return Boolean:new(x.type == "function") end },
	{ "overload", "(x)", function(state, x) return Boolean:new(x.type == "overload") end },
	{ "callable", "(x)", function(state, x) return Boolean:new(x.type == "overload" or x.type == "function" or x.type == "lua function" or x.type == "quote") end },
}
