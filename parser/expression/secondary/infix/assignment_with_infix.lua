local ast = require("ast")
local Call, Identifier, ArgumentTuple = ast.Call, ast.Identifier, ast.ArgumentTuple

local assignment = require("parser.expression.secondary.infix.assignment")
local assignment_call = require("parser.expression.secondary.infix.assignment_call")

local infixes = require("common").regular_operators.infixes

local generated = {}

for _, infix in ipairs(infixes) do
	local operator = infix[1].."="
	local identifier = "_=_"
	local infix_identifier = "_"..infix[1].."_"

	table.insert(generated, assignment {
		operator = operator,
		identifier = identifier,
		build_ast = function(self, left, right)
			right = Call:new(Identifier:new(infix_identifier), ArgumentTuple:new(left, right))
			return assignment.build_ast(self, left, right)
		end
	})

	table.insert(generated, assignment_call {
		operator = operator,
		identifier = identifier,
		build_ast = function(self, left, right)
			right = Call:new(Identifier:new(infix_identifier), ArgumentTuple:new(left, right))
			return assignment_call.build_ast(self, left, right)
		end
	})
end

return generated
