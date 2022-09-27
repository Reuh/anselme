local eval
local truthy, merge_state, escape, get_variable, tags, events, set_variable
local run_line, run_block

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
	elseif line.type == "while" then
		line.parent_block.last_condition_success = nil
		local v, e = eval(state, line.expression)
		if not v then return v, ("%s; at %s"):format(e, line.source) end
		while truthy(v) do
			line.parent_block.last_condition_success = true
			v, e = run_block(state, line.child)
			if e then return v, e end
			if v then return v end
			-- next iteration
			v, e = eval(state, line.expression)
			if not v then return v, ("%s; at %s"):format(e, line.source) end
		end
	elseif line.type == "choice" then
		local v, e = events:make_space_for(state, "choice")
		if not v then return v, ("%s; in automatic event flush at %s"):format(e, line.source) end
		v, e = eval(state, line.text)
		if not v then return v, ("%s; at %s"):format(e, line.source) end
		local l = v.type == "list" and v.value or { v }
		-- convert text events to choices
		for _, item in ipairs(l) do
			if item.type == "event buffer" then
				local current_tags = tags:current(state)
				local choice_block_state = { tags = current_tags, block = line.child }
				local final_buffer = {}
				for _, event in ipairs(item.value) do
					if event.type == "text" then
						-- create new choice block if needed
						local last_choice_block = final_buffer[#final_buffer]
						if not last_choice_block or last_choice_block.type ~= "choice" then
							last_choice_block = { type = "choice", value = {} }
							table.insert(final_buffer, last_choice_block)
						end
						-- create new choice item in choice block if needed
						local last_choice = last_choice_block.value[#last_choice_block.value]
						if not last_choice then
							last_choice = { _state = choice_block_state }
							table.insert(last_choice_block.value, last_choice)
						end
						-- add text to last choice item
						for _, txt in ipairs(event.value) do
							table.insert(last_choice, txt)
						end
					else
						table.insert(final_buffer, event)
					end
				end
				local iv, ie = events:write_buffer(state, final_buffer)
				if not iv then return iv, ("%s; at %s"):format(ie, line.source) end
			end
		end
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
		local cv, ce = run_block(state, line.child)
		if ce then return cv, ce end
		if cv then return cv end
		return v
	elseif line.type == "text" then
		local v, e = events:make_space_for(state, "text") -- do this before any evaluation start
		if not v then return v, ("%s; in automatic event flush at %s"):format(e, line.source) end
		v, e = eval(state, line.text)
		if not v then return v, ("%s; at %s"):format(e, line.source) end
		local l = v.type == "list" and v.value or { v }
		for _, item in ipairs(l) do
			if item.type == "event buffer" then
				local iv, ie = events:write_buffer(state, item.value)
				if not iv then return iv, ("%s; at %s"):format(ie, line.source) end
			end
		end
	elseif line.type == "flush_events" then
		local v, e = events:flush(state)
		if not v then return v, ("%s; in event flush at %s"):format(e, line.source) end
	elseif line.type == "function" and line.subtype == "checkpoint" then
		local reached, reachede = get_variable(state, line.namespace.."🏁")
		if not reached then return nil, reachede end
		local s, e = set_variable(state, line.namespace.."🏁", {
			type = "number",
			value = reached.value + 1
		})
		if not s then return nil, e end
		s, e = set_variable(state, line.parent_resumable.namespace.."🔖", {
			type = "function reference",
			value = { line.name }
		})
		if not s then return nil, e end
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
	-- (when resuming from a checkpoint, execution is resumed from inside the checkpoint, the line.subtype=="checkpoint" check in run_line is never called)
	-- (and we want this to be done after executing the checkpoint block anyway)
	if block.parent_line and block.parent_line.type == "function" and block.parent_line.subtype == "checkpoint" then
		local parent_line = block.parent_line
		local reached, reachede = get_variable(state, parent_line.namespace.."🏁")
		if not reached then return nil, reachede end
		local seen, seene = get_variable(state, parent_line.namespace.."👁️")
		if not seen then return nil, seene end
		local checkpoint, checkpointe = get_variable(state, parent_line.parent_resumable.namespace.."🔖")
		if not checkpoint then return nil, checkpointe end
		local s, e = set_variable(state, parent_line.namespace.."👁️", {
			type = "number",
			value = seen.value + 1
		})
		if not s then return nil, e end
		s, e = set_variable(state, parent_line.namespace.."🏁", {
			type = "number",
			value = reached.value + 1
		})
		if not s then return nil, e end
		-- don't update checkpoint if an already more precise checkpoint is set
		-- (since we will go up the whole checkpoint hierarchy when resuming from a nested checkpoint)
		if checkpoint.type == "nil" or not checkpoint.value[1]:match("^"..escape(parent_line.name)) then
			s, e = set_variable(state, parent_line.parent_resumable.namespace.."🔖", {
				type = "function reference",
				value = { parent_line.name }
			})
			if not s then return nil, e end
		end
		merge_state(state)
	end
	-- go up hierarchy if asked to resume
	-- will stop at resumable function boundary
	-- if parent is a choice, will ignore choices that belong to the same block (like the whole block was executed naturally from a higher parent)
	-- if parent if a condition, will mark it as a success (skipping following else-conditions) (for the same reasons as for choices)
	-- if parent pushed a tag, will pop it (tags from parents are added to the stack in run())
	if resume_from_there and block.parent_line and not block.parent_line.resumable then
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
		-- go up in hierarchy in ascending order until resumable function boundary
		local parent_line = block.parent_line
		while parent_line and not parent_line.resumable do
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
	-- stray elements may be left on the stack if there is a return before we go up all the tag blocks, so we trim them
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
truthy, merge_state, tags, get_variable, events, set_variable = common.truthy, common.merge_state, common.tags, common.get_variable, common.events, common.set_variable
escape = require((...):gsub("interpreter%.interpreter$", "parser.common")).escape

return interpreter
