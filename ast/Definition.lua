local ast = require("ast")
local Nil, Overloadable

local operator_priority = require("common").operator_priority

local Definition = ast.abstract.Node {
	type = "definition",

	symbol = nil,
	expression = nil,
	format_priority = operator_priority["_=_"],

	init = function(self, symbol, expression)
		self.symbol = symbol
		self.expression = expression
	end,

	_format = function(self, ...)
		return self.symbol:format(...).." = "..self.expression:format_right(...)
	end,

	traverse = function(self, fn, ...)
		fn(self.symbol, ...)
		fn(self.expression, ...)
	end,

	_eval = function(self, state)
		if self.symbol.exported and state.scope:defined_in_current(self.symbol) then
			return Nil:new() -- export vars: can reuse existing defining
		end

		local symbol = self.symbol:eval(state)
		local val = self.expression:eval(state)

		if Overloadable:issub(val) then
			state.scope:define_overloadable(symbol, val)
		else
			state.scope:define(symbol, val)
		end

		return Nil:new()
	end,

	_prepare = function(self, state)
		local symbol, val = self.symbol, self.expression
		symbol:prepare(state)
		val:prepare(state)

		if Overloadable:issub(val) then
			state.scope:define_overloadable(symbol, val)
		else
			state.scope:define(symbol, val)
		end
	end
}

package.loaded[...] = Definition
Nil, Overloadable = ast.Nil, ast.abstract.Overloadable

return Definition
