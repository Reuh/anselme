local ast = require("anselme.ast")
local Nil = ast.Nil

local persistent_manager = require("anselme.state.persistent_manager")

return {
	{
		"persist", "(key, default)",
		function(state, key, default)
			return persistent_manager:get(state, key, default)
		end
	},
	{
		"persist", "(key, default) = value",
		function(state, key, default, value)
			persistent_manager:set(state, key, value)
			return Nil:new()
		end
	},
	{
		"persist", "(key)",
		function(state, key)
			return persistent_manager:get(state, key)
		end
	},
	{
		"persist", "(key) = value",
		function(state, key, value)
			persistent_manager:set(state, key, value)
			return Nil:new()
		end
	},
}
