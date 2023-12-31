local ast = require("anselme.ast")
local Nil, Boolean, Definition, Call, Function, ParameterTuple, FunctionParameter, Identifier, Overload, Assignment = ast.Nil, ast.Boolean, ast.Definition, ast.Call, ast.Function, ast.ParameterTuple, ast.FunctionParameter, ast.Identifier, ast.Overload, ast.Assignment
local assert0 = require("anselme.common").assert0

return {
	{
		"defined", "(c::closure, s::string)",
		function(state, c, s)
			return Boolean:new(c.scope:defined_in_current_strict(state, s:to_identifier()))
		end
	},
	{
		"has upvalue", "(c::closure, s::string)",
		function(state, c, s)
			return Boolean:new(c.scope:defined(state, s:to_identifier()))
		end
	},
	{
		"_._", "(c::closure, s::string)",
		function(state, c, s)
			local identifier = s:to_identifier()
			assert0(c.scope:defined(state, identifier), ("no variable %q defined in closure"):format(s.string))
			return c.scope:get(state, identifier)
		end
	},
	{
		"_._", "(c::closure, s::string) = v",
		function(state, c, s, v)
			local identifier = s:to_identifier()
			assert0(c.scope:defined(state, identifier), ("no variable %q defined in closure"):format(s.string))
			c.scope:set(state, identifier, v)
			return Nil:new()
		end
	},
	{
		"_._", "(c::closure, s::symbol) = v",
		function(state, c, s, v)
			state.scope:push(c.scope)
			local r = Definition:new(s, v):eval(state)
			state.scope:pop()
			return r
		end
	},
	{
		">_", "(q::is(\"quote\"))",
		function(state, q)
			local exp = q.expression
			local get = Function:new(ParameterTuple:new(), exp):eval(state)

			local set_exp
			if Call:is(exp) then
				set_exp = Call:new(exp.func, exp.arguments:with_assignment(Identifier:new("value")))
			elseif Identifier:is(exp) then
				set_exp = Assignment:new(exp, Identifier:new("value"))
			end

			if set_exp then
				local set_param = ParameterTuple:new()
				set_param:insert_assignment(FunctionParameter:new(Identifier:new("value")))
				local set = Function:new(set_param, set_exp):eval(state)
				return Overload:new(get, set)
			else
				return get
			end
		end
	}
}
