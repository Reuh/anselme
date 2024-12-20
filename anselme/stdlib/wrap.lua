--- # Wrap operator
-- @titlelevel 3

local ast = require("anselme.ast")
local Call, Function, ParameterTuple, FunctionParameter, Identifier, Overload = ast.Call, ast.Function, ast.ParameterTuple, ast.FunctionParameter, ast.Identifier, ast.Overload

return {
	{
		--- Returns a new function or overload with `expression` as the function expression.
		--
		-- If `expression` is a function call or an identifier, this returns instead an overload of two functions,
		-- defined like `$<expression>` and `$() = v; <expression> = v`, where `<expression>` is replaced by `expression`.
		-- @title > expression
		">_", "(q::is(\"quote\"))",
		function(state, q)
			local exp = q.expression
			local get = Function:with_return_boundary(ParameterTuple:new(), exp):eval(state)

			local set_exp
			if Call:is(exp) then
				set_exp = Call:new(exp.func, exp.arguments:with_assignment(Identifier:new("value")))
			elseif Identifier:is(exp) then
				set_exp = Call:from_operator("_=_", q, Identifier:new("value"))
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
