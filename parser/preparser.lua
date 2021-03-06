local format_identifier, identifier_pattern, escape, special_functions_names, pretty_signature, signature

-- try to define an alias using rem, the text that follows the identifier
-- returns true, new_rem, alias_name in case of success
-- returns true, rem in case of no alias and no error
-- returns nil, err in case of alias and error
local function maybe_alias(rem, fqm, namespace, line, state)
	local alias
	if rem:match("^%:[^%:%=]") then
		local param_content = rem:sub(2)
		alias, rem = param_content:match("^("..identifier_pattern..")(.-)$")
		if not alias then return nil, ("expected an identifier in alias, but got %q; at %s"):format(param_content, line.source) end
		alias = format_identifier(alias)
		-- format alias
		local aliasfqm = ("%s%s"):format(namespace, alias)
		-- define alias
		if state.aliases[aliasfqm] ~= nil and state.aliases[aliasfqm] ~= fqm then
			return nil, ("trying to define alias %q for %q, but already exist and refer to %q; at %s"):format(aliasfqm, fqm, state.aliases[aliasfqm], line.source)
		end
		state.aliases[aliasfqm] = fqm
	end
	return true, rem, alias
end

-- * ast: if success
-- * nil, error: in case of error
local function parse_line(line, state, namespace)
	local l = line.content
	local r = {
		source = line.source
	}
	-- else-condition & condition
	if l:match("^~~?") then
		r.type = l:match("^~~") and "else-condition" or "condition"
		r.child = true
		local expr = l:match("^~~?(.*)$")
		if expr:match("[^%s]") then
			r.expression = expr
		else
			r.expression = "1"
		end
	-- choice
	elseif l:match("^>") then
		r.type = "choice"
		r.push_event = "choice"
		r.child = true
		r.text = l:match("^>%s*(.-)$")
	-- function & checkpoint
	elseif l:match("^%$") or l:match("^§") then -- § is a 2-bytes caracter, DO NOT USE LUA PATTERN OPERATORS as they operate on single bytes
		r.type = l:match("^%$") and "function" or "checkpoint"
		r.child = true
		-- store parent function and run checkpoint when line is read
		if r.type == "checkpoint" then
			r.parent_function = true
		end
		-- don't keep function node in block AST
		if r.type == "function" then
			r.remove_from_block_ast = true
			-- lua function
			if state.global_state.link_next_function_definition_to_lua_function then
				r.lua_function = state.global_state.link_next_function_definition_to_lua_function
				state.global_state.link_next_function_definition_to_lua_function = nil
			end
		end
		-- get identifier
		local lc = l:match("^%$(.-)$") or l:match("^§(.-)$")
		local identifier, rem = lc:match("^("..identifier_pattern..")(.-)$")
		if not identifier then
			for _, name in ipairs(special_functions_names) do
				identifier, rem = lc:match("^(%s*"..escape(name).."%s*)(.-)$")
				if identifier then break end
			end
		end
		if not identifier then
			return nil, ("no valid identifier in checkpoint/function definition line %q; at %s"):format(lc, line.source)
		end
		-- format identifier
		local fqm = ("%s%s"):format(namespace, format_identifier(identifier))
		local func_namespace = fqm .. "."
		-- get alias
		local ok_alias
		ok_alias, rem = maybe_alias(rem, fqm, namespace, line, state)
		if not ok_alias then return ok_alias, rem end
		-- anything else are argument, isolate function it its own namespace
		-- (to not mix its args and variables with the main variant)
		if rem:match("[^%s]") then
			func_namespace = ("%s(%s)."):format(fqm, r)
			r.private_namespace = true
		end
		-- define function
		if state.variables[fqm] then return nil, ("trying to define %s %s, but a variable with the same name exists; at %s"):format(r.type, fqm, line.source) end
		r.namespace = func_namespace
		r.name = fqm
		-- get params
		r.params = {}
		if r.type == "function" and rem:match("^%b()") then
			local content
			content, rem = rem:match("^(%b())%s*(.*)$")
			content = content:gsub("^%(", ""):gsub("%)$", "")
			for param in content:gmatch("[^%,]+") do
				-- get identifier
				local param_identifier, param_rem = param:match("^("..identifier_pattern..")(.-)$")
				if not param_identifier then return nil, ("no valid identifier in function parameter %q; at %s"):format(param, line.source) end
				param_identifier = format_identifier(param_identifier)
				-- format identifier
				local param_fqm = ("%s%s"):format(func_namespace, param_identifier)
				-- get alias
				local ok_param_alias, param_alias
				ok_param_alias, param_rem, param_alias = maybe_alias(param_rem, param_fqm, func_namespace, line, state)
				if not ok_param_alias then return ok_param_alias, param_rem end
				-- get potential type annotation and default value
				local type_annotation, default
				if param_rem:match("^::") then
					type_annotation = param_rem:match("^::(.*)$")
				elseif param_rem:match("^=") then
					default = param_rem:match("^=(.*)$")
				elseif param_rem:match("[^%s]") then
					return nil, ("unexpected characters after parameter %q: %q; at %s"):format(param_fqm, param_rem, line.source)
				end
				-- add parameter
				table.insert(r.params, { name = param_identifier, alias = param_alias, full_name = param_fqm, type_annotation = type_annotation, default = default, vararg = nil })
			end
		end
		-- get assignment param
		if r.type == "function" and rem:match("^%:%=") then
			local param = rem:match("^%:%=(.*)$")
			-- get identifier
			local param_identifier, param_rem = param:match("^("..identifier_pattern..")(.-)$")
			if not param_identifier then return nil, ("no valid identifier in function parameter %q; at %s"):format(param, line.source) end
			param_identifier = format_identifier(param_identifier)
			-- format identifier
			local param_fqm = ("%s%s"):format(func_namespace, param_identifier)
			-- get alias
			local ok_param_alias, param_alias
			ok_param_alias, param_rem, param_alias = maybe_alias(param_rem, param_fqm, func_namespace, line, state)
			if not ok_param_alias then return ok_param_alias, param_rem end
			-- get potential type annotation
			local type_annotation
			if param_rem:match("^::") then
				type_annotation = param_rem:match("^::(.*)$")
			elseif param_rem:match("[^%s]") then
				return nil, ("unexpected characters after parameter %q: %q; at %s"):format(param_fqm, param_rem, line.source)
			end
			-- add parameter
			r.assignment = { name = param_identifier, alias = param_alias, full_name = param_fqm, type_annotation = type_annotation, default = nil, vararg = nil }
		elseif rem:match("[^%s]") then
			return nil, ("expected end-of-line at end of checkpoint/function definition line, but got %q; at %s"):format(rem, line.source)
		end
		-- calculate arity
		local minarity, maxarity = #r.params, #r.params
		for _, param in ipairs(r.params) do -- params with default values
			if param.default then
				minarity = minarity - 1
			end
		end
		-- varargs
		if maxarity > 0 and r.params[maxarity].full_name:match("%.%.%.$") then
			r.params[maxarity].name = r.params[maxarity].name:match("^(.*)%.%.%.$")
			r.params[maxarity].full_name = r.params[maxarity].full_name:match("^(.*)%.%.%.$")
			r.params[maxarity].vararg = true
			minarity = minarity - 1
			maxarity = math.huge
		end
		r.arity = { minarity, maxarity }
		r.signature = signature(r)
		r.pretty_signature = pretty_signature(r)
		-- check for signature conflict with functions with the same fqm
		if state.functions[fqm] then
			for _, variant in ipairs(state.functions[fqm]) do
				if r.signature == variant.signature then
					return nil, ("trying to define %s %s, but another function with same signature %s exists; at %s"):format(r.type, r.pretty_signature, variant.pretty_signature, line.source)
				end
			end
		end
		-- define variables
		if not line.children then line.children = {} end
		-- define 👁️ variable
		local seen_alias = state.global_state.builtin_aliases["👁️"]
		if seen_alias then
			table.insert(line.children, 1, { content = (":👁️:%s=0"):format(seen_alias), source = line.source })
		else
			table.insert(line.children, 1, { content = ":👁️=0", source = line.source })
		end
		if r.type == "function" then
			-- define 🔖 variable
			local checkpoint_alias = state.global_state.builtin_aliases["🔖"]
			if checkpoint_alias then
				table.insert(line.children, 1, { content = (":🔖:%s=\"\""):format(checkpoint_alias), source = line.source })
			else
				table.insert(line.children, 1, { content = ":🔖=\"\"", source = line.source })
			end
		elseif r.type == "checkpoint" then
			-- define 🏁 variable
			local reached_alias = state.global_state.builtin_aliases["🏁"]
			if reached_alias then
				table.insert(line.children, 1, { content = (":🏁:%s=0"):format(reached_alias), source = line.source })
			else
				table.insert(line.children, 1, { content = ":🏁=0", source = line.source })
			end
		end
		-- define args
		for _, param in ipairs(r.params) do
			if not state.variables[param.full_name] then
				state.variables[param.full_name] = {
					type = "undefined argument",
					value = nil
				}
			else
				return nil, ("trying to define parameter %q, but a variable with the same name exists; at %s"):format(param.full_name, line.source)
			end
		end
		if r.assignment then
			if not state.variables[r.assignment.full_name] then
				state.variables[r.assignment.full_name] = {
					type = "undefined argument",
					value = nil
				}
			else
				return nil, ("trying to define parameter %q, but a variable with the same name exists; at %s"):format(r.assignment.full_name, line.source)
			end
		end
		-- define new function, no other variant yet
		if not state.functions[fqm] then
			state.functions[fqm] = { r }
		-- overloading
		else
			table.insert(state.functions[fqm], r)
		end
	-- definition
	elseif l:match("^:") then
		r.type = "definition"
		r.remove_from_block_ast = true
		-- get identifier
		local identifier, rem = l:match("^:("..identifier_pattern..")(.-)$")
		if not identifier then return nil, ("no valid identifier at start of definition line %q; at %s"):format(l, line.source) end
		-- format identifier
		local fqm = ("%s%s"):format(namespace, format_identifier(identifier))
		-- get alias
		local ok_alias
		ok_alias, rem = maybe_alias(rem, fqm, namespace, line, state)
		if not ok_alias then return ok_alias, rem end
		-- get expression
		local exp = rem:match("^=(.*)$")
		if not exp then return nil, ("expected \"= expression\" after %q in definition line; at %s"):format(rem, line.source) end
		-- define identifier
		if state.functions[fqm] then return nil, ("trying to define variable %q, but a function with the same name exists; at %s"):format(fqm, line.source) end
		if state.variables[fqm] then return nil, ("trying to define variable %q but it is already defined; at %s"):format(fqm, line.source) end
		r.fqm = fqm
		r.expression = exp
		state.variables[fqm] = { type = "pending definition", value = { expression = nil, source = r.source } }
	-- tag
	elseif l:match("^%#") then
		r.type = "tag"
		r.child = true
		local expr = l:match("^%#(.*)$")
		if expr:match("[^%s]") then
			r.expression = expr
		else
			r.expression = "()"
		end
	-- return
	elseif l:match("^%@") then
		r.type = "return"
		r.parent_function = true
		local expr = l:match("^%@(.*)$")
		if expr:match("[^%s]") then
			r.expression = expr
		else
			r.expression = "()"
		end
	-- text
	elseif l:match("[^%s]") then
		r.type = "text"
		r.push_event = "text"
		r.text = l
	-- flush events
	else
		r.type = "flush_events"
	end
	if not r.type then return nil, ("unknown line %s type"):format(line.source) end
	return r
end

-- * block: in case of success
-- * nil, err: in case of error
local function parse_block(indented, state, namespace, parent_function)
	local block = { type = "block" }
	for _, l in ipairs(indented) do
		-- parsable line
		local ast, err = parse_line(l, state, namespace)
		if err then return nil, err end
		-- store parent function
		if ast.parent_function then ast.parent_function = parent_function end
		-- add to block AST
		if not ast.remove_from_block_ast then
			ast.parent_block = block
			-- add ast node
			ast.parent_position = #block+1
			table.insert(block, ast)
		end
		-- add child
		if ast.child then ast.child = { type = "block", parent_line = ast } end
		-- queue in expression evalution
		table.insert(state.queued_lines, { namespace = ast.namespace or namespace, line = ast })

		-- indented block
		if l.children then
			if not ast.child then
				return nil, ("line %s (%s) can't have children"):format(ast.source, ast.type)
			else
				local r, e = parse_block(l.children, state, ast.namespace or namespace, ast.type == "function" and ast or parent_function)
				if not r then return r, e end
				r.parent_line = ast
				ast.child = r
			end
		end
	end
	return block
end

-- returns new_indented
local function transform_indented(indented)
	local i = 1
	while i <= #indented do
		local l = indented[i]
		-- comment
		if l.content:match("^%(") then
			table.remove(indented, i)
		else
			-- condition decorator
			if l.content:match("^.-%s*[^~]%~[^#~$]-$") then
				local decorator
				l.content, decorator = l.content:match("^(..-)%s*(%~[^#~$]-)$")
				indented[i] = { content = decorator, source = l.source, children = { l } }
			-- tag decorator
			elseif l.content:match("^..-%s*%#[^#~$]-$") then
				local decorator
				l.content, decorator = l.content:match("^(..-)%s*(%#[^#~$]-)$")
				indented[i] = { content = decorator, source = l.source, children = { l } }
			-- function decorator
			elseif l.content:match("^..-%s*%$[^#~$]-$") then
				local name
				l.content, name = l.content:match("^(..-)%s*%$([^#~$]-)$")
				indented[i] = { content = "~"..name, source = l.source }
				table.insert(indented, i+1, { content = "$"..name, source = l.source, children = { l } })
				i = i + 1 -- $ line should not contain any decorator anymore
			else
				i = i + 1 -- only increment when no decorator, as there may be several decorators per line
			end

			-- indented block
			if l.children then
				transform_indented(l.children)
			end
		end
	end
	return indented
end

--- returns the nested list of lines {content="", line=1, children={lines...} or nil}, parsing indentation
-- multiple empty lines are merged
-- * list, last line, insert_empty_line: in case of success
-- * nil, err: in case of error
local function parse_indent(lines, source, i, indentLevel, insert_empty_line)
	i = i or 1
	indentLevel = indentLevel or 0
	local indented = {}
	while i <= #lines do
		if lines[i]:match("[^%s]") then
			local indent, line = lines[i]:match("^(%s*)(.*)$")
			if #indent == indentLevel then
				if insert_empty_line then
					table.insert(indented, { content = "", source = ("%s:%s"):format(source, insert_empty_line) })
					insert_empty_line = false
				end
				table.insert(indented, { content = line, source = ("%s:%s"):format(source, i) })
			elseif #indent > indentLevel then
				if #indented == 0 then
					return nil, ("unexpected indentation; at %s:%s"):format(source, i)
				else
					local t
					t, i, insert_empty_line = parse_indent(lines, source, i, #indent, insert_empty_line)
					if not t then return nil, i end
					indented[#indented].children = t
				end
			else
				return indented, i-1, insert_empty_line
			end
		elseif not insert_empty_line then
			insert_empty_line = i
		end
		i = i + 1
	end
	return indented, i-1, insert_empty_line
end

--- return the list of raw lines of s
local function parse_lines(s)
	local lines = {}
	for l in (s.."\n"):gmatch("(.-)\n") do
		table.insert(lines, l)
	end
	return lines
end

--- preparse shit: create AST structure, define variables and functions, but don't parse expression or perform any type checking
-- (wait for other files to be parsed before doing this with postparse)
-- * block: in case of success
-- * nil, err: in case of error
local function parse(state, s, name, source)
	-- parse lines
	local lines = parse_lines(s)
	local indented, e = parse_indent(lines, source or name)
	if not indented then return nil, e end
	-- wrap in named function if neccessary
	if name ~= "" then
		if not name:match("^"..identifier_pattern.."$") then
			return nil, ("invalid function name %q"):format(name)
		end
		indented = {
			{ content = "$ "..name, source = ("%s:%s"):format(source or name, 0), children = indented },
		}
	end
	-- transform ast
	indented = transform_indented(indented)
	-- build state proxy
	local state_proxy = {
		aliases = setmetatable({}, { __index = state.aliases }),
		variables = setmetatable({}, { __index = state.aliases }),
		functions = setmetatable({}, {
			__index = function(self, key)
				if state.functions[key] then
					local t = {} -- need to copy to allow ipairs over variants
					for k, v in ipairs(state.functions[key]) do
						t[k] = v
					end
					self[key] = t
					return t
				end
				return nil
			end
		}),
		queued_lines = {},
		global_state = state
	}
	-- parse
	local root, err = parse_block(indented, state_proxy, "")
	if not root then return nil, err end
	-- merge back state proxy into global state
	for k,v in pairs(state_proxy.aliases) do
		state.aliases[k] = v
	end
	for k,v in pairs(state_proxy.variables) do
		state.variables[k] = v
	end
	for k,v in pairs(state_proxy.functions) do
		if not state.functions[k] then
			state.functions[k] = v
		else
			for i,w in ipairs(v) do
				state.functions[k][i] = w
			end
		end
	end
	for _,l in ipairs(state_proxy.queued_lines) do
		table.insert(state.queued_lines, l)
	end
	-- return block
	return root
end

package.loaded[...] = parse
local common = require((...):gsub("preparser$", "common"))
format_identifier, identifier_pattern, escape, special_functions_names, pretty_signature, signature = common.format_identifier, common.identifier_pattern, common.escape, common.special_functions_names, common.pretty_signature, common.signature

return parse
