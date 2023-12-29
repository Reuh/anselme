local suffix = require("anselme.parser.expression.secondary.suffix.suffix")

local operator_priority = require("anselme.common").operator_priority

local ast = require("anselme.ast")
local Call, ArgumentTuple = ast.Call, ast.ArgumentTuple

return suffix {
	operator = "!",
	priority = operator_priority["_!"],

	build_ast = function(self, left)
		return Call:new(left, ArgumentTuple:new())
	end
}
