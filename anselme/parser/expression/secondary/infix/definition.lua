local infix = require("anselme.parser.expression.secondary.infix.infix")
local escape = require("anselme.common").escape

local operator_priority = require("anselme.common").operator_priority

local ast = require("anselme.ast")
local Definition, Symbol = ast.Definition, ast.Symbol

return infix {
	operator = "=",
	identifier = "_=_",
	priority = operator_priority["_=_"],

	match = function(self, str, current_priority, primary)
		local escaped = escape(self.operator)
		return self.priority > current_priority and str:match("^"..escaped) and Symbol:is(primary)
	end,

	build_ast = function(self, left, right)
		return Definition:new(left, right)
	end
}
