local ast = require("anselme.ast")
local ArgumentTuple, Boolean, Nil = ast.ArgumentTuple, ast.Boolean, ast.Nil

local resume_manager = require("anselme.state.resume_manager")
local calling_environment_manager = require("anselme.state.calling_environment_manager")

return {
	{
		"from", "(function::function, anchor::anchor)",
		function(state, func, anchor)
			return func:resume(state, anchor)
		end
	},
	{
		"from", "(function::function, anchor::nil)",
		function(state, func)
			return func:call(state, ArgumentTuple:new())
		end
	},
	{
		"resuming", "()",
		function(state)
			return Boolean:new(resume_manager:resuming(state))
		end
	},
	{
		"resuming", "(level::number=0)",
		function(state, level)
			local env = calling_environment_manager:get_level(state, level:to_lua(state)+1)
			state.scope:push(env)
			local r = Boolean:new(resume_manager:resuming(state))
			state.scope:pop()
			return r
		end
	},
	{
		"resume target", "()",
		function(state)
			return resume_manager:get(state)
		end
	},
	{
		"merge branch", "()",
		function(state)
			state:merge()
			return Nil:new()
		end
	},
}