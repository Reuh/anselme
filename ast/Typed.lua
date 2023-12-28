local ast = require("ast")

local operator_priority = require("common").operator_priority

local format_identifier

local Typed
Typed = ast.abstract.Runtime {
	type = "typed",

	expression = nil,
	type_expression = nil,

	init = function(self, type, expression)
		self.type_expression = type
		self.expression = expression
	end,

	_format = function(self, state, prio, ...)
		-- try custom format
		if state and state.scope:defined(format_identifier) then
			local custom_format = format_identifier:eval(state)
			local args = ast.ArgumentTuple:new(self)
			local fn, d_args = custom_format:dispatch(state, args)
			if fn then
				return custom_format:call(state, d_args):format(state, prio, ...)
			end
		end
		return ("type(%s, %s)"):format(self.type_expression:format(state, operator_priority["_,_"], ...), self.expression:format_right(state, operator_priority["_,_"], ...))
	end,

	traverse = function(self, fn, ...)
		fn(self.type_expression, ...)
		fn(self.expression, ...)
	end
}

package.loaded[...] = Typed
format_identifier = ast.Identifier:new("format")

return Typed
