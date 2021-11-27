local eval
local truthy, merge_state, to_lua, escape, get_variable, eval_text_callback
local run_line, run_block

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

--- tag management
local tags = {
	--- push new tags on top of the stack, from Anselme values
	push = function(self, state, val)
		local new = {}
		-- copy
		local last = self:current(state)
		for k,v in pairs(last) do new[k] = v end
		-- merge with new values
		if val.type ~= "list" then val = { type = "list", value = { val } } end
		for k, v in pairs(to_lua(val)) do new[k] = v end
		-- add
		table.insert(state.interpreter.tags, new)
		return self:len(state)
	end,
	--- same but do not merge with last stack item
	push_lua_no_merge = function(self, state, val)
		table.insert(state.interpreter.tags, val)
		return self:len(state)
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
	-- try to prefer this to pop if possible, so in case we mess up the stack somehow it will restore the stack to a good state
	-- (we may allow tag push/pop from the user side at some point)
	trim = function(self, state, len)
		while #state.interpreter.tags > len do
			self:pop(state)
		end
	end
}

--- event buffer management
-- i.e. only for text and choice events
local events = {
	--- add a new element to the event buffer
	-- will flush if needed
	-- returns true in case of success
	-- returns nil, err in case of error
	append = function(self, state, type, data)
		if state.interpreter.event_capture_stack[type] then
			local r, e = state.interpreter.event_capture_stack[type][#state.interpreter.event_capture_stack[type]](data)
			if not r then return r, e end
		else
			local r, e = self:make_space_for(state, type)
			if not r then return r, e end

			if not state.interpreter.event_buffer then
				state.interpreter.event_type = type
				state.interpreter.event_buffer = {}
			end

			table.insert(state.interpreter.event_buffer, data)
		end
		return true
	end,
	--- add a new item in the last element (a list of elements) of the event buffer
	-- will flush if needed
	-- will use default or a new list if buffer is empty
	-- returns true in case of success
	-- returns nil, err in case of error
	append_in_last = function(self, state, type, data, default)
		local r, e = self:make_space_for(state, type)
		if not r then return r, e end

		if not state.interpreter.event_buffer then
			r, e = self:append(state, type, default or {})
			if not r then return r, e end
		end

		table.insert(state.interpreter.event_buffer[#state.interpreter.event_buffer], data)

		return true
	end,

	--- start capturing events of a certain type
	-- when an event of the type is appended, fn will be called with this event data
	-- and the event will not be added to the event buffer
	-- fn returns nil, err in case of error
	push_capture = function(self, state, type, fn)
		if not state.interpreter.event_capture_stack[type] then
			state.interpreter.event_capture_stack[type] = {}
		end
		table.insert(state.interpreter.event_capture_stack[type], fn)
	end,
	--- stop capturing events of a certain type.
	-- must be called after a push_capture
	-- this is handled by a stack so nested capturing is allowed.
	pop_capture = function(self, state, type)
		table.remove(state.interpreter.event_capture_stack[type])
		if #state.interpreter.event_capture_stack[type] == 0 then
			state.interpreter.event_capture_stack[type] = nil
		end
	end,

	-- flush event buffer if it's neccessary to push an event of the given type
	-- returns true in case of success
	-- returns nil, err in case of error
	make_space_for = function(self, state, type)
		if state.interpreter.event_buffer and state.interpreter.event_type ~= type and not state.interpreter.event_capture_stack[type] then
			return self:flush(state)
		end
		return true
	end,
	--- flush events and send them to the game if possible
	-- returns true in case of success
	-- returns nil, err in case of error
	flush = function(self, state)
		while state.interpreter.event_buffer do
			local type, buffer = state.interpreter.event_type, state.interpreter.event_buffer
			state.interpreter.event_type = nil
			state.interpreter.event_buffer = nil
			state.interpreter.skip_choices_until_flush = nil
			-- extract some needed state data for each choice block
			local choices
			if type == "choice" then
				choices = {}
				for _, c in ipairs(buffer) do
					table.insert(choices, c._state)
					c._state = nil
				end
			end
			-- text post processing
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
					local i = tags:push_lua_no_merge(state, choice.tags)
					local _, e = run_block(state, choice.block)
					tags:trim(state, i-1)
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

-- returns var in case of success and there is a return
-- return nil in case of success and there is no return
-- return nil, err in case of error
run_line = function(state, line)
	-- store line
	state.interpreter.running_line = line
	-- line types
	if line.type == "condition" then
		line.parent_block.last_condition_success = nil
		local v, e = eval(state, line.expression)
		if not v then return v, ("%s; at %s"):format(e, line.source) end
		if truthy(v) then
			line.parent_block.last_condition_success = true
			v, e = run_block(state, line.child)
			if e then return v, e end
			if v then return v end
		end
	elseif line.type == "else-condition" then
		if not line.parent_block.last_condition_success then
			local v, e = eval(state, line.expression)
			if not v then return v, ("%s; at %s"):format(e, line.source) end
			if truthy(v) then
				line.parent_block.last_condition_success = true
				v, e = run_block(state, line.child)
				if e then return v, e end
				if v then return v end
			end
		end
	elseif line.type == "choice" then
		local v, e = events:make_space_for(state, "choice")
		if not v then return v, ("%s; in automatic event flush at %s"):format(e, line.source) end
		local currentTags = tags:current(state)
		local choice_block_state = { tags = currentTags, block = line.child }
		v, e = events:append(state, "choice", { _state = choice_block_state }) -- new choice
		if not v then return v, e end
		events:push_capture(state, "text", function(event)
			local v2, e2 = events:append_in_last(state, "choice", event, { _state = choice_block_state })
			if not v2 then return v2, e2 end
		end)
		v, e = eval_text_callback(state, line.text, function(text)
			local v2, e2 = events:append_in_last(state, "choice", { text = text, tags = currentTags }, { _state = choice_block_state })
			if not v2 then return v2, e2 end
		end)
		events:pop_capture(state, "text")
		if not v then return v, ("%s; at %s"):format(e, line.source) end
	elseif line.type == "tag" then
		local v, e = eval(state, line.expression)
		if not v then return v, ("%s; at %s"):format(e, line.source) end
		local i = tags:push(state, v)
		v, e = run_block(state, line.child)
		tags:trim(state, i-1)
		if e then return v, e end
		if v then return v end
	elseif line.type == "return" then
		local v, e = eval(state, line.expression)
		if not v then return v, ("%s; at %s"):format(e, line.source) end
		return v
	elseif line.type == "text" then
		local v, e = events:make_space_for(state, "text") -- do this before any evaluation start
		if not v then return v, ("%s; in automatic event flush at %s"):format(e, line.source) end
		local currentTags = tags:current(state)
		v, e = eval_text_callback(state, line.text, function(text)
			-- why you would want to send a non-text event from there, I have no idea, but I'm not going to stop you
			local v2, e2 = events:append(state, "text", { text = text, tags = currentTags })
			if not v2 then return v2, e2 end
		end)
		if not v then return v, ("%s; at %s"):format(e, line.source) end
	elseif line.type == "flush_events" then
		local v, e = events:flush(state)
		if not v then return v, ("%s; in event flush at %s"):format(e, line.source) end
	elseif line.type == "checkpoint" then
		local reached, reachede = get_variable(state, line.namespace.."🏁")
		if not reached then return nil, reachede end
		state.variables[line.namespace.."🏁"] = {
			type = "number",
			value = reached.value + 1
		}
		state.variables[line.parent_function.namespace.."🔖"] = {
			type = "string",
			value = line.name
		}
		merge_state(state)
	else
		return nil, ("unknown line type %q; at %s"):format(line.type, line.source)
	end
end

-- returns var in case of success and there is a return
-- return nil in case of success and there is no return
-- return nil, err in case of error
run_block = function(state, block, resume_from_there, i, j)
	i = i or 1
	local max = math.min(#block, j or math.huge)
	while i <= max do
		local line = block[i]
		local skip = false
		-- skip current choice block if enabled
		if state.interpreter.skip_choices_until_flush and line.type == "choice" then
			skip = true
		end
		-- run line
		if not skip then
			local v, e = run_line(state, line)
			if e then return v, e end
			if v then return v end
		end
		i = i + 1
	end
	-- if we are exiting a checkpoint block, mark it as ran and update checkpoint
	-- (when resuming from a checkpoint, execution is resumed from inside the checkpoint, the line.type=="checkpoint" check in run_line is never called)
	-- (and we want this to be done after executing the checkpoint block anyway)
	if block.parent_line and block.parent_line.type == "checkpoint" then
		local parent_line = block.parent_line
		local reached, reachede = get_variable(state, parent_line.namespace.."🏁")
		if not reached then return nil, reachede end
		local seen, seene = get_variable(state, parent_line.namespace.."👁️")
		if not seen then return nil, seene end
		local checkpoint, checkpointe = get_variable(state, parent_line.parent_function.namespace.."🔖")
		if not checkpoint then return nil, checkpointe end
		state.variables[parent_line.namespace.."👁️"] = {
			type = "number",
			value = seen.value + 1
		}
		state.variables[parent_line.namespace.."🏁"] = {
			type = "number",
			value = reached.value + 1
		}
		-- don't update checkpoint if an already more precise checkpoint is set
		-- (since we will go up the whole checkpoint hierarchy when resuming from a nested checkpoint)
		local current_checkpoint = checkpoint.value
		if not current_checkpoint:match("^"..escape(parent_line.name)) then
			state.variables[parent_line.parent_function.namespace.."🔖"] = {
				type = "string",
				value = parent_line.name
			}
		end
		merge_state(state)
	end
	-- go up hierarchy if asked to resume
	-- will stop at function boundary
	-- if parent is a choice, will ignore choices that belong to the same block (like the whole block was executed naturally from a higher parent)
	-- if parent if a condition, will mark it as a success (skipping following else-conditions) (for the same reasons as for choices)
	-- if parent pushed a tag, will pop it (tags from parents are added to the stack in run())
	if resume_from_there and block.parent_line and block.parent_line.type ~= "function" then
		local parent_line = block.parent_line
		if parent_line.type == "choice" then
			state.interpreter.skip_choices_until_flush = true
		elseif parent_line.type == "condition" or parent_line.type == "else-condition" then
			parent_line.parent_block.last_condition_success = true
		end
		if parent_line.type == "tag" then
			tags:pop(state)
		end
		local v, e = run_block(state, parent_line.parent_block, resume_from_there, parent_line.parent_position+1)
		if e then return v, e end
		if v then return v, e end
	end
	return nil
end

-- returns var in case of success
-- return nil, err in case of error
local function run(state, block, resume_from_there, i, j)
	-- restore tags from parents when resuming
	local tags_len = tags:len(state)
	if resume_from_there then
		local tags_to_add = {}
		-- go up in hierarchy in ascending order until function boundary
		local parent_line = block.parent_line
		while parent_line and parent_line.type ~= "function" do
			if parent_line.type == "tag" then
				local v, e = eval(state, parent_line.expression)
				if not v then return v, ("%s; at %s"):format(e, parent_line.source) end
				table.insert(tags_to_add, v)
			end
			parent_line = parent_line.parent_block.parent_line
		end
		-- re-add tag in desceding order
		for k=#tags_to_add, 1, -1 do
			tags:push(state, tags_to_add[k])
		end
	end
	-- run
	local v, e = run_block(state, block, resume_from_there, i, j)
	-- return to previous tag state
	-- when resuming is done, tag stack pop when exiting the tag block
	-- stray elements may be left on the stack if there is a return before we exit all the tag block, so we trim them
	if resume_from_there then
		tags:trim(state, tags_len)
	end
	-- return
	if e then return v, e end
	if v then
		return v
	else
		-- default no return value
		return {
			type = "nil",
			value = nil
		}
	end
end

local interpreter = {
	run = run,
	run_block = run_block,
	run_line = run_line
}

package.loaded[...] = interpreter
eval = require((...):gsub("interpreter$", "expression"))
local common = require((...):gsub("interpreter$", "common"))
truthy, merge_state, to_lua, get_variable, eval_text_callback = common.truthy, common.merge_state, common.to_lua, common.get_variable, common.eval_text_callback
escape = require((...):gsub("interpreter%.interpreter$", "parser.common")).escape

return interpreter
