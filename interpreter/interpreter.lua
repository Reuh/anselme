local eval
local truthy, merge_state, to_lua, eval_text, escape

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
	trim = function(self, state, len)
		while #state.interpreter.tags > len do
			self:pop(state)
		end
	end
}

local function write_event(state, type, data)
	if state.interpreter.event_buffer and state.interpreter.event_type ~= type then
		error(("previous event of type %q has not been flushed, can't write new %q event"):format(state.interpreter.event_type, type))
	end
	if not state.interpreter.event_buffer then
		state.interpreter.event_type = type
		state.interpreter.event_buffer = {}
	end
	table.insert(state.interpreter.event_buffer, { data = data, tags = tags:current(state) })
end

local run_block

-- returns var in case of success and there is a return
-- return nil in case of success and there is no return
-- return nil, err in case of error
local function run_line(state, line)
	-- store line
	state.interpreter.running_line = line
	-- condition decorator
	local skipped = false
	if line.condition then
		local v, e = eval(state, line.condition)
		if not v then return v, ("%s; at %s"):format(e, line.source) end
		skipped = not truthy(v)
	end
	if not skipped then
		-- tag decorator
		if line.tag then
			local v, e = eval(state, line.tag)
			if not v then return v, ("%s; in tag decorator at %s"):format(e, line.source) end
			tags:push(state, v)
		end
		-- if line intend to push an event, flush buffer it it's a different event
		if line.push_event and state.interpreter.event_buffer and state.interpreter.event_type ~= line.push_event then
			local v, e = run_line(state, { source = line.source, type = "flush_events" })
			if e then return v, e end
			if v then return v end
		end
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
			local t, er = eval_text(state, line.text)
			if not t then return t, er end
			table.insert(state.interpreter.choice_available, {
				tags = tags:current(state),
				block = line.child
			})
			write_event(state, "choice", t)
		elseif line.type == "tag" then
			local v, e = eval(state, line.expression)
			if not v then return v, ("%s; at %s"):format(e, line.source) end
			tags:push(state, v)
			v, e = run_block(state, line.child)
			tags:pop(state)
			if e then return v, e end
			if v then return v end
		elseif line.type == "return" then
			local v, e = eval(state, line.expression)
			if not v then return v, ("%s; at %s"):format(e, line.source) end
			return v
		elseif line.type == "text" then
			local t, er = eval_text(state, line.text)
			if not t then return t, ("%s; at %s"):format(er, line.source) end
			write_event(state, "text", t)
		elseif line.type == "flush_events" then
			while state.interpreter.event_buffer do
				local type, buffer = state.interpreter.event_type, state.interpreter.event_buffer
				state.interpreter.event_type = nil
				state.interpreter.event_buffer = nil
				-- yield
				coroutine.yield(type, buffer)
				-- run choice
				if type == "choice" then
					local sel = state.interpreter.choice_selected
					state.interpreter.choice_selected = nil
					if not sel or sel < 1 or sel > #state.interpreter.choice_available then
						return nil, "invalid choice"
					else
						local choice = state.interpreter.choice_available[sel]
						state.interpreter.choice_available = {}
						tags:push_lua_no_merge(state, choice.tags)
						local v, e = run_block(state, choice.block)
						tags:pop(state)
						if e then return v, e end
						-- discard return value from choice block as the execution is delayed until an event flush
						-- and we don't want to stop the execution of another function unexpectedly
					end
				end
			end
		elseif line.type ~= "checkpoint" then
			return nil, ("unknown line type %q; at %s"):format(line.type, line.source)
		end
		-- tag decorator
		if line.tag then
			tags:pop(state)
		end
		-- checkpoint decorator and line
		if line.checkpoint then
			state.variables[line.namespace.."👁️"] = {
				type = "number",
				value = state.variables[line.namespace.."👁️"].value + 1
			}
			state.variables[line.parent_function.namespace.."🏁"] = {
				type = "string",
				value = line.name
			}
			merge_state(state)
		end
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
		if state.interpreter.skip_choices_until_flush then
			if line.type == "choice" then
				skip = true
			elseif line.type == "flush_events" or (line.push_event and line.push_event ~= "choice") then
				state.interpreter.skip_choices_until_flush = nil
			end
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
	-- (when resuming from a checkpoint, execution is resumed from inside the checkpoint, the line.checkpoint check in run_line is never called)
	-- (and we want this to be done after executing the checkpoint block anyway)
	if block.parent_line and block.parent_line.checkpoint then
		local parent_line = block.parent_line
		state.variables[parent_line.namespace.."👁️"] = {
			type = "number",
			value = state.variables[parent_line.namespace.."👁️"].value + 1
		}
		-- don't update checkpoint if an already more precise checkpoint is set
		-- (since we will go up the whole checkpoint hierarchy when resuming from a nested checkpoint)
		local current_checkpoint = state.variables[parent_line.parent_function.namespace.."🏁"].value
		if not current_checkpoint:match("^"..escape(parent_line.name)) then
			state.variables[parent_line.parent_function.namespace.."🏁"] = {
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
		if parent_line.type == "tag" or parent_line.tag then
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
			if parent_line.tag then
				local v, e = eval(state, parent_line.tag)
				if not v then return v, ("%s; in tag decorator at %s"):format(e, parent_line.source) end
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
	-- tag stack pop when resuming is done when exiting the tag block
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
truthy, merge_state, to_lua, eval_text = common.truthy, common.merge_state, common.to_lua, common.eval_text
escape = require((...):gsub("interpreter%.interpreter$", "parser.common")).escape

return interpreter
