-- note: functions only appear in non-evaluated nodes! once evaluated, they always become closures

local ast = require("anselme.ast")
local Overloadable = ast.abstract.Overloadable
local Closure, ReturnBoundary

local operator_priority = require("anselme.common").operator_priority

local Function
Function = Overloadable {
	type = "function",

	parameters = nil, -- ParameterTuple
	expression = nil,

	init = function(self, parameters, expression)
		self.parameters = parameters
		self.expression = ReturnBoundary:new(expression)
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

		-- reminder: don't do any additionnal processing here as that won't be executed when resuming self.expression directly
		-- which is done in a few places, notably to predefine exports in Closure
		-- instead wrap it in some additional node, like our friend ReturnBoundary

		return exp
	end,

	_eval = function(self, state)
		return Closure:new(Function:new(self.parameters:eval(state), self.expression), state)
	end,
}

package.loaded[...] = Function
Closure, ReturnBoundary = ast.Closure, ast.ReturnBoundary

return Function
