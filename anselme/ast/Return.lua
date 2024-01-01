local ast = require("anselme.ast")

local Return
Return = ast.abstract.Runtime {
	type = "return",

	expression = nil,
	subtype = nil, -- string; "break" or "continue"

	init = function(self, expression, subtype)
		self.expression = expression
		self.subtype = subtype
	end,

	_format = function(self, ...)
		if self.subtype then
			return ("return(%s, %s)"):format(self.expression:format(...), self.subtype)
		else
			return ("return(%s)"):format(self.expression:format(...))
		end
	end,

	traverse = function(self, fn, ...)
		fn(self.expression, ...)
	end,

	to_lua = function(self, state)
		return self.expression:to_lua(state)
	end
}

return Return
