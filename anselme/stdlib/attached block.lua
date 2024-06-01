--- # Attached block
--
-- The attached block can usually be accessed using the `_` variable. However, `_` is only defined in the scope of the line the block is attached to.
-- These functions are intended to be used to retrieve an attached block where `_` can not be used directly.
--
-- ```
-- // `if` use `attached block!` in order to obtain the attached block without needing to pass `_` as an argument
-- if(true)
-- 	print("hello")
-- ```
-- @titlelevel 3

local ast = require("anselme.ast")
local Function, ParameterTuple, Identifier = ast.Function, ast.ParameterTuple, ast.Identifier

local calling_environment_manager = require("anselme.state.calling_environment_manager")

local block_identifier = Identifier:new("_")

return {
	{
		--- Return the attached block (as a function).
		--
		-- `level` indicates the position on the call stack where the attached block should be searched. 0 is where `attached block` was called, 1 is where the function calling `attached block` was called, 2 is where the function calling the function that called `attached block` is called, etc.
		--
		-- ```
		-- // level is 1, `attached block` is called from `call attached block`: the attached block will be searched from where `call attached block` was called
		-- :$call attached block()
		-- 	:fn = attached block!
		-- 	fn!
		-- call attached block!
		-- 	print("hello")
		-- ```
		--
		-- ```
		-- // level is 0: the attached block is searched where `attached block` was called, i.e. the current scope
		-- :block = attached block(level=0)
		--		print("hello")
		-- block! // hello
		-- // which is the same as
		-- :block = $_
		-- 	print("hello")
		-- ```
		--
		-- if `keep return` is true, if the attached block function returns a return value when called, it will be returned as is (instead of unwrapping only the value associated with the return), and will therefore propagate the return to the current block.
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
		--- Same as the above function, but returns `default` if there is no attached block instead of throwing an error.
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
