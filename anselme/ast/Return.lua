local ast = require("anselme.ast")

local operator_priority = require("anselme.common").operator_priority

local Return
Return = ast.abstract.Node {
	type = "return",

	expression = nil,

	init = function(self, expression)
		self.expression = expression
	end,

	_format = function(self, ...)
		return ("@%s"):format(self.expression:format_right(...))
	end,
	_format_priority = function(self)
		return operator_priority["@_"]
	end,

	traverse = function(self, fn, ...)
		fn(self.expression, ...)
	end,

	_eval = function(self, state)
		return Return:new(self.expression:eval(state))
	end,

	to_lua = function(self, state)
		return self.expression:to_lua(state)
	end
}

return Return
