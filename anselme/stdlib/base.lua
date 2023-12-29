local ast = require("anselme.ast")
local Pair, ArgumentTuple, Nil, String, Typed, Boolean = ast.Pair, ast.ArgumentTuple, ast.Nil, ast.String, ast.Typed, ast.Boolean

return {
	{ "_;_", "(left, right)", function(state, left, right) return right end },
	{ "_;", "(left)", function(state, left) return Nil:new() end },
	{ "_:_", "(name, value)", function(state, a, b) return Pair:new(a,b) end },
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
		"print", "(a)",
		function(state, a)
			print(a:format(state))
			return Nil:new()
		end
	},
	{
		"hash", "(a)",
		function(state, a)
			return String:new(a:hash())
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
		"value", "(value)",
		function(state, v)
			if v.type == "typed" then
				return v.expression
			else
				return v
			end
		end
	},
	{
		"type", "(value, type)",
		function(state, v, t)
			return Typed:new(v, t)
		end
	},
	{ "true", Boolean:new(true) },
	{ "false", Boolean:new(false) },
}
