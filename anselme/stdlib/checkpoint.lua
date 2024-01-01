local ast = require("anselme.ast")
local ArgumentTuple, Boolean, Nil = ast.ArgumentTuple, ast.Boolean, ast.Nil

local resume_manager = require("anselme.state.resume_manager")

return {
	{
		"resume", "(function::closure, anchor::anchor)",
		function(state, func, anchor)
			return func:resume(state, anchor)
		end
	},
	{
		"resume", "(function::closure, anchor::nil)",
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
		"resuming", "(level::number)",
		function(state, level)
			local env = ast.Closure:get_level(state, level:to_lua(state))
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
	}
}
