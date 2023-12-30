local ast = require("anselme.ast")
local ArgumentTuple, Boolean = ast.ArgumentTuple, ast.Boolean

local resume_manager = require("anselme.state.resume_manager")

return {
	{
		"_~>_", "(anchor::anchor, quote)",
		function(state, anchor, quote)
			resume_manager:push(state, anchor)
			local r = quote:call(state, ArgumentTuple:new())
			resume_manager:pop(state)
			return r
		end
	},
	{
		"_~>_", "(anchor::nil, quote)",
		function(state, anchor, quote)
			return quote:call(state, ArgumentTuple:new())
		end
	},
	{
		"resume", "(function::closure, anchor::anchor)",
		function(state, func, anchor)
			return func:resume(state, anchor)
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
}
