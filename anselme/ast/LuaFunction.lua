local ast = require("anselme.ast")
local Overloadable = ast.abstract.Overloadable

local operator_priority = require("anselme.common").operator_priority
local unpack = table.unpack or unpack

local calling_environment_manager

local LuaFunction
LuaFunction = ast.abstract.Runtime(Overloadable) {
	type = "lua function",

	parameters = nil, -- ParameterTuple
	func = nil, -- lua function

	init = function(self, parameters, func)
		self.parameters = parameters
		self.func = func
	end,

	traverse = function(self, fn, ...)
		fn(self.parameters, ...)
	end,

	_hash = function(self)
		return ("%s<%s;%s>"):format(self.type, self.parameters:hash(), tostring(self.func))
	end,

	_format = function(self, ...)
		if self.parameters.assignment then
			return "$"..self.parameters:format(...).."; <lua function>"
		else
			return "$"..self.parameters:format(...).." <lua function>"
		end
	end,
	_format_priority = function(self)
		return operator_priority["$_"]
	end,

	compatible_with_arguments = function(self, state, args)
		return args:match_parameter_tuple(state, self.parameters)
	end,
	format_signature = function(self, state)
		return "$"..self.parameters:format_short(state)
	end,
	hash_signature = function(self)
		return self.parameters:hash()
	end,
	call_dispatched = function(self, state, args)
		local calling_environment = state.scope:capture()
		calling_environment_manager:push(state, calling_environment)

		local lua_args = { state }

		state.scope:push()

		args:bind_parameter_tuple(state, self.parameters)
		for _, param in ipairs(self.parameters.list) do
			table.insert(lua_args, state.scope:get(param.identifier))
		end

		state.scope:pop()

		local r = self.func(unpack(lua_args))
		assert(r, "lua function returned no value")

		calling_environment_manager:pop(state)
		return r
	end,

	_eval = function(self, state)
		return LuaFunction:new(self.parameters:eval(state), self.func)
	end,

	to_lua = function(self, state)
		return self.func
	end,
}

package.loaded[...] = LuaFunction
calling_environment_manager = require("anselme.state.calling_environment_manager")

return LuaFunction
