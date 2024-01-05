local ast = require("anselme.ast")

local operator_priority = require("anselme.common").operator_priority

local format_identifier

local ArgumentTuple

local Typed
Typed = ast.abstract.Runtime {
	type = "typed",

	expression = nil,
	type_expression = nil,

	init = function(self, expression, type)
		self.expression = expression
		self.type_expression = type
	end,

	_format = function(self, state, prio, ...)
		-- try custom format
		if state and state.scope:defined(format_identifier) then
			local custom_format = format_identifier:eval(state)
			local args = ArgumentTuple:new(self)
			local fn, d_args = custom_format:dispatch(state, args)
			if fn then
				return custom_format:call(state, d_args):format(state, prio, ...)
			end
		end
		return ("type(%s, %s)"):format(self.expression:format(state, operator_priority["_,_"], ...), self.type_expression:format_right(state, operator_priority["_,_"], ...))
	end,

	traverse = function(self, fn, ...)
		fn(self.expression, ...)
		fn(self.type_expression, ...)
	end
}

package.loaded[...] = Typed
format_identifier = ast.Identifier:new("format")
ArgumentTuple = ast.ArgumentTuple

return Typed
