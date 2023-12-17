local infix = require("parser.expression.secondary.infix.infix")

local operator_priority = require("common").operator_priority

local ast = require("ast")
local Call, Identifier, ArgumentTuple, ResumeParentFunction, ParameterTuple, Function = ast.Call, ast.Identifier, ast.ArgumentTuple, ast.ResumeParentFunction, ast.ParameterTuple, ast.Function

return infix {
	operator = "|>",
	identifier = "_|>_",
	priority = operator_priority["_|>_"],

	build_ast = function(self, left, right)
		right = Function:new(ParameterTuple:new(), ResumeParentFunction:new(right))
		return Call:new(Identifier:new(self.identifier), ArgumentTuple:new(left, right))
	end
}
