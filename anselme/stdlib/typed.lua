local ast = require("anselme.ast")
local ArgumentTuple, String, Typed, Boolean = ast.ArgumentTuple, ast.String, ast.Typed, ast.Boolean

return {
	{
		"_::_", "(value, check)",
		function(state, value, check)
			local r = check:call(state, ArgumentTuple:new(value))
			if r:truthy() then
				return value
			else
				error(("value check failure: %s does not satisfy %s"):format(value:format(state), check:format(state)), 0)
			end
		end
	},

	{
		"is typed", "(value)",
		function(state, v)
			return Boolean:new(v.type == "typed")
		end,
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
}
