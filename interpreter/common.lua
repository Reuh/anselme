local atypes, ltypes
local eval, run_block

local function post_process_text(state, text)
	-- remove trailing spaces
	if state.feature_flags["strip trailing spaces"] then
		local final = text[#text]
		if final then
			final.text = final.text:match("^(.-) *$")
			if final.text == "" then
				table.remove(text)
			end
		end
	end
	-- remove duplicate spaces
	if state.feature_flags["strip duplicate spaces"] then
		for i=1, #text-1 do
			local a, b = text[i], text[i+1]
			local na = #a.text:match(" *$")
			local nb = #b.text:match("^ *")
			if na > 0 and nb > 0 then -- remove duplicated spaces from second element first
				b.text = b.text:match("^ *(.-)$")
			end
			if na > 1 then
				a.text = a.text:match("^(.- ) *$")
			end
		end
	end
end

local common
common = {
	--- merge interpreter state with global state
	merge_state = function(state)
		-- merge alias state
		local global = state.interpreter.global_state
		for alias, fqm in pairs(state.aliases) do
			global.aliases[alias] = fqm
			state.aliases[alias] = nil
		end
		-- variable state
		-- move values modifed in-place from read cache to variables
		local cache = getmetatable(state.variables).cache
		for var, value in pairs(cache) do
			if value.modified then
				value.modified = nil
				state.variables[var] = value
			end
			cache[var] = nil
		end
		-- merge modified variables
		for var, value in pairs(state.variables) do
			global.variables[var] = value
			state.variables[var] = nil
		end
	end,
	--- returns a variable's value, evaluating a pending expression if neccessary
	-- if you're sure the variable has already been evaluated, use state.variables[fqm] directly
	-- return var
	-- return nil, err
	get_variable = function(state, fqm)
		local var = state.variables[fqm]
		if var.type == "pending definition" then
			local v, e = eval(state, var.value.expression)
			if not v then
				return nil, ("%s; while evaluating default value for variable %q defined at %s"):format(e, fqm, var.value.source)
			end
			state.variables[fqm] = v
			return v
		else
			return var
		end
	end,
	--- check truthyness of an anselme value
	truthy = function(val)
		if val.type == "number" then
			return val.value ~= 0
		elseif val.type == "nil" then
			return false
		else
			return true
		end
	end,
	--- compare two anselme value for equality
	compare = function(a, b)
		if a.type ~= b.type then
			return false
		end
		if a.type == "pair" or a.type == "type" then
			return common.compare(a.value[1], b.value[1]) and common.compare(a.value[2], b.value[2])
		elseif a.type == "list" then
			if #a.value ~= #b.value then
				return false
			end
			for i, v in ipairs(a.value) do
				if not common.compare(v, b.value[i]) then
					return false
				end
			end
			return true
		else
			return a.value == b.value
		end
	end,
	--- format a anselme value to something printable
	-- does not call custom {}() functions, only built-in ones, so it should not be able to fail
	-- str: if success
	-- nil, err: if error
	format = function(val)
		if atypes[val.type] and atypes[val.type].format then
			return atypes[val.type].format(val.value)
		else
			return nil, ("no formatter for type %q"):format(val.type)
		end
	end,
	--- convert anselme value to lua
	-- lua value: if success (may be nil!)
	-- nil, err: if error
	to_lua = function(val)
		if atypes[val.type] and atypes[val.type].to_lua then
			return atypes[val.type].to_lua(val.value)
		else
			return nil, ("no Lua exporter for type %q"):format(val.type)
		end
	end,
	--- convert lua value to anselme
	-- anselme value: if success
	-- nil, err: if error
	from_lua = function(val)
		if ltypes[type(val)] and ltypes[type(val)].to_anselme then
			return ltypes[type(val)].to_anselme(val)
		else
			return nil, ("no Lua importer for type %q"):format(type(val))
		end
	end,
	--- evaluate a text AST into a single Lua string
	-- string: if success
	-- nil, err: if error
	eval_text = function(state, text)
		local l = {}
		common.eval_text_callback(state, text, function(str) table.insert(l, str) end)
		return table.concat(l)
	end,
	--- same as eval_text, but instead of building a Lua string, call callback for every evaluated part of the text
	-- callback returns nil, err in case of error
	-- true: if success
	-- nil, err: if error
	eval_text_callback = function(state, text, callback)
		for _, item in ipairs(text) do
			if type(item) == "string" then
				callback(item)
			else
				local v, e = eval(state, item)
				if not v then return v, e end
				v, e = common.format(v)
				if not v then return v, e end
				if v ~= "" then
					local r, err = callback(v)
					if err then return r, err end
				end
			end
		end
		return true
	end,
	--- check if an anselme value is of a certain type
	-- specificity(number): if var is of type type
	-- false: if not
	is_of_type = function(var, type)
		local depth = 1
		-- var has a custom type
		if var.type == "type" then
			local var_type = var.value[2]
			while true do
				if common.compare(var_type, type) then -- same type
					return depth
				elseif var_type.type == "type" then -- compare parent type
					depth = depth + 1
					var_type = var_type.value[2]
				else -- no parent, fall back on base type
					depth = depth + 1
					var = var.value[1]
					break
				end
			end
		end
		-- var has a base type
		return type.type == "string" and type.value == var.type and depth
	end,
	-- return a pretty printable type value for var
	pretty_type = function(var)
		if var.type == "type" then
			return common.format(var.value[2])
		else
			return var.type
		end
	end,
	--- tag management
	tags = {
		--- push new tags on top of the stack, from Anselme values
		push = function(self, state, val)
			local new = {}
			-- copy
			local last = self:current(state)
			for k,v in pairs(last) do new[k] = v end
			-- merge with new values
			if val.type ~= "list" then val = { type = "list", value = { val } } end
			for k, v in pairs(common.to_lua(val)) do new[k] = v end
			-- add
			table.insert(state.interpreter.tags, new)
		end,
		--- same but do not merge with last stack item
		push_lua_no_merge = function(self, state, val)
			table.insert(state.interpreter.tags, val)
		end,
		-- pop tag table on top of the stack
		pop = function(self, state)
			table.remove(state.interpreter.tags)
		end,
		--- return current lua tags table
		current = function(self, state)
			return state.interpreter.tags[#state.interpreter.tags] or {}
		end,
		--- returns length of tags stack
		len = function(self, state)
			return #state.interpreter.tags
		end,
		--- pop item until we reached desired stack length
		-- so in case there's a possibility to mess up the stack somehow, it will restore the stack to a good state
		trim = function(self, state, len)
			while #state.interpreter.tags > len do
				self:pop(state)
			end
		end
	},
	--- event buffer management
	-- i.e. only for text and choice events
	events = {
		--- add a new element to the last event in the current buffer
		-- will create new event if needed
		append = function(self, state, type, data)
			local buffer = self:current_buffer(state)
			local last = buffer[#buffer]
			if not last or last.type ~= type then
				last = { type = type }
				table.insert(buffer, last)
			end
			table.insert(last, data)
		end,

		--- new events will be collected in this event buffer (any table) until the next pop
		-- this is handled by a stack so nesting is allowed
		push_buffer = function(self, state, buffer)
			table.insert(state.interpreter.event_buffer_stack, buffer)
		end,
		--- stop capturing events of a certain type.
		-- must be called after a push_buffer
		pop_buffer = function(self, state)
			table.remove(state.interpreter.event_buffer_stack)
		end,
		--- returns the current buffer
		current_buffer = function(self, state)
			return state.interpreter.event_buffer_stack[#state.interpreter.event_buffer_stack]
		end,

		-- flush event buffer if it's neccessary to push an event of the given type
		-- returns true in case of success
		-- returns nil, err in case of error
		make_space_for = function(self, state, type)
			if #state.interpreter.event_buffer_stack == 0 and state.interpreter.current_event and state.interpreter.current_event.type ~= type then -- FIXME useful?
				return self:manual_flush(state)
			end
			return true
		end,

		--- write all the data in a buffer into the current buffer, or to the game is no buffer is currently set
		write_buffer = function(self, state, buffer)
			for _, event in ipairs(buffer) do
				if #state.interpreter.event_buffer_stack == 0 then
					if event.type == "flush" then
						local r, e = self:manual_flush(state)
						if not r then return r, e end
					elseif state.interpreter.current_event then
						if state.interpreter.current_event.type == event.type then
							for _, v in ipairs(event) do
								table.insert(state.interpreter.current_event, v)
							end
						else
							local r, e = self:manual_flush(state)
							if not r then return r, e end
							state.interpreter.current_event = event
						end
					else
						state.interpreter.current_event = event
					end
				else
					local current_buffer = self:current_buffer(state)
					table.insert(current_buffer, event)
				end
			end
			return true
		end,

		--- same as manual_flush but add the flush to the current buffer if one is set instead of directly to the game
		flush = function(self, state)
			if #state.interpreter.event_buffer_stack == 0 then
				return self:manual_flush(state)
			else
				local current_buffer = self:current_buffer(state)
				table.insert(current_buffer, { type = "flush" })
				return true
			end
		end,

		--- flush events and send them to the game if possible
		-- returns true in case of success
		-- returns nil, err in case of error
		manual_flush = function(self, state)
			while state.interpreter.current_event do
				local event = state.interpreter.current_event
				state.interpreter.current_event = nil

				local type, buffer = event.type, event
				buffer.type = nil

				state.interpreter.skip_choices_until_flush = nil

				-- choice processing
				local choices
				if type == "choice" then
					choices = {}
					-- discard empty choices
					for i=#buffer, 1, -1 do
						if #buffer[i] == 0 then
							table.remove(buffer, i)
						end
					end
					-- extract some needed state data for each choice block
					for _, c in ipairs(buffer) do
						table.insert(choices, c._state)
						c._state = nil
					end
					-- nervermind
					if #choices == 0 then
						return true
					end
				end
				-- text & choice text content post processing
				if type == "text" then
					post_process_text(state, buffer)
				end
				if type == "choice" then
					for _, c in ipairs(buffer) do
						post_process_text(state, c)
					end
				end
				-- yield event
				coroutine.yield(type, buffer)
				-- run choice
				if type == "choice" then
					local sel = state.interpreter.choice_selected
					state.interpreter.choice_selected = nil
					if not sel or sel < 1 or sel > #choices then
						return nil, "invalid choice"
					else
						local choice = choices[sel]
						-- execute in expected tag & event capture state
						local capture_state = state.interpreter.event_capture_stack
						state.interpreter.event_capture_stack = {}
						common.tags:push_lua_no_merge(state, choice.tags)
						local _, e = run_block(state, choice.block)
						common.tags:pop(state)
						state.interpreter.event_capture_stack = capture_state
						if e then return nil, e end
						-- we discard return value from choice block as the execution is delayed until an event flush
						-- and we don't want to stop the execution of another function unexpectedly
					end
				end
			end
			return true
		end
	}
}

package.loaded[...] = common
local types = require((...):gsub("interpreter%.common$", "stdlib.types"))
atypes, ltypes = types.anselme, types.lua
eval = require((...):gsub("common$", "expression"))
run_block = require((...):gsub("common$", "interpreter")).run_block

return common
