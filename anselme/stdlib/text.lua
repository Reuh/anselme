local ast = require("anselme.ast")
local Nil, Choice, PartialScope, ArgumentTuple, Identifier, Text = ast.Nil, ast.Choice, ast.PartialScope, ast.ArgumentTuple, ast.Identifier, ast.Text

local event_manager = require("anselme.state.event_manager")
local translation_manager = require("anselme.state.translation_manager")
local tag_manager = require("anselme.state.tag_manager")
local resume_manager = require("anselme.state.resume_manager")

return {
	-- text
	{
		"_+_", "(a::is text, b::is text)",
		function(state, a, b)
			local r = Text:new()
			for _, e in ipairs(a.list) do
				r:insert(e[1], e[2])
			end
			for _, e in ipairs(b.list) do
				r:insert(e[1], e[2])
			end
			return r
		end
	},
	{
		"_!", "(txt::is text)",
		function(state, text)
			event_manager:write(state, text)
			return Nil:new()
		end
	},
	{
		"tag", "(txt::is text, tags::is struct)",
		function(state, text, tags)
			return text:with_tags(tags)
		end
	},

	-- choice
	{
		"write choice", "(text::is text, fn=attached block(keep return=true, default=($()())))",
		function(state, text, func)
			if func:contains_current_resume_target(state) then
				func:call(state, ArgumentTuple:new())
				event_manager:write_and_discard_following(state, Choice:new(text, func), resume_manager:resuming_environment(state))
			else
				event_manager:write(state, Choice:new(text, func))
			end
			return Nil:new()
		end,
		alias = { "*_" }
	},

	-- translation
	{
		"_->_", "(original::is(\"quote\"), translated::is(\"quote\"))",
		function(state, original, translated)
			local exp = PartialScope:preserve(state, translated.expression, Identifier:new("_"))
			translation_manager:set(state, tag_manager:get(state), original.expression, exp)
			return Nil:new()
		end
	}
}
