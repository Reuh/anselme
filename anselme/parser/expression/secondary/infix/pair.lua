local infix = require("anselme.parser.expression.secondary.infix.infix")

local operator_priority = require("anselme.common").operator_priority

local ast = require("anselme.ast")
local Call, Identifier, ArgumentTuple = ast.Call, ast.Identifier, ast.ArgumentTuple

return infix {
	operator = ":",
	identifier = "_:_",
	priority = operator_priority["_:_"],

	build_ast = function(self, left, right)
		if Identifier:is(left) and not left.parenthesied then
			left = left:to_string()
		end
		return Call:new(Identifier:new(self.identifier), ArgumentTuple:new(left, right))
	end
}
