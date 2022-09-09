local atypes, ltypes
local eval, run_block
local replace_with_copied_values, fix_not_modified_references
local common
local identifier_pattern
local copy

--- copy some text & process it to be suited to be sent to Lua in an event
local function post_process_text(state, text)
	local r = {}
	-- copy into r & convert tags to lua
	for _, t in ipairs(text) do
		local tags = common.to_lua(t.tags)
		if state.interpreter.base_lua_tags then
			for k, v in pairs(state.interpreter.base_lua_tags) do
				if tags[k] == nil then tags[k] = v end
			end
		end
		table.insert(r, {
			text = t.text,
			tags = tags
		})
	end
	-- remove trailing spaces
	if state.feature_flags["strip trailing spaces"] then
		local final = r[#r]
		if final then
			final.text = final.text:match("^(.-) *$")
			if final.text == "" then
				table.remove(r)
			end
		end
	end
	-- remove duplicate spaces
	if state.feature_flags["strip duplicate spaces"] then
		for i=1, #r-1 do
			local a, b = r[i], r[i+1]
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
	return r
end

common = {
	--- merge interpreter state with global state
	merge_state = function(state)
		local mt = getmetatable(state.variables)
		-- store current scoped variables before merging them
		for fn in pairs(mt.scoped) do
			common.scope:store_last_scope(state, fn)
		end
		-- merge alias state
		local global = state.interpreter.global_state
		for alias, fqm in pairs(state.aliases) do
			global.aliases[alias] = fqm
			state.aliases[alias] = nil
		end
		-- merge modified mutable varables
		local copy_cache, modified_tables = mt.copy_cache, mt.modified_tables
		replace_with_copied_values(global.variables, copy_cache, modified_tables)
		mt.copy_cache = {}
		mt.modified_tables = {}
		mt.cache = {}
		-- merge modified re-assigned variables
		for var, value in pairs(state.variables) do
			if var:match("^"..identifier_pattern.."$") then -- skip scoped variables
				global.variables[var] = value
				state.variables[var] = nil
			end
		end
		-- scoping: since merging means we will re-copy every variable from global state again, we need to simulate this
		-- behavious for scoped variables (to have consistent references for mutables values in particular), including
		-- scopes that aren't currently active
		fix_not_modified_references(mt.scoped, copy_cache, modified_tables) -- replace not modified values in scope with original before re-copying to keep consistent references
		for _, scopes in pairs(mt.scoped) do
			for _, scope in ipairs(scopes) do
				for var, value in pairs(scope) do
					-- pretend the value for this scope is the global value so the cache system perform the new copy from it
					local old_var = global.variables[var]
					global.variables[var] = value
					state.variables[var] = nil
					scope[var] = state.variables[var]
					mt.cache[var] = nil
					global.variables[var] = old_var
				end
			end
		end
		-- restore last scopes
		for fn in pairs(mt.scoped) do
			common.scope:set_last_scope(state, fn)
		end
	end,
	--- checks if the value is compatible with the variable's (eventual) constraint
	-- returns depth, or math.huge if no constraint
	-- returns nil, err
	check_constraint = function(state, fqm, val)
		local constraint = state.variable_constraints[fqm]
		if constraint then
			if not constraint.value then
				local v, e = eval(state, constraint.pending)
				if not v then
					return nil, ("%s; while evaluating constraint for variable %q"):format(e, fqm)
				end
				constraint.value = v
			end
			local depth = common.is_of_type(val, constraint.value)
			if not depth then
				return nil, ("constraint check failed")
			end
			return depth
		end
		return math.huge
	end,
	--- checks if the variable is mutable
	-- returns true
	-- returns nil, mutation illegal message
	check_mutable = function(state, fqm)
		if state.variable_constants[fqm] then
			return nil, ("can't change the value of a constant %q"):format(fqm)
		end
		return true
	end,
	--- mark a value as constant, recursively affecting all the potentially mutable subvalues
	mark_constant = function(v)
		if v.type == "list" then
			v.constant = true
			for _, item in ipairs(v.value) do
				common.mark_constant(item)
			end
		elseif v.type == "object" then
			v.constant = true
		elseif v.type == "pair" or v.type == "annotated" then
			common.mark_constant(v.value[1])
			common.mark_constant(v.value[2])
		elseif v.type ~= "nil" and v.type ~= "number" and v.type ~= "string" and v.type ~= "function reference" and v.type ~= "variable reference" then
			error("unknown type")
		end
	end,
	--- returns a variable's value, evaluating a pending expression if neccessary
	-- if you're sure the variable has already been evaluated, use state.variables[fqm] directly
	-- return var
	-- return nil, err
	get_variable = function(state, fqm)
		local var = state.variables[fqm]
		if var.type == "pending definition" then
			-- evaluate
			local v, e = eval(state, var.value.expression)
			if not v then
				return nil, ("%s; while evaluating default value for variable %q defined at %s"):format(e, fqm, var.value.source)
			end
			-- make constant if variable is constant
			if state.variable_constants[fqm] then
				v = copy(v)
				common.mark_constant(v)
			end
			-- set variable
			local s, err = common.set_variable(state, fqm, v, state.variable_constants[fqm])
			if not s then return nil, err end
			return v
		else
			return var
		end
	end,
	--- set the value of a variable
	-- returns true
	-- returns nil, err
	set_variable = function(state, name, val, bypass_constant_check)
		if val.type ~= "pending definition" then
			-- check constant
			if not bypass_constant_check then
				local s, e = common.check_mutable(state, name)
				if not s then
					return nil, ("%s; while assigning value to variable %q"):format(e, name)
				end
			end
			-- check constraint
			local s, e = common.check_constraint(state, name, val)
			if not s then
				return nil, ("%s; while assigning value to variable %q"):format(e, name)
			end
		end
		state.variables[name] = val
		return true
	end,
	--- handle scoped function
	scope = {
		init_scope = function(self, state, fn)
			local scoped = getmetatable(state.variables).scoped
			if not fn.scoped then error("trying to initialize the scope stack for a non-scoped function") end
			if not scoped[fn] then scoped[fn] = {} end
			-- check scoped variables
			for _, name in ipairs(fn.scoped) do
				-- put fresh variable from global state in scope
				local val = state.interpreter.global_state.variables[name]
				if val.type ~= "undefined argument" and val.type ~= "pending definition" then -- only possibilities for scoped variable, and they're immutable
					error("invalid scoped variable")
				end
			end
		end,
		--- push a new scope for this function
		push = function(self, state, fn)
			local scoped = getmetatable(state.variables).scoped
			self:init_scope(state, fn)
			-- preserve current values in last scope
			self:store_last_scope(state, fn)
			-- add scope
			local fn_scope = {}
			table.insert(scoped[fn], fn_scope)
			self:set_last_scope(state, fn)
		end,
		--- pop the last scope for this function
		pop = function(self, state, fn)
			local scoped = getmetatable(state.variables).scoped
			if not scoped[fn] then error("trying to pop a scope without any pushed scope") end
			-- remove current scope
			table.remove(scoped[fn])
			-- restore last scope
			self:set_last_scope(state, fn)
			-- if the stack is empty,
			-- we could remove mt.scoped[fn] I guess, but I don't think there's going to be a million different functions in a single game so should be ok
			-- (anselme's performance is already bad enough, let's not create tables at each function call...)
		end,
		--- store the current values of the scoped variables in the last scope of this function
		store_last_scope = function(self, state, fn)
			local scopes = getmetatable(state.variables).scoped[fn]
			local last_scope = scopes[#scopes]
			if last_scope then
				for _, name in pairs(fn.scoped) do
					local val = rawget(state.variables, name)
					if val then
						last_scope[name] = val
					end
				end
			end
		end,
		--- set scopped variables to previous scope
		set_last_scope = function(self, state, fn)
			local scopes = getmetatable(state.variables).scoped[fn]
			for _, name in ipairs(fn.scoped) do
				state.variables[name] = nil
			end
			local last_scope = scopes[#scopes]
			if last_scope then
				for name, val in pairs(last_scope) do
					state.variables[name] = val
				end
			end
		end
	},
	--- mark a table as modified, so it will be merged on the next checkpoint if it appears somewhere in a value
	mark_as_modified = function(state, v)
		local modified = getmetatable(state.variables).modified_tables
		table.insert(modified, v)
	end,
	--- returns true if a variable should be persisted on save
	-- will exclude: undefined variables, variables in scoped functions, constants, internal anselme variables
	should_keep_variable = function(state, name, value)
		return value.type ~= "undefined argument" and value.type ~= "pending definition" and name:match("^"..identifier_pattern.."$") and not name:match("^anselme%.") and not state.variable_constants[name]
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
	--- compare two anselme values for equality.
	-- for immutable values or constants: compare by value
	-- for mutable values: compare by reference
	compare = function(a, b)
		if a.type ~= b.type or a.constant ~= b.constant then
			return false
		end
		if a.type == "pair" or a.type == "annotated" then
			return common.compare(a.value[1], b.value[1]) and common.compare(a.value[2], b.value[2])
		elseif a.type == "function reference" then
			if #a.value ~= #b.value then
				return false
			end
			for _, aname in ipairs(a.value) do
				local found = false
				for _, bname in ipairs(b.value) do
					if aname == bname then
						found = true
						break
					end
				end
				if not found then
					return false
				end
			end
			return true
		-- mutable types: need to be constant
		elseif a.constant and a.type == "list" then
			if #a.value ~= #b.value then
				return false
			end
			for i, v in ipairs(a.value) do
				if not common.compare(v, b.value[i]) then
					return false
				end
			end
			return true
		elseif a.constant and a.type == "object" then
			if a.value.class ~= b.value.class then
				return false
			end
			-- check every attribute redefined in a and b
			-- NOTE: comparaison will fail if an attribute has been redefined in only one of the object, even if it was set to the same value as the original class attribute
			local compared = {}
			for name, v in pairs(a.value.attributes) do
				compared[name] = true
				if not b.value.attributes[name] or not common.compare(v, b.value.attributes[name]) then
					return false
				end
			end
			for name, v in pairs(b.value.attributes) do
				if not compared[name] then
					if not a.value.attributes[name] or not common.compare(v, a.value.attributes[name]) then
						return false
					end
				end
			end
			return true
		-- the rest
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
	--- check if an anselme value is of a certain type or annotation
	-- specificity(number): if var is of type type. lower is more specific
	-- false: if not
	is_of_type = function(var, type)
		local depth = 1
		-- var has a custom annotation
		if var.type == "annotated" then
			-- special case: if we just want to see if a value is annotated
			if type.type == "string" and type.value == "annotated" then
				return depth
			end
			-- check annotation
			local var_type = var.value[2]
			while true do
				if common.compare(var_type, type) then -- same type
					return depth
				elseif var_type.type == "annotated" then -- compare parent type
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
		if var.type == "annotated" then
			return common.format(var.value[2])
		else
			return var.type
		end
	end,
	--- tag management
	tags = {
		--- push new tags on top of the stack, from Anselme values
		push = function(self, state, val)
			local new = { type = "list", value = {} }
			-- copy
			local last = self:current(state)
			for _, v in ipairs(last.value) do table.insert(new.value, v) end
			-- append new values
			if val.type ~= "list" then val = { type = "list", value = { val } } end
			for _, v in ipairs(val.value) do table.insert(new.value, v) end
			-- add
			table.insert(state.interpreter.tags, new)
		end,
		--- same but do not merge with last stack item
		push_no_merge = function(self, state, val)
			table.insert(state.interpreter.tags, val)
		end,
		-- pop tag table on top of the stack
		pop = function(self, state)
			table.remove(state.interpreter.tags)
		end,
		--- return current lua tags table
		current = function(self, state)
			return state.interpreter.tags[#state.interpreter.tags] or { type = "list", value = {} }
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
				last = { type = type, value = {} }
				table.insert(buffer, last)
			end
			table.insert(last.value, data)
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
		--- returns the current buffer value
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
							for _, v in ipairs(event.value) do
								table.insert(state.interpreter.current_event.value, v)
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
				state.interpreter.skip_choices_until_flush = nil

				local type = event.type
				local buffer

				local choices
				-- copy & process text buffer
				if type == "text" then
					buffer = post_process_text(state, event.value)
				-- copy & process choice buffer
				elseif type == "choice" then
					-- copy & process choice text content into buffer, and needed private state into choices for each choice
					buffer = {}
					choices = {}
					for _, c in ipairs(event.value) do
						table.insert(buffer, post_process_text(state, c))
						table.insert(choices, c._state)
					end
					-- discard empty choices
					for i=#buffer, 1, -1 do
						if #buffer[i] == 0 then
							table.remove(buffer, i)
							table.remove(choices, i)
						end
					end
					-- nervermind
					if #choices == 0 then
						return true
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
						common.tags:push_no_merge(state, choice.tags)
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
local acommon = require((...):gsub("interpreter%.common$", "common"))
replace_with_copied_values, fix_not_modified_references = acommon.replace_with_copied_values, acommon.fix_not_modified_references
identifier_pattern = require((...):gsub("interpreter%.common$", "parser.common")).identifier_pattern
copy = require((...):gsub("interpreter%.common$", "common")).copy

return common
