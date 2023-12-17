-- used stop propagating Return when leaving functions

local ast = require("ast")
local Return

local ReturnBoundary = ast.abstract.Node {
	type = "return boundary",

	expression = nil,

	init = function(self, expression)
		self.expression = expression
		self.format_priority = self.expression.format_priority
	end,

	_format = function(self, ...)
		return self.expression:format(...)
	end,

	traverse = function(self, fn, ...)
		fn(self.expression, ...)
	end,

	_eval = function(self, state)
		local exp = self.expression:eval(state)
		if Return:is(exp) then
			return exp.expression
		else
			return exp
		end
	end
}

package.loaded[...] = ReturnBoundary
Return = ast.Return

return ReturnBoundary
