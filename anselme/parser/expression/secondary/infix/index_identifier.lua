local escape = require("anselme.common").escape

local infix = require("anselme.parser.expression.secondary.infix.infix")
local identifier = require("anselme.parser.expression.primary.identifier")

local operator_priority = require("anselme.common").operator_priority

local ast = require("anselme.ast")
local Call, Identifier, ArgumentTuple = ast.Call, ast.Identifier, ast.ArgumentTuple

return infix {
	operator = ".",
	identifier = "_._",
	priority = operator_priority["_._"],

	match = function(self, str, current_priority, primary)
		local escaped = escape(self.operator)
		return self.priority > current_priority and str:match("^"..escaped) and identifier:match(str:match("^.(.-)$"))
	end,

	build_ast = function(self, left, right)
		assert(Identifier:is(right))
		return Call:new(Identifier:new(self.identifier), ArgumentTuple:new(left, right:to_string()))
	end
}
