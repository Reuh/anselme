local class = require("anselme.lib.class")

local ast = require("anselme.ast")
local Table, Identifier

local persistent_identifier, persistent_symbol

local persistent_manager = class {
	init = false,

	setup = function(self, state)
		state.scope:define(persistent_symbol, Table:new(state))
	end,

	-- set the persistant variable `key` to `value` (evaluated)
	set = function(self, state, key, value)
		local persistent = state.scope:get(persistent_identifier)
		persistent:set(state, key, value)
	end,
	-- get the persistant variable `key`'s value
	-- if `default` is given, will set the variable to this if not currently set
	get = function(self, state, key, default)
		local persistent = state.scope:get(persistent_identifier)
		if not persistent:has(state, key) then
			if default then
				persistent:set(state, key, default)
			else
				error("persistent key does not exist")
			end
		end
		return persistent:get(state, key)
	end,

	-- returns a struct of the current persisted variables
	capture = function(self, state)
		local persistent = state.scope:get(persistent_identifier)
		return persistent:to_struct(state)
	end
}

package.loaded[...] = persistent_manager
Table, Identifier = ast.Table, ast.Identifier

persistent_identifier = Identifier:new("_persistent") -- Table of { [key] = Call, ... }
persistent_symbol = persistent_identifier:to_symbol()

return persistent_manager
