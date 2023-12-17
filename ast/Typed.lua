local ast = require("ast")

local operator_priority = require("common").operator_priority

return ast.abstract.Runtime {
	type = "typed",

	expression = nil,
	type_expression = nil,

	init = function(self, type, expression)
		self.type_expression = type
		self.expression = expression
	end,

	_format = function(self, state, prio, ...)
		return ("type(%s, %s)"):format(self.type_expression:format(state, operator_priority["_,_"], ...), self.expression:format_right(state, operator_priority["_,_"], ...))
	end,

	traverse = function(self, fn, ...)
		fn(self.type_expression, ...)
		fn(self.expression, ...)
	end
}
