-- note: functions only appear in non-evaluated nodes! once evaluated, they always become closures

local ast = require("anselme.ast")
local Overloadable, Runtime = ast.abstract.Overloadable, ast.abstract.Runtime

local resume_manager

local Closure
Closure = Runtime(Overloadable) {
	type = "closure",

	func = nil, -- Function
	scope = nil, -- Environment

	init = function(self, func, state)
		self.func = func

		-- layer a new scope layer on top of captured/current scope
		-- to allow future define in the function (fn.:var = "foo")
		state.scope:push()
		self.scope = state.scope:capture()
		state.scope:pop()
	end,

	_format = function(self, ...)
		return self.func:format(...)
	end,

	traverse = function(self, fn, ...)
		fn(self.func, ...)
		fn(self.scope, ...)
	end,

	compatible_with_arguments = function(self, state, args)
		return args:match_parameter_tuple(state, self.func.parameters)
	end,
	format_parameters = function(self, state)
		return self.func.parameters:format(state)
	end,
	call_dispatched = function(self, state, args)
		state.scope:push(self.scope)
		local exp = self.func:call_dispatched(state, args)
		state.scope:pop()
		return exp
	end,
	resume = function(self, state, target)
		if self.func.parameters.min_arity > 0 then error("can't resume function with parameters") end
		state.scope:push(self.scope)
		resume_manager:push(state, target)
		local exp = self.func:call(state, ast.ArgumentTuple:new())
		resume_manager:pop(state)
		state.scope:pop()
		return exp
	end,
}

package.loaded[...] = Closure
resume_manager = require("anselme.state.resume_manager")

return Closure
