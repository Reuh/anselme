local class = require("class")

local ast = require("ast")
local Nil, String, List, Identifier = ast.Nil, ast.String, ast.List, ast.Identifier

-- list of event data
local event_buffer_identifier = Identifier:new("_event_buffer")
local event_buffer_symbol = event_buffer_identifier:to_symbol{ confined_to_branch = true } -- per-branch, global variables

-- type of currently buffered event
local last_event_type_identifier = Identifier:new("_last_event_type")
local last_event_type_symbol = last_event_type_identifier:to_symbol{ confined_to_branch = true }

return class {
	init = false,

	setup = function(self, state)
		state.scope:define(event_buffer_symbol, List:new(state))
		state.scope:define(last_event_type_symbol, Nil:new())
	end,
	reset = function(self, state)
		state.scope:set(event_buffer_identifier, List:new(state))
		state.scope:set(last_event_type_identifier, Nil:new())
	end,

	write = function(self, state, event)
		local current_type = state.scope:get(last_event_type_identifier):to_lua(state)
		if current_type ~= nil and current_type ~= event.type then
			self:flush(state)
		end
		state.scope:set(last_event_type_identifier, String:new(event.type))
		state.scope:get(event_buffer_identifier):insert(state, event)
	end,

	flush = function(self, state)
		local last_type = state.scope:get(last_event_type_identifier):to_lua(state)
		if last_type then
			local last_buffer = state.scope:get(event_buffer_identifier)
			local event_president = last_buffer:get(state, 1) -- elected representative of all concerned events
			-- yield event data
			local data = event_president:build_event_data(state, last_buffer)
			coroutine.yield(last_type, data)
			-- clear room for the future
			state.scope:set(last_event_type_identifier, Nil:new())
			state.scope:set(event_buffer_identifier, List:new(state))
			-- post callback
			if event_president.post_flush_callback then event_president:post_flush_callback(state, last_buffer, data) end
		end
	end,
	final_flush = function(self, state)
		while state.scope:get(last_event_type_identifier):to_lua(state) do self:flush(state) end
	end
}
