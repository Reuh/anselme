--- # Pairs
-- @titlelevel 3

local ast = require("anselme.ast")
local Pair = ast.Pair

return {
	--- Returns a new pair with name `name` and value `value`.
	--
	-- Note that if the left expression is an identifier, it is parsed as a string.
	-- ```
	-- name: 42
	-- // is the same as
	-- "name": 42
	-- ```
	{ "_:_", "(name, value)", function(state, a, b) return Pair:new(a,b) end },

	{
		--- Returns the pair `pair`'s name.
		"name", "(pair::is pair)",
		function(state, pair)
			return pair.name
		end
	},
	{
		--- Returns the pair `pair`'s value.
		"value", "(pair::is pair)",
		function(state, pair)
			return pair.value
		end
	},
}
