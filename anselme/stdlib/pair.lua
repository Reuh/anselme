local ast = require("anselme.ast")
local Pair = ast.Pair

return {
	{ "_:_", "(name, value)", function(state, a, b) return Pair:new(a,b) end },

	{
		"name", "(pair::is pair)",
		function(state, pair)
			return pair.name
		end
	},
	{
		"value", "(pair::is pair)",
		function(state, pair)
			return pair.value
		end
	},
}
