local ast = require("anselme.ast")
local Function, ParameterTuple, Identifier = ast.Function, ast.ParameterTuple, ast.Identifier

local calling_environment_manager = require("anselme.state.calling_environment_manager")

local block_identifier = Identifier:new("_")

return {
	{
		"attached block", "(level::is number=1, keep return=false)",
		function(state, level, keep_return)
			-- level 2: env of the function that called the function that called attached block
			local env = calling_environment_manager:get_level(state, level:to_lua(state))
			local block = env:get(state, block_identifier).expression
			local fn
			if keep_return:truthy() then
				fn = Function:new(ParameterTuple:new(), block)
			else
				fn = Function:with_return_boundary(ParameterTuple:new(), block)
			end
			state.scope:push(env)
			fn = fn:eval(state) -- make closure
			state.scope:pop()
			return fn
		end
	},
	{
		"attached block", "(level::is number=1, keep return=false, default)",
		function(state, level, keep_return, default)
			-- level 2: env of the function that called the function that called attached block
			local env = calling_environment_manager:get_level(state, level:to_lua(state))
			if env:defined(state, block_identifier) then
				local block = env:get(state, block_identifier).expression
				local fn
				if keep_return:truthy() then
					fn = Function:new(ParameterTuple:new(), block)
				else
					fn = Function:with_return_boundary(ParameterTuple:new(), block)
				end
				state.scope:push(env)
				fn = fn:eval(state) -- make closure
				state.scope:pop()
				return fn
			else
				return default
			end
		end
	},
}
