local class = require("anselme.lib.class")
local ast = require("anselme.ast")
local Event, Runtime = ast.abstract.Event, ast.abstract.Runtime
local ArgumentTuple, Struct

local to_anselme = require("anselme.common.to_anselme")

local group_text_by_tag_identifier

--- A Lua-friendly representation of an Anselme Text value.
-- They appear in both TextEventData and ChoiceEventData to represent the text that has to be shown.
--
-- It contains a list of _text parts_, which are parts of a single text, each part potentially having differrent tags attached.
-- A text will typically only consist of a single part unless it was built using text interpolation.
--
-- Each text part is a table containing `text` (string) and  `tags` (table) properties, for example: `{ text = "text part string", tags = { color = "red" } }`.
-- @title LuaText
-- @defer lua text
local LuaText
LuaText = class {
	-- [1] = { text = "string", tags = { tag_name = value, ... } }, ...

	_state = nil,

	--- Anselme Text value this was created from. For advanced usage only. See the source file [Text.lua](anselme/ast/Text.lua) for more information.
	-- @defer lua text
	raw = nil,

	init = function(self, text, state)
		self._state = state
		self.raw = text
		for _, e in ipairs(text.list) do
			table.insert(self, { text = e[1]:to_lua(state), tags = e[2]:to_lua(state) })
		end
	end,

	--- Returns a text representation of the LuaText, using Anselme's default formatting. Useful for debugging.
	--
	-- Usage: `print(luatext)`
	-- @defer lua text
	__tostring = function(self)
		return self.raw:format(self._state)
	end,

	-- Returns a simple table representation of this LuaText.
	-- This contains no metatable, method, or cycle; only the list part of this LuaText.
	-- { text = "string", tags = { tag_name = value, ... } }
	to_simple_table = function(self)
		local t = {}
		for _, part in ipairs(self) do
			table.insert(t, part)
		end
		return t
	end,
}

--- TextEventData represent the data returned by an event with the type `"text"`.
-- See the [language documentation](language.md#texts) for more details on how to create a text event.
--
-- A TextEventData contains a list of [LuaText](#luatext), each LuaText representing a separate line of the text event.
--
-- For example, the following Anselme script:
--
-- ```
-- | Hi!
-- | My name's John.
-- ```
-- will return a text event containing two LuaTexts, the first containing the text "Hi!" and the second "My name's John.".
--
-- Usage:
-- ```lua
-- local event_type, event_data = run_state:step()
-- if event_type == "text" then
-- 	-- event_data is a TextEventData, i.e. a list of LuaText
-- 	for _, luatext in ipairs(event_data) do
--  		-- luatext is a list of text parts { text = "text string", tags = { ... } }
-- 		for _, textpart in ipairs(luatext) do
-- 			write_text_part_with_color(textpart.text, textpart.tags.color)
-- 		end
-- 		write_text("\n") -- for example, if we want a newline between each text line
-- 	end
-- else
--	-- handle other event types...
-- end
-- ```
-- @title TextEventData
local TextEventData
TextEventData = class {
	-- [1] = LuaText, ...

	--- Returns a list of TextEventData where the first part of each LuaText of each TextEventData has the same value for the tag `tag_key`.
	--
	-- In other words, this groups all the LuaTexts contained in this TextEventData using the `tag_key` tag and returns a list containing these groups.
	--
	-- For example, with the following Anselme script:
	-- ```
	-- speaker: "John" #
	-- 	| A
	-- 	| B
	-- speaker: "Lana" #
	-- 	| C
	-- speaker: "John" #
	-- 	| D
	-- ```
	-- calling `text_event_data:group_by("speaker")` will return a list of three TextEventData:
	-- * the first with the texts "A" and "B"; both with the tag `speaker="John"`
	-- * the second with the text "C"; with the tag `speaker="Lana"`
	-- * the last with the text "D"; wiith the tag `speaker="John"`
	group_by = function(self, tag_key)
		if type(tag_key) == "string" then tag_key = to_anselme(tag_key) end
		local l = {}
		local current_group
		local last_value
		for _, luatext in ipairs(self) do
			local list = luatext.raw.list
			if #list > 0 then
				local value = list[1][2]:get_strict(tag_key)
				if (not current_group) or (last_value == nil and value) or (last_value and value == nil) or (last_value and value and last_value:hash() ~= value:hash()) then -- new group
					current_group = TextEventData:new()
					table.insert(l, current_group)
					last_value = value
				end
				table.insert(current_group, luatext) -- add to current group
			end
		end
		return l
	end,

	-- Returns a simple table representation of this TextEventData.
	-- This contains no metatable, method, or cycle; only a list of simple representation of LuaText (see LuaText:to_simple_table).
	-- { lua_text_1_simple, lua_text_2_simple, ... }
	to_simple_table = function(self)
		local t = {}
		for _, lua_text in ipairs(self) do
			table.insert(t, lua_text:to_simple_table())
		end
		return t
	end,
}

local Text
Text = Runtime(Event) {
	type = "text",

	list = nil, -- { { String, tag Struct }, ... }

	init = function(self)
		self.list = {}
	end,
	insert = function(self, str, tags) -- only for construction
		table.insert(self.list, { str, tags })
	end,

	with_tags = function(self, tags)
		local r = Text:new()
		for _, e in ipairs(self.list) do
			local t = Struct:new()
			t:include(e[2])
			t:include(tags)
			self:insert(e[1], t)
		end
		return r
	end,

	traverse = function(self, fn, ...)
		for _, e in ipairs(self.list) do
			fn(e[1], ...)
			fn(e[2], ...)
		end
	end,

	_format = function(self, ...)
		local t = {}
		for _, e in ipairs(self.list) do
			table.insert(t, ("%s%s"):format(e[2]:format(...), e[1]:format(...)))
		end
		return ("| %s |"):format(table.concat(t, " "))
	end,

	to_lua = function(self, state)
		return LuaText:new(self, state)
	end,

	-- autocall when used directly as a statement
	eval_statement = function(self, state)
		return self:call(state, ArgumentTuple:new())
	end,

	-- Text comes from TextInterpolation which already evals the contents

	build_event_data = function(self, state, event_buffer)
		local l = TextEventData:new()
		for _, text in event_buffer:iter(state) do
			table.insert(l, text:to_lua(state))
		end
		if state.scope:defined(group_text_by_tag_identifier) then
			local tag_key = state.scope:get(group_text_by_tag_identifier)
			return l:group_by(tag_key)
		else
			return { l }
		end
	end,
}

package.loaded[...] = Text
ArgumentTuple, Struct = ast.ArgumentTuple, ast.Struct
group_text_by_tag_identifier = ast.Identifier:new("_group_text_by_tag")

return Text
