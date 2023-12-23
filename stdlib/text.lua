local ast = require("ast")
local Nil, Choice, AttachBlock = ast.Nil, ast.Choice, ast.AttachBlock

local event_manager = require("state.event_manager")
local translation_manager = require("state.translation_manager")
local tag_manager = require("state.tag_manager")

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

	-- translation
	{
		"_->_", "(original::is(\"quote\"), translated::is(\"quote\"))",
		function(state, original, translated)
			translation_manager:set(state, tag_manager:get(state), original.expression, AttachBlock:preserve(state, translated.expression))
			return Nil:new()
		end
	}
}
