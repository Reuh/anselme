local ast = require("ast")
local Boolean, ArgumentTuple = ast.Boolean, ast.ArgumentTuple

return {
	{
		"_==_", "(a, b)",
		function(state, a, b)
			if a.mutable ~= b.mutable then return Boolean:new(false)
			elseif a.mutable then
				return Boolean:new(a == b)
			else
				return Boolean:new(a:hash() == b:hash())
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
