local format_identifier, identifier_pattern, escape, special_functions_names, pretty_signature, signature, copy, injections

local parse_indented

--- try to define an alias using rem, the text that follows the identifier
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

--- inject lines defined for the injection that match parent_function type and inject_type in inject_in starting from index inject_at
local function inject(state, parent_function, inject_type, inject_in, inject_at)
	inject_at = inject_at or #inject_in+1
	local prefix
	if parent_function.subtype == "checkpoint" then
		prefix = "checkpoint"
	elseif parent_function.subtype == "class" then
		prefix = "class"
	elseif parent_function.scoped then
		prefix = "scoped_function"
	else
		prefix = "function"
	end
	local ninject = ("%s_%s"):format(prefix, inject_type)
	if state.inject[ninject] then
		for i, ll in ipairs(state.inject[ninject]) do
			table.insert(inject_in, inject_at+i-1, copy(ll))
		end
	end
end

--- parse a single line into AST
-- * ast: if success
-- * nil, error: in case of error
local function parse_line(line, state, namespace, parent_function)
	local l = line.content
	local r = {
		source = line.source
	}
	-- else-condition, condition & while
	if l:match("^~[~%?]?") then
		if l:match("^~~") then
			r.type = "else-condition"
		elseif l:match("^~%?") then
			r.type = "while"
		else
			r.type = "condition"
		end
		r.child = true
		local expr = l:match("^~[~%?]?(.*)$")
		if expr:match("[^%s]") then
			r.expression = expr
		else
			r.expression = "1"
		end
	-- choice
	elseif l:match("^>") then
		r.type = "choice"
		r.child = true
		r.text = l:match("^>%s*(.-)$")
	-- definition
	elseif l:match("^:") then
		local lr = l:match("^:(.*)$")
		-- immediately run variable
		local run_immediately = false
		if lr:match("^~") then
			lr = lr:match("^~(.*)$")
			run_immediately = true
		end
		-- function & checkpoint
		if lr:match("^%$") or lr:match("^%!") or lr:match("^%%") then -- § is a 2-bytes caracter, DO NOT USE LUA PATTERN OPERATORS as they operate on single bytes
			r.type = "function"
			r.child = true
			-- subtype options
			local allow_params = true
			local allow_assign = true
			local keep_in_ast = false
			if lr:match("^%$") then
				r.subtype = "function"
				r.resume_boundary = true
			elseif lr:match("^%%") then
				r.subtype = "class"
				r.resume_boundary = true
				allow_params = false
				allow_assign = false
			elseif lr:match("^%!") then
				r.subtype = "checkpoint"
				allow_params = false
				allow_assign = false
				keep_in_ast = true
				r.parent_function = parent_function -- store parent function and run checkpoint when line is read
			else
				error("unknown function line type")
			end
			-- don't keep function node in block AST
			if not keep_in_ast then
				r.remove_from_block_ast = true
			end
			-- lua function
			if r.subtype == "function" and state.global_state.link_next_function_definition_to_lua_function then
				r.lua_function = state.global_state.link_next_function_definition_to_lua_function
				state.global_state.link_next_function_definition_to_lua_function = nil
			end
			-- get identifier
			local lc = lr:match("^[%$%%%!](.-)$")
			local identifier, rem = lc:match("^("..identifier_pattern..")(.-)$")
			if not identifier then
				for _, name in ipairs(special_functions_names) do
					identifier, rem = lc:match("^(%s*"..escape(name).."%s*)(.-)$")
					if identifier then break end
				end
			end
			if not identifier then
				return nil, ("no valid identifier in function definition line %q; at %s"):format(lc, line.source)
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
				func_namespace = ("%s(%s)."):format(fqm, tostring(r))
				r.private_namespace = true
			end
			-- define function
			if state.variables[fqm] then return nil, ("trying to define %s %s, but a variable with the same name exists; at %s"):format(r.type, fqm, line.source) end
			r.namespace = func_namespace
			r.name = fqm
			-- get params
			r.params = {}
			if allow_params and rem:match("^%b()") then
				r.scoped = true
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
					-- get potential type constraints and default value
					local type_constraint, default
					if param_rem:match("^::") then
						type_constraint = param_rem:match("^::(.*)$")
					elseif param_rem:match("^=") then
						default = param_rem:match("^=(.*)$")
					elseif param_rem:match("[^%s]") then
						return nil, ("unexpected characters after parameter %q: %q; at %s"):format(param_fqm, param_rem, line.source)
					end
					-- add parameter
					table.insert(r.params, { name = param_identifier, alias = param_alias, full_name = param_fqm, type_constraint = type_constraint, default = default, vararg = nil })
				end
			end
			-- get assignment param
			if allow_assign and rem:match("^%:%=") then
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
				-- get potential type constraint
				local type_constraint
				if param_rem:match("^::") then
					type_constraint = param_rem:match("^::(.*)$")
				elseif param_rem:match("[^%s]") then
					return nil, ("unexpected characters after parameter %q: %q; at %s"):format(param_fqm, param_rem, line.source)
				end
				-- add parameter
				r.assignment = { name = param_identifier, alias = param_alias, full_name = param_fqm, type_constraint = type_constraint, default = nil, vararg = nil }
			elseif rem:match("[^%s]") then
				return nil, ("expected end-of-line at end of function definition line, but got %q; at %s"):format(rem, line.source)
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
			if r.subtype ~= "checkpoint" then
				-- define 🔖 variable
				local checkpoint_alias = state.global_state.builtin_aliases["🔖"]
				if checkpoint_alias then
					table.insert(line.children, 1, { content = (":🔖:%s=()"):format(checkpoint_alias), source = line.source })
				else
					table.insert(line.children, 1, { content = ":🔖=()", source = line.source })
				end
				-- custom code injection
				inject(state, r, "start", line.children, 2)
				inject(state, r, "end", line.children)
			elseif r.subtype == "checkpoint" then
				-- define 🏁 variable
				local reached_alias = state.global_state.builtin_aliases["🏁"]
				if reached_alias then
					table.insert(line.children, 1, { content = (":🏁:%s=0"):format(reached_alias), source = line.source })
				else
					table.insert(line.children, 1, { content = ":🏁=0", source = line.source })
				end
				-- custom code injection
				inject(state, r, "start", line.children, 2)
				inject(state, r, "end", line.children)
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
		-- variable and constants
		else
			r.type = "definition"
			r.remove_from_block_ast = true
			local rem = lr
			-- check if constant
			if rem:match("^:") then
				rem = rem:match("^:(.*)$")
				r.constant = true
			end
			-- get identifier
			local identifier
			identifier, rem = rem:match("^("..identifier_pattern..")(.-)$")
			if not identifier then return nil, ("no valid identifier at start of definition line %q; at %s"):format(l, line.source) end
			-- format identifier
			local fqm = ("%s%s"):format(namespace, format_identifier(identifier))
			-- get alias
			local ok_alias
			ok_alias, rem = maybe_alias(rem, fqm, namespace, line, state)
			if not ok_alias then return ok_alias, rem end
			-- type constraint
			if rem:match("^::(.-)=") then
				r.constraint, rem = rem:match("^::%s*(.-)%s*(=.*)$")
			end
			-- get expression
			local exp = rem:match("^=(.*)$")
			if not exp then return nil, ("expected \"= expression\" after %q in definition line; at %s"):format(rem, line.source) end
			-- define identifier
			if state.functions[fqm] then return nil, ("trying to define variable %q, but a function with the same name exists; at %s"):format(fqm, line.source) end
			if state.variables[fqm] then
				if state.variables[fqm].type == "pending definition" then
					return nil, ("trying to define variable %q but it is already defined at %s; at %s"):format(fqm, state.variables[fqm].value.source, line.source)
				else
					return nil, ("trying to define variable %q but it is already defined; at %s"):format(fqm, line.source)
				end
			end
			r.name = fqm
			r.expression = exp
			state.variables[fqm] = { type = "pending definition", value = { expression = nil, source = r.source } }
			if r.constant then state.variable_constants[fqm] = true end
		end
		-- add expression line after to perform the immediate execution
		if run_immediately then
			line.line_after = { content = "~ "..r.name, source = line.source }
		end
	-- tag
	elseif l:match("^%#") then
		r.type = "tag"
		r.child = true
		local expr = l:match("^%#(.*)$")
		r.expression = ("{%s}"):format(expr)
	-- return
	elseif l:match("^%@") then
		r.type = "return"
		r.child = true
		r.parent_function = parent_function
		local expr = l:match("^%@(.*)$")
		if expr:match("[^%s]") then
			r.expression = expr
		else
			r.expression = "()"
		end
		-- custom code injection
		if not line.children then line.children = {} end
		inject(state, parent_function, "return", line.children)
	-- text
	elseif l:match("[^%s]") then
		r.type = "text"
		r.text = l
	-- flush events
	else
		r.type = "flush_events"
	end
	if not r.type then return nil, ("unknown line %s type"):format(line.source) end
	return r
end

--- parse an indented into final AST
-- * block: in case of success
-- * nil, err: in case of error
local function parse_block(indented, state, namespace, parent_function)
	local block = { type = "block" }
	for i, l in ipairs(indented) do
		-- parsable line
		local ast, err = parse_line(l, state, namespace, parent_function)
		if err then return nil, err end
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
				local r, e = parse_block(l.children, state, ast.namespace or namespace, (ast.type == "function" and ast.subtype ~= "checkpoint") and ast or parent_function)
				if not r then return r, e end
				r.parent_line = ast
				ast.child = r
			end
		end

		-- insert line after
		if l.line_after then
			table.insert(indented, i+1, l.line_after)
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
			i = i + 1
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

--- make indented from intial string
-- * list: in case of success
-- * nil, err: in case of error
parse_indented = function(s, fnname, source)
	source = source or fnname
	-- parse lines
	local lines = parse_lines(s)
	local indented, e = parse_indent(lines, source)
	if not indented then return nil, e end
	-- wrap in named function if neccessary
	if fnname ~= nil and fnname ~= "" then
		if not fnname:match("^"..identifier_pattern.."$") then
			return nil, ("invalid function name %q"):format(fnname)
		end
		indented = {
			{ content = ":$ "..fnname, source = ("%s:%s"):format(source, 0), children = indented },
		}
	end
	-- transform ast
	indented = transform_indented(indented)
	return indented
end

--- preparse shit: create AST structure, define variables and functions, but don't parse expression or perform any type checking
-- (wait for other files to be parsed before doing this with postparse)
-- * block: in case of success
-- * nil, err: in case of error
local function parse(state, s, name, source)
	-- get indented
	local indented, e = parse_indented(s, name, source)
	if not indented then return nil, e end
	-- build state proxy
	local state_proxy = {
		inject = {},
		aliases = setmetatable({}, { __index = state.aliases }),
		variable_constraints = setmetatable({}, { __index = state.variable_constraints }),
		variable_constants = setmetatable({}, { __index = state.variable_constants }),
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
	-- parse injects
	for tinject, ninject in pairs(injections) do
		if state.inject[ninject] then
			local inject_indented, err = parse_indented(state.inject[ninject], nil, "injected "..tinject)
			if not inject_indented then return nil, err end
			state_proxy.inject[ninject] = inject_indented
		end
	end
	-- parse
	local root, err = parse_block(indented, state_proxy, "")
	if not root then return nil, err end
	-- merge back state proxy into global state
	for k,v in pairs(state_proxy.aliases) do
		state.aliases[k] = v
	end
	for k,v in pairs(state_proxy.variable_constraints) do
		state.variable_constraints[k] = v
	end
	for k,v in pairs(state_proxy.variable_constants) do
		state.variable_constants[k] = v
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
format_identifier, identifier_pattern, escape, special_functions_names, pretty_signature, signature, injections = common.format_identifier, common.identifier_pattern, common.escape, common.special_functions_names, common.pretty_signature, common.signature, common.injections
copy = require((...):gsub("parser%.preparser$", "common")).copy

return parse
