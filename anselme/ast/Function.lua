-- note: functions only appear in non-evaluated nodes! once evaluated, they always become closures

local ast = require("anselme.ast")
local Overloadable = ast.abstract.Overloadable
local ReturnBoundary

local operator_priority = require("anselme.common").operator_priority

local resume_manager, calling_environment_manager

local Function
Function = Overloadable {
	type = "function",

	parameters = nil, -- ParameterTuple
	expression = nil, -- function content
	scope = nil, -- Environment; captured scope for closure (evaluated functions); not set when not evaluated

	init = function(self, parameters, expression, scope)
		self.parameters = parameters
		self.expression = expression
		self.scope = scope
	end,
	with_return_boundary = function(self, parameters, expression)
		return Function:new(parameters, ReturnBoundary:new(expression))
	end,

	_format = function(self, ...)
		if self.parameters.assignment then
			return "$"..self.parameters:format(...).."; "..self.expression:format_right(...)
		else
			return "$"..self.parameters:format(...).." "..self.expression:format_right(...)
		end
	end,
	_format_priority = function(self)
		return operator_priority["$_"]
	end,

	traverse = function(self, fn, ...)
		fn(self.parameters, ...)
		fn(self.expression, ...)
		if self.scope then
			fn(self.scope, ...)
		end
	end,

	_eval = function(self, state)
		-- layer a new scope layer on top of captured/current scope
		-- to allow future define in the function (fn.:var = "foo")
		state.scope:push()
		local scope = state.scope:capture() -- capture current scope to build closure
		state.scope:pop()

		return Function:new(self.parameters:eval(state), self.expression, scope)
	end,

	compatible_with_arguments = function(self, state, args)
		return args:match_parameter_tuple(state, self.parameters)
	end,
	format_parameters = function(self, state)
		return self.parameters:format(state)
	end,
	hash_parameters = function(self)
		return self.parameters:hash()
	end,
	call_dispatched = function(self, state, args)
		assert(self.scope, "can't call unevaluated function")

		-- push captured closure scope
		local calling_environment = state.scope:capture()
		state.scope:push(self.scope)
		calling_environment_manager:push(state, calling_environment)

		-- push function scope
		state.scope:push()
		args:bind_parameter_tuple(state, self.parameters)
		local exp = self.expression:eval(state)
		state.scope:pop()

		calling_environment_manager:pop(state)
		state.scope:pop()
		return exp
	end,
	resume = function(self, state, target)
		if self.parameters.min_arity > 0 then error("can't resume function with parameters") end
		assert(self.scope, "can't resume unevaluated function")

		-- push captured closure scope
		local calling_environment = state.scope:capture()
		state.scope:push(self.scope)
		calling_environment_manager:push(state, calling_environment)

		resume_manager:push(state, target)

		-- push function scope
		state.scope:push()
		local exp = self.expression:eval(state)
		state.scope:pop()

		resume_manager:pop(state)

		calling_environment_manager:pop(state)
		state.scope:pop()
		return exp
	end,
}

package.loaded[...] = Function
ReturnBoundary = ast.ReturnBoundary

resume_manager = require("anselme.state.resume_manager")
calling_environment_manager = require("anselme.state.calling_environment_manager")

return Function
