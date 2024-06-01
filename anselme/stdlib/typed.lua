--- # Typed values
-- @titlelevel 3

local ast = require("anselme.ast")
local ArgumentTuple, String, Typed, Boolean = ast.ArgumentTuple, ast.String, ast.Typed, ast.Boolean

return {
	{
		--- Call `check(value)` and error if it returns a false value.
		-- This can be used to ensure a value checking function is verified on a value.
		-- @defer value checking
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
		--- Returns true if `value` is a typed value, false otherwise.
		"is typed", "(value)",
		function(state, v)
			return Boolean:new(v.type == "typed")
		end,
	},
	{
		--- Returns the type of `value`.
		--
		-- If `value` is a typed value, returns its associated type.
		-- Otherwise, returns a string of its type (`"string"`, `"number"`, etc.).
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
		--- Returns a new typed value with value `value` and type `type`.
		"type", "(value, type)",
		function(state, v, t)
			return Typed:new(v, t)
		end
	},
	{
		--- Returns the value of `value`.
		--
		-- If `value` is a typed value, returns its associated value.
		-- Otherwise, returns a `value` directly.
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
