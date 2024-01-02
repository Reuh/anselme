local ast = require("anselme.ast")
local Nil, Boolean, Definition, Call, Function, ParameterTuple, FunctionParameter, Identifier, Overload, Assignment, Return = ast.Nil, ast.Boolean, ast.Definition, ast.Call, ast.Function, ast.ParameterTuple, ast.FunctionParameter, ast.Identifier, ast.Overload, ast.Assignment, ast.Return
local assert0 = require("anselme.common").assert0

local calling_environment_manager = require("anselme.state.calling_environment_manager")

local block_identifier = Identifier:new("_")

return {
	{
		"defined", "(c::function, s::string)",
		function(state, c, s)
			return Boolean:new(c.scope:defined_in_current_strict(state, s:to_identifier()))
		end
	},
	{
		"has upvalue", "(c::function, s::string)",
		function(state, c, s)
			return Boolean:new(c.scope:defined(state, s:to_identifier()))
		end
	},
	{
		"_._", "(c::function, s::string)",
		function(state, c, s)
			local identifier = s:to_identifier()
			assert0(c.scope:defined(state, identifier), ("no variable %q defined in closure"):format(s.string))
			return c.scope:get(state, identifier)
		end
	},
	{
		"_._", "(c::function, s::string) = v",
		function(state, c, s, v)
			local identifier = s:to_identifier()
			assert0(c.scope:defined(state, identifier), ("no variable %q defined in closure"):format(s.string))
			c.scope:set(state, identifier, v)
			return Nil:new()
		end
	},
	{
		"_._", "(c::function, s::symbol) = v",
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
	{
		"return", "(value=())",
		function(state, val)
			if Return:is(val) then val = val.expression end
			return Return:new(val)
		end
	},
	{
		"break", "(value=())",
		function(state, val)
			if Return:is(val) then val = val.expression end
			return Return:new(val, "break")
		end
	},
	{
		"continue", "(value=())",
		function(state, val)
			if Return:is(val) then val = val.expression end
			return Return:new(val, "continue")
		end
	},
	{
		"attached block", "(level::number=1, keep return=false)",
		function(state, level, keep_return)
			-- level 2: env of the function that called the function that called attached block
			local env = calling_environment_manager:get_level(state, level:to_lua(state)+1)
			local r = env:get(state, block_identifier)
			if keep_return:truthy() then
				return Function:new(ParameterTuple:new(), r.expression):eval(state)
			else
				return Function:with_return_boundary(ParameterTuple:new(), r.expression):eval(state)
			end
		end
	},
	{
		"attached block", "(level::number=1, keep return=false, default)",
		function(state, level, keep_return, default)
			-- level 2: env of the function that called the function that called attached block
			local env = calling_environment_manager:get_level(state, level:to_lua(state)+1)
			if env:defined(state, block_identifier) then
				local r = env:get(state, block_identifier)
				if keep_return:truthy() then
					return Function:new(ParameterTuple:new(), r.expression):eval(state)
				else
					return Function:with_return_boundary(ParameterTuple:new(), r.expression):eval(state)
				end
			else
				return default
			end
		end
	},
}
