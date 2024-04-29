local class = require("anselme.lib.class")

local ast = require("anselme.ast")
local Nil, String, List, Identifier = ast.Nil, ast.String, ast.List, ast.Identifier

-- list of event data
local event_buffer_identifier = Identifier:new("_event_buffer")
local event_buffer_symbol = event_buffer_identifier:to_symbol{ confined_to_branch = true } -- per-branch, global variables

-- type of currently buffered event
local last_event_type_identifier = Identifier:new("_last_event_type")
local last_event_type_symbol = last_event_type_identifier:to_symbol{ confined_to_branch = true }

-- (per-scope) indicate if we should discard write to an event type
local discard_next_events_identifier = Identifier:new("_discard_next_events")
local discard_next_events_symbol = discard_next_events_identifier:to_symbol{ confined_to_branch = true }

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

	-- write an event into the event buffer
	-- will flush if an event of a different type is present in the buffer
	write = function(self, state, event)
		-- discard if requested
		if state.scope:defined(discard_next_events_identifier) then
			local discard_type = state.scope:get(discard_next_events_identifier):to_lua()
			if discard_type == event.type then
				return
			elseif discard_type ~= nil then
				state.scope:set(discard_next_events_identifier, Nil:new()) -- fake flush the discarded events
			end
		end
		-- flush until no event of same type
		repeat
			local current_type = state.scope:get(last_event_type_identifier):to_lua(state)
			if current_type ~= nil and current_type ~= event.type then
				self:flush(state)
			end
		until current_type == nil or current_type == event.type
		-- write
		state.scope:set(last_event_type_identifier, String:new(event.type))
		state.scope:get(event_buffer_identifier):insert(state, event)
	end,
	-- same as :write, but will not actually write the event, instead discarding all immediately following event of the same type in the same scope and children
	write_and_discard_following = function(self, state, event, scope)
		if not scope:defined_in_current(state, discard_next_events_symbol) then
			scope:define(state, discard_next_events_symbol, String:new(event.type))
		else
			scope:set(state, discard_next_events_identifier, String:new(event.type))
		end
	end,

	-- flush the event buffer: build the event data and yield it
	flush = function(self, state)
		local last_type = state.scope:get(last_event_type_identifier):to_lua(state)
		if last_type then
			local last_buffer = state.scope:get(event_buffer_identifier)
			local event_president = last_buffer:get(state, 1) -- elected representative of all concerned events
			-- yield event data
			local data = event_president:build_event_data(state, last_buffer)
			coroutine.yield(last_type, data)
			-- clear room for the future
			self:reset(state)
			-- post callback
			if event_president.post_flush_callback then event_president:post_flush_callback(state, last_buffer, data) end
		end
	end,
	-- keep flushing until nothing is left (a flush may re-fill the buffer during its execution)
	complete_flush = function(self, state)
		while state.scope:get(last_event_type_identifier):to_lua(state) do self:flush(state) end
	end
}
