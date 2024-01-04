local ast = require("anselme.ast")
local Call, Function, ParameterTuple, FunctionParameter, Identifier, Overload, Assignment = ast.Call, ast.Function, ast.ParameterTuple, ast.FunctionParameter, ast.Identifier, ast.Overload, ast.Assignment

return {
	{
		">_", "(q::is(\"quote\"))",
		function(state, q)
			local exp = q.expression
			local get = Function:with_return_boundary(ParameterTuple:new(), exp):eval(state)

			local set_exp
			if Call:is(exp) then
				set_exp = Call:new(exp.func, exp.arguments:with_assignment(Identifier:new("value")))
			elseif Identifier:is(exp) then
				set_exp = Assignment:new(exp, Identifier:new("value"))
			end

			if set_exp then
				local set_param = ParameterTuple:new()
				set_param:insert_assignment(FunctionParameter:new(Identifier:new("value")))
				local set = Function:with_return_boundary(set_param, set_exp):eval(state)
				return Overload:new(get, set)
			else
				return get
			end
		end
	},
}
