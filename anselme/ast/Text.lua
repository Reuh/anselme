local class = require("anselme.lib.class")
local ast = require("anselme.ast")
local Event, Runtime = ast.abstract.Event, ast.abstract.Runtime
local ArgumentTuple

local to_anselme = require("anselme.common.to_anselme")

local TextEventData
TextEventData = class {
	-- returns a list of TextEventData where the first element of each text of each TextEventData has the same value for the tag tag_name
	group_by = function(self, tag_name)
		local l = {}
		local current_group
		local tag_key = to_anselme(tag_name)
		local last_value
		for _, event in ipairs(self) do
			local list = event.list
			if #list > 0 then
				local value = list[1][2]:get_strict(tag_key)
				if (not current_group) or (last_value == nil and value) or (last_value and value == nil) or (last_value and value and last_value:hash() ~= value:hash()) then -- new group
					current_group = TextEventData:new()
					table.insert(l, current_group)
					last_value = value
				end
				table.insert(current_group, event) -- add to current group
			end
		end
		return l
	end,
}

local Text = Runtime(Event) {
	type = "text",

	list = nil, -- { { String, tag Struct }, ... }

	init = function(self)
		self.list = {}
	end,
	insert = function(self, str, tags) -- only for construction
		table.insert(self.list, { str, tags })
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

	-- autocall when used directly as a statement
	eval_statement = function(self, state)
		return self:call(state, ArgumentTuple:new())
	end,

	-- Text comes from TextInterpolation which already evals the contents

	build_event_data = function(self, state, event_buffer)
		local l = TextEventData:new()
		for _, event in event_buffer:iter(state) do
			table.insert(l, event)
		end
		return l
	end,
}

package.loaded[...] = Text
ArgumentTuple = ast.ArgumentTuple

return Text
