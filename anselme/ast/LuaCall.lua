local ast = require("anselme.ast")
local unpack = table.unpack or unpack
local calling_environment_manager

local LuaCall
LuaCall = ast.abstract.Runtime {
	type = "lua call",
	hide_in_stacktrace = true,
	_evaluated = false,

	parameters = nil, -- ParameterTuple, may be unevaluated
	func = nil, -- lua function

	init = function(self, parameters, func)
		self.parameters = parameters
		self.func = func
	end,

	make_function = function(self, state, parameters, func)
		local fn = ast.Function:new(parameters, LuaCall:new(parameters, func))
		return fn:eval(state)
	end,

	traverse = function(self, fn, ...)
		fn(self.parameters, ...)
	end,

	_hash = function(self)
		return ("%s<%s;%s>"):format(self.type, self.parameters:hash(), tostring(self.func))
	end,

	_format = function(self, ...)
		return "<lua function>"
	end,

	_eval = function(self, state)
		-- get arguments
		local lua_args = { state }
		for _, param in ipairs(self.parameters.list) do
			table.insert(lua_args, state.scope:get(param.identifier))
		end

		-- run function, in calling environment
		state.scope:push(calling_environment_manager:get_level(state, 1))
		local r = self.func(unpack(lua_args))
		assert(r, "lua function returned no value")
		state.scope:pop()

		return r
	end,

	to_lua = function(self, state)
		return self.func
	end,
}

package.loaded[...] = LuaCall
calling_environment_manager = require("anselme.state.calling_environment_manager")

return LuaCall
