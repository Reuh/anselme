local ast = require("ast")
local Nil, Choice = ast.Nil, ast.Choice

local event_manager = require("state.event_manager")

return {
	-- text
	{
		"_!", "(txt::text)",
		function(state, text)
			event_manager:write(state, text)
			return Nil:new()
		end
	},

	-- choice
	{
		"_|>_", "(txt::text, fn)",
		function(state, text, func)
			event_manager:write(state, Choice:new(text, func))
			return Nil:new()
		end
	},
}
