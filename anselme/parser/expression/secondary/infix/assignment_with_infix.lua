local ast = require("anselme.ast")
local Call, Identifier, ArgumentTuple = ast.Call, ast.Identifier, ast.ArgumentTuple

local assignment = require("anselme.parser.expression.secondary.infix.assignment")
local assignment_call = require("anselme.parser.expression.secondary.infix.assignment_call")

local infixes = require("anselme.common").regular_operators.infixes
local operator_priority = require("anselme.common").operator_priority

local generated = {}

for _, infix in ipairs(infixes) do
	local compound_operator = infix[1].."="
	local identifier = "_=_"
	local infix_identifier = "_"..infix[1].."_"

	-- avoid a lot of unecessary trouble with <= & friends. why would you ever want to use i <= 7 as i = i < 7 anyway.
	if not operator_priority["_"..compound_operator.."_"] then
		table.insert(generated, assignment {
			operator = compound_operator,
			identifier = identifier,
			build_ast = function(self, left, right)
				right = Call:new(Identifier:new(infix_identifier), ArgumentTuple:new(left, right))
				return assignment.build_ast(self, left, right)
			end
		})

		table.insert(generated, assignment_call {
			operator = compound_operator,
			identifier = identifier,
			build_ast = function(self, left, right)
				right = Call:new(Identifier:new(infix_identifier), ArgumentTuple:new(left, right))
				return assignment_call.build_ast(self, left, right)
			end
		})
	end
end

return generated
