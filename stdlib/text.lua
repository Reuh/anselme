local ast = require("ast")
local Nil, Choice, AttachBlock, ArgumentTuple = ast.Nil, ast.Choice, ast.AttachBlock, ast.ArgumentTuple

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
			if func:contains_resume_target(state) then
				func:call(state, ArgumentTuple:new())
				event_manager:write_and_discard_on_flush(state, Choice:new(text, func))
			else
				event_manager:write(state, Choice:new(text, func))
			end
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