-- note: functions only appear in non-evaluated nodes! once evaluated, they always become closures

local ast = require("ast")
local Overloadable = ast.abstract.Overloadable
local Closure, ReturnBoundary

local operator_priority = require("common").operator_priority

local Function
Function = Overloadable {
	type = "function",

	parameters = nil, -- ParameterTuple
	expression = nil,
	format_priority = operator_priority["$_"],

	exports = nil, -- { [sym] = exp, ... }, exctracted from expression during :prepare

	init = function(self, parameters, expression, exports)
		self.parameters = parameters
		self.expression = ReturnBoundary:new(expression)
		self.exports = exports or {}
	end,

	_format = function(self, ...)
		if self.parameters.assignment then
			return "$"..self.parameters:format(...).."; "..self.expression:format_right(...)
		else
			return "$"..self.parameters:format(...).." "..self.expression:format_right(...)
		end
	end,

	traverse = function(self, fn, ...)
		fn(self.parameters, ...)
		fn(self.expression, ...)
	end,

	compatible_with_arguments = function(self, state, args)
		return args:match_parameter_tuple(state, self.parameters)
	end,
	format_parameters = function(self, state)
		return self.parameters:format(state)
	end,
	call_dispatched = function(self, state, args)
		state.scope:push()
		args:bind_parameter_tuple(state, self.parameters)

		local exp = self.expression:eval(state)

		state.scope:pop()

		-- reminder: don't do any additionnal processing here as that won't be executed when resuming self.expression
		-- instead wrap it in some additional node, like our friend ReturnBoundary

		return exp
	end,

	_eval = function(self, state)
		return Closure:new(Function:new(self.parameters:eval(state), self.expression, self.exports), state)
	end,

	_prepare = function(self, state)
		state.scope:push_export() -- recreate scope context that will be created by closure

		state.scope:push()
		self.parameters:prepare(state)
		self.expression:prepare(state)
		state.scope:pop()

		self.exports = state.scope:capture():list_exported(state)
		state.scope:pop()
	end,
}

package.loaded[...] = Function
Closure, ReturnBoundary = ast.Closure, ast.ReturnBoundary

return Function
