--- ## Resuming functions
--
-- Instead of starting from the beginning of the function expression each time, functions can be started from any anchor anchor literal present in the function expression using the functions resuming functions described below.
--
-- ```
-- :$f
-- 	print(1)
-- 	#anchor
-- 	print(2)
-- f!from(#anchor) // 2
-- f! // 1, 2
-- ```
--
-- To execute a function from an anchor, or _resuming_ a function, Anselme, when evaluating a block, simply skip any line that does not contain the anchor literal (either in the line itself or its attached block) until we reach the anchor.
--
-- ```
-- :$f
-- 	print("not run")
-- 	(print("run"), _)
-- 		print("not run")
-- 		#anchor
-- 		print("run")
-- 	print("run")
-- f!from(#anchor)
-- ```
-- @titlelevel 3

local ast = require("anselme.ast")
local ArgumentTuple, Boolean, Nil = ast.ArgumentTuple, ast.Boolean, ast.Nil

local resume_manager = require("anselme.state.resume_manager")
local event_manager = require("anselme.state.event_manager")
local calling_environment_manager = require("anselme.state.calling_environment_manager")

return {
	{
		--- Call the function `function` with no arguments, starting from the anchor `anchor`.
		"from", "(function::is function, anchor::is anchor)",
		function(state, func, anchor)
			return func:resume(state, anchor)
		end
	},
	{
		--- Call the function `function` with no arguments, starting from the beginning.
		"from", "(function::is function, anchor::is nil=())",
		function(state, func)
			return func:call(state, ArgumentTuple:new())
		end
	},
	{
		--- Returns true if we are currently resuming the function call (i.e. the function started from a anchor instead of its beginning).
		--
		-- `level` indicates the position on the call stack where the resuming status should be checked. 0 is where `resuming` was called, 1 is where the function calling `resuming` was called, 2 is where the function calling the function that called `resuming` is called, etc.
		"resuming", "(level::is number=0)",
		function(state, level)
			local env = calling_environment_manager:get_level(state, level:to_lua(state))
			state.scope:push(env)
			local r = Boolean:new(resume_manager:resuming(state))
			state.scope:pop()
			return r
		end
	},
	{
		--- Returns the current resuming target (an anchor).
		"resume target", "()",
		function(state)
			return resume_manager:get(state)
		end
	},
	{
		--- Merge all variables defined or changed in the branch back into the parent branch.
		--
		-- If `complete flush` is true, all waiting events will be flushed until no events remain before merging the state.
		"merge branch", "(complete flush=true)",
		function(state, complete_flush)
			if complete_flush:truthy() then
				event_manager:complete_flush(state)
			end
			state:merge()
			return Nil:new()
		end
	},
}
