--- # Text
-- @titlelevel 3

local ast = require("anselme.ast")
local Nil, Choice, PartialScope, ArgumentTuple, Identifier, Text = ast.Nil, ast.Choice, ast.PartialScope, ast.ArgumentTuple, ast.Identifier, ast.Text

local event_manager = require("anselme.state.event_manager")
local translation_manager = require("anselme.state.translation_manager")
local tag_manager = require("anselme.state.tag_manager")
local resume_manager = require("anselme.state.resume_manager")

local group_text_by_tag_identifier = Identifier:new("_group_text_by_tag")
local group_text_by_tag_symbol = group_text_by_tag_identifier:to_symbol { exported = true }

return {
	-- text
	{
		--- Concatenate two texts, returning a new text value.
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
		--- Write a text event in the event buffer using this text.
		"_!", "(txt::is text)",
		function(state, text)
			event_manager:write(state, text)
			return Nil:new()
		end
	},
	{
		--- Create and return a new text from `text`, with the tags from `tags` added.
		"tag", "(txt::is text, tags::is struct)",
		function(state, text, tags)
			return text:with_tags(tags)
		end
	},

	{
		--- Cause future text events to be each split into separate text event every time the value of the tag with the key `tag_key` changes.
		--
		-- For example, with the following Anselme script:
		-- ```
		-- group text by tag("speaker")
		-- speaker: "John" #
		-- 	| A
		-- 	| B
		-- speaker: "Lana" #
		-- 	| C
		-- speaker: "John" #
		-- 	| D
		-- ```
		-- will produce three separate text events instead of one:
		-- * the first with the texts "A" and "B"; both with the tag `speaker="John"`
		-- * the second with the text "C"; with the tag `speaker="Lana"`
		-- * the last with the text "D"; wiith the tag `speaker="John"`
		--
		-- This setting affect will affect the whole state.
		"group text by tag", "(tag::is string)",
		function(state, tag)
			if not state.scope:defined(group_text_by_tag_identifier) then
				state.scope:define(group_text_by_tag_symbol, tag)
			else
				state.scope:set(group_text_by_tag_identifier, tag)
			end
			return Nil:new()
		end
	},

	-- choice
	{
		--- Write a choice event to the event buffer using this text and `fn` as the function to call if the choice is selected.
		--
		-- The same function is also defined in the `*_` operator:
		-- ```
		-- *| Choice
		-- 	42
		-- // is the same as
		-- write choice(| Choice |, $42)
		-- ```
		--
		-- If we are currently resuming to an anchor contained in `fn`, `fn` is directly called and the current choice event buffer will be discarded on flush, simulating the choice event buffer being sent to the host game and this choice being selected.
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
		--- Add a translation so `original` is replaced with `translated`.
		-- @title original -> translated
		"_->_", "(original::is(\"quote\"), translated::is(\"quote\"))",
		function(state, original, translated)
			local exp = PartialScope:preserve(state, translated.expression, Identifier:new("_"))
			translation_manager:set(state, tag_manager:get(state), original.expression, exp)
			return Nil:new()
		end
	}
}
