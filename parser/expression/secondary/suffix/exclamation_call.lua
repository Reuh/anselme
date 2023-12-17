local suffix = require("parser.expression.secondary.suffix.suffix")

local operator_priority = require("common").operator_priority

local ast = require("ast")
local Call, ArgumentTuple = ast.Call, ast.ArgumentTuple

return suffix {
	operator = "!",
	priority = operator_priority["_!"],

	build_ast = function(self, left)
		return Call:new(left, ArgumentTuple:new())
	end
}
