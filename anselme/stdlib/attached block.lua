local ast = require("anselme.ast")
local Function, ParameterTuple, Identifier = ast.Function, ast.ParameterTuple, ast.Identifier

local calling_environment_manager = require("anselme.state.calling_environment_manager")

local block_identifier = Identifier:new("_")

return {
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
