local ast = require("anselme.ast")
local Nil

local operator_priority = require("anselme.common").operator_priority

local Assignment = ast.abstract.Node {
	type = "assignment",

	identifier = nil,
	expression = nil,
	format_priority = operator_priority["_=_"],

	init = function(self, identifier, expression)
		self.identifier = identifier
		self.expression = expression
	end,

	_format = function(self, ...)
		return self.identifier:format(...).." = "..self.expression:format_right(...)
	end,

	traverse = function(self, fn, ...)
		fn(self.identifier, ...)
		fn(self.expression, ...)
	end,

	_eval = function(self, state)
		local val = self.expression:eval(state)
		state.scope:set(self.identifier, val)
		return Nil:new()
	end,
}

package.loaded[...] = Assignment
Nil = ast.Nil

return Assignment
