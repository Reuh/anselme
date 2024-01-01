local class = require("anselme.lib.class")

local ast = require("anselme.ast")
local Identifier

-- stack of resumable contexts
local calling_env_identifier, calling_env_symbol

local calling_environment_manager = class {
	init = false,

	push = function(self, state, calling_environment)
		state.scope:push_partial(calling_env_identifier)
		state.scope:define(calling_env_symbol, calling_environment)
	end,
	pop = function(self, state)
		state.scope:pop()
	end,

	get_level = function(self, state, level)
		local env = state.scope:capture()
		while level > 0 do
			assert(env:defined(state, calling_env_identifier), "no calling function")
			env = env:get(state, calling_env_identifier)
			level = level - 1
		end
		return env
	end,
}

package.loaded[...] = calling_environment_manager

Identifier = ast.Identifier

calling_env_identifier = Identifier:new("_calling_environment")
calling_env_symbol = calling_env_identifier:to_symbol()

return calling_environment_manager
