local class = require("anselme.lib.class")
local ast = require("anselme.ast")
local ArgumentTuple
local Event = ast.abstract.Event

local operator_priority = require("anselme.common").operator_priority

--- ChoiceEventData represent the data returned by an event with the type `"choice"`.
-- See the [language documentation](language.md#choices) for more details on how to create a choice event.
--
-- A ChoiceEventData contains a list of [LuaText](#luatext), each LuaText representing a separate choice of the choice event.
--
-- For example, the following Anselme script:
--
-- ```
-- *| Yes!
-- *| No.
-- ```
-- will return a choice event containing two LuaTexts, the first containing the text "Yes!" and the second "No.".
--
-- Usage:
-- ```lua
-- current_choice = nil
-- waiting_for_choice = false
--
-- -- in your anselem event handling loop:
-- if not waiting_for_choice then
-- 	local event_type, event_data = run_state:step()
-- 	if event_type == "choice" then
-- 		-- event_data is a ChoiceEventData, i.e. a list of LuaText
-- 		for i, luatext in ipairs(event_data) do
-- 			write(("Choice number %s:"):format(i))
--  			-- luatext is a list of text parts { text = "text string", tags = { ... } }
-- 			for _, textpart in ipairs(luatext) do
-- 				write_choice_part_with_color(textpart.text, textpart.tags.color)
-- 			end
-- 		else
-- 		-- handle other event types...
-- 		end
-- 		current_choice = event_data
-- 		waiting_for_choice = true
-- 	end
-- end
--
-- -- somewhere in your code where choices are selected
-- current_choice:select(choice_number)
-- waiting_for_choice = false
-- ```
-- @title ChoiceEventData
local ChoiceEventData = class {
	-- [1] = LuaText, ...

	_selected = nil,

	--- Choose the choice at position `choice` (number).
	--
	-- A choice must be selected after receiving a choice event and before calling `:step` again.
	choose = function(self, choice)
		self._selected = choice
	end
}

local Choice
Choice = ast.abstract.Runtime(Event) {
	type = "choice",

	text = nil,
	func = nil,

	init = function(self, text, func)
		self.text = text
		self.func = func
	end,

	traverse = function(self, fn, ...)
		fn(self.text, ...)
		fn(self.func, ...)
	end,

	_format = function(self, state, prio, ...)
		return ("write choice(%s, %s)"):format(self.text:format(state, operator_priority["_,_"], ...), self.func:format_right(state, operator_priority["_,_"], ...))
	end,

	build_event_data = function(self, state, event_buffer)
		local l = ChoiceEventData:new()
		for _, c in event_buffer:iter(state) do
			table.insert(l, c.text:to_lua(state))
		end
		return l
	end,
	post_flush_callback = function(self, state, event_buffer, data)
		local choice = data._selected
		assert(choice, "no choice made")
		assert(choice > 0 and choice <= event_buffer:len(state), "choice out of bounds")

		event_buffer:get(state, choice).func:call(state, ArgumentTuple:new())
	end
}

package.loaded[...] = Choice
ArgumentTuple = ast.ArgumentTuple

return Choice
