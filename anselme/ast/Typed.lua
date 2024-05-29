local ast = require("anselme.ast")

local operator_priority = require("anselme.common").operator_priority

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
		return ("type(%s, %s)"):format(self.expression:format(state, operator_priority["_,_"], ...), self.type_expression:format_right(state, operator_priority["_,_"], ...))
	end,

	traverse = function(self, fn, ...)
		fn(self.expression, ...)
		fn(self.type_expression, ...)
	end
}

return Typed
