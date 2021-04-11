local eval
local truthy, flush_state, to_lua, eval_text

local function write_event(state, type, data)
	if state.interpreter.event_buffer and state.interpreter.event_type ~= type then
		error(("previous event of type %q has not been flushed, can't write new %q event"):format(state.interpreter.event_type, type))
	end
	if not state.interpreter.event_buffer then
		state.interpreter.event_type = type
		state.interpreter.event_buffer = {}
	end
	table.insert(state.interpreter.event_buffer, { data = data, tags = state.interpreter.tags[#state.interpreter.tags] or {} })
end

local tags = {
	push = function(self, state, val)
		local new = {}
		-- copy
		local last = state.interpreter.tags[#state.interpreter.tags] or {}
		for k,v in pairs(last) do new[k] = v end
		-- merge with new values
		if val.type ~= "list" then val = { type = "list", value = { val } } end
		for k, v in pairs(to_lua(val)) do new[k] = v end
		-- add
		table.insert(state.interpreter.tags, new)
	end,
	pop = function(self, state)
		table.remove(state.interpreter.tags)
	end
}

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
			table.insert(state.interpreter.choice_available, line.child)
			write_event(state, "choice", t)
		elseif line.type == "tag" then
			if line.expression then
				local v, e = eval(state, line.expression)
				if not v then return v, ("%s; at %s"):format(e, line.source) end
				tags:push(state, v)
			end
			local v, e = run_block(state, line.child)
			if line.expression then tags:pop(state) end
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
						local v, e = run_block(state, choice)
						if e then return v, e end
						if v then return v end
					end
				end
			end
		elseif line.type ~= "paragraph" then
			return nil, ("unknown line type %q; at %s"):format(line.type, line.source)
		end
		-- tag decorator
		if line.tag then
			tags:pop(state)
		end
		-- paragraph decorator
		if line.paragraph then
			state.variables[line.namespace.."👁️"] = {
				type = "number",
				value = state.variables[line.namespace.."👁️"].value + 1
			}
			state.variables[line.parent_function.namespace.."🏁"] = {
				type = "string",
				value = line.name
			}
			flush_state(state)
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
	-- go up hierarchy if asked to resume
	-- will stop at function boundary
	-- if parent is a choice, will ignore choices that belong to the same block (like the whole block was executed naturally from a higher parent)
	-- if parent if a condition, will mark it as a success (skipping following else-conditions) (for the same reasons as for choices)
	if resume_from_there and block.parent_line and block.parent_line.type ~= "function" then
		local parent_line = block.parent_line
		if parent_line.type == "choice" then
			state.interpreter.skip_choices_until_flush = true
		elseif parent_line.type == "condition" or parent_line.type == "else-condition" then
			parent_line.parent_block.last_condition_success = true
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
	-- run
	local v, e = run_block(state, block, resume_from_there, i, j)
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
truthy, flush_state, to_lua, eval_text = common.truthy, common.flush_state, common.to_lua, common.eval_text

return interpreter
