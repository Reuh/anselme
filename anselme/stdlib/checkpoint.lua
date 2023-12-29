local ast = require("anselme.ast")
local ArgumentTuple = ast.ArgumentTuple

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
	}
}
