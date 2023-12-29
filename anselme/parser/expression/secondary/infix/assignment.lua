local infix = require("anselme.parser.expression.secondary.infix.infix")
local escape = require("anselme.common").escape

local operator_priority = require("anselme.common").operator_priority

local ast = require("anselme.ast")
local Identifier, Assignment = ast.Identifier, ast.Assignment

return infix {
	operator = "=",
	identifier = "_=_",
	priority = operator_priority["_=_"],

	-- return bool
	match = function(self, str, current_priority, primary)
		local escaped = escape(self.operator)
		return self.priority > current_priority and str:match("^"..escaped) and Identifier:is(primary)
	end,

	build_ast = function(self, left, right)
		return Assignment:new(left, right)
	end
}
