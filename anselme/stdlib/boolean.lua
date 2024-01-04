local ast = require("anselme.ast")
local Boolean, ArgumentTuple = ast.Boolean, ast.ArgumentTuple

return {
	{ "true", Boolean:new(true) },
	{ "false", Boolean:new(false) },

	{
		"_==_", "(a, b)",
		function(state, a, b)
			if a.mutable ~= b.mutable then return Boolean:new(false)
			else
				return Boolean:new(a:hash() == b:hash())
			end
		end
	},
	{
		"_!=_", "(a, b)",
		function(state, a, b)
			if a.mutable ~= b.mutable then return Boolean:new(true)
			else
				return Boolean:new(a:hash() ~= b:hash())
			end
		end
	},
	{
		"!_", "(a)",
		function(state, a)
			return Boolean:new(not a:truthy())
		end
	},
	{
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
