local ast = require("anselme.ast")
local Nil, Overloadable

local operator_priority = require("anselme.common").operator_priority

local Definition = ast.abstract.ResumeTarget {
	type = "definition",

	symbol = nil,
	expression = nil,

	init = function(self, symbol, expression)
		self.symbol = symbol
		self.expression = expression
	end,

	_format = function(self, ...)
		return self.symbol:format(...).." = "..self.expression:format_right(...)
	end,
	_format_priority = function(self)
		return operator_priority["_=_"]
	end,

	traverse = function(self, fn, ...)
		fn(self.symbol, ...)
		fn(self.expression, ...)
	end,

	_eval = function(self, state)
		if self.symbol.exported and state.scope:defined_in_current(self.symbol) then
			return Nil:new() -- export vars: can reuse existing definition
		end

		local symbol = self.symbol:eval(state)
		if symbol.alias then
			state.scope:define_alias(symbol, self.expression)
		else
			local val = self.expression:eval(state)

			if Overloadable:issub(val) then
				state.scope:define_overloadable(symbol, val)
			else
				state.scope:define(symbol, val)
			end
		end

		return Nil:new()
	end,
}

package.loaded[...] = Definition
Nil, Overloadable = ast.Nil, ast.abstract.Overloadable

return Definition
