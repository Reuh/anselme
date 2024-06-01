--- # Boolean
-- @titlelevel 3

local ast = require("anselme.ast")
local Boolean, ArgumentTuple = ast.Boolean, ast.ArgumentTuple

return {
	--- A boolean true value.
	{ "true", Boolean:new(true) },
	--- A boolean false value.
	{ "false", Boolean:new(false) },

	{
		--- Equality operator.
		-- Returns true if `a` and `b` are equal, false otherwise.
		--
		-- Mutable values are compared by reference, immutable values are compared by value.
		"_==_", "(a, b)",
		function(state, a, b)
			if a.mutable ~= b.mutable then return Boolean:new(false)
			else
				return Boolean:new(a:hash() == b:hash())
			end
		end
	},
	{
		--- Inequality operator.
		-- Retrusn false if `a` and `b` are equal, true otherwise.
		"_!=_", "(a, b)",
		function(state, a, b)
			if a.mutable ~= b.mutable then return Boolean:new(true)
			else
				return Boolean:new(a:hash() ~= b:hash())
			end
		end
	},
	{
		--- Boolean not operator.
		-- Returns false if `a` is true, false otherwise.
		"!_", "(a)",
		function(state, a)
			return Boolean:new(not a:truthy())
		end
	},
	{
		--- Boolean lazy and operator.
		-- If `left` is truthy, evaluate `right` and returns it. Otherwise, returns left.
		"_&_", "(left, right)",
		function(state, left, right)
			if left:truthy() then
				return right:call(state, ArgumentTuple:new())
			else
				return left
			end
		end
	},
	{
		--- Boolean lazy or operator.
		-- If `left` is truthy, returns it. Otherwise, evaluate `right` and returns it.
		"_|_", "(left, right)",
		function(state, left, right)
			if left:truthy() then
				return left
			else
				return right:call(state, ArgumentTuple:new())
			end
		end
	},
}
