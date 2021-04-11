local expression
local format_identifier, identifier_pattern
local eval

-- * ast: if success
-- * nil, error: in case of error
local function parse_line(line, state, namespace)
	local l = line.content
	local r = {
		source = line.source
	}
	-- comment
	if l:match("^%(") then
		r.type = "comment"
		r.remove_from_block_ast = true
		return r
	end
	-- decorators
	while l:match("^..+[~#]") or l:match("^..+§") do
		-- condition
		if l:match("^..+%~.-$") then
			local expr
			l, expr = l:match("^(.-)%s*%~(.-)$")
			r.condition = expr
		-- paragraph
		elseif l:match("^..+§.-$") then
			-- get identifier
			local name
			l, name = l:match("^(.-)%s*§(.-)$")
			local identifier, rem = name:match("^("..identifier_pattern..")(.-)$")
			if not identifier then return nil, ("no valid identifier in paragraph decorator %q; at %s"):format(identifier, line.source) end
			-- format identifier
			local fqm = ("%s%s"):format(namespace, format_identifier(identifier))
			-- get alias
			if rem:match("^%:") then
				local content = rem:sub(2)
				local alias, rem2 = content:match("^("..identifier_pattern..")(.-)$")
				if not alias then return nil, ("expected an identifier in alias in paragraph decorator, but got %q; at %s"):format(content, line.source) end
				if rem2:match("[^%s]") then return nil, ("expected end-of-line after identifier in alias in paragraph decorator, but got %q; at %s"):format(rem2, line.source) end
				-- format alias
				local aliasfqm = ("%s%s"):format(namespace, format_identifier(alias))
				-- define alias
				if state.aliases[aliasfqm] ~= nil and state.aliases[aliasfqm] ~= fqm then
					return nil, ("trying to define alias %q for variable %q, but already exist and refer to different variable %q; at %s"):format(aliasfqm, fqm, state.aliases[aliasfqm], line.source)
				end
				state.aliases[aliasfqm] = fqm
			elseif rem:match("[^%s]") then
				return nil, ("expected end-of-line after identifier in paragraph decorator, but got %q; at %s"):format(rem, line.source)
			end
			-- define paragraph
			namespace = fqm.."."
			r.paragraph = true
			r.parent_function = true
			r.namespace = fqm.."."
			r.name = fqm
			if not state.functions[fqm] then
				state.functions[fqm] = {
					{
						arity = 0,
						value = r
					}
				}
				if not state.variables[fqm..".👁️"] then
					state.variables[fqm..".👁️"] = {
						type = "number",
						value = 0
					}
				end
				-- define alias for 👁️
				local seen_alias = state.builtin_aliases["👁️"]
				if seen_alias then
					local alias = ("%s.%s"):format(fqm, seen_alias)
					if state.aliases[alias] ~= nil and state.aliases[alias] then
						return nil, ("trying to define alias %q for variable %q, but already exist and refer to different variable %q; at %s"):format(alias, fqm..".👁️", state.aliases[alias], line.source)
					end
					state.aliases[alias] = fqm..".👁️"
				end
			else
				table.insert(state.functions[fqm], {
					arity = 0,
					value = r
				})
			end
		-- tag
		elseif l:match("^..+%#.-$") then
			local expr
			l, expr = l:match("^(.-)%s*%#(.-)$")
			r.tag = expr
		end
	end
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
	-- function & paragraph
	elseif l:match("^%$") or l:match("^§") then -- § is a 2-bytes caracter, DO NOT USE LUA PATTERN OPERATORS as they operate on single bytes
		r.type = l:match("^%$") and "function" or "paragraph"
		r.child = true
		-- get identifier
		local lc = l:match("^%$(.*)$") or l:match("^§(.*)$")
		local identifier, rem = lc:match("^("..identifier_pattern..")(.-)$")
		if not identifier then return nil, ("no valid identifier in paragraph/function definition line %q; at %s"):format(lc, line.source) end
		-- format identifier
		local fqm = ("%s%s"):format(namespace, format_identifier(identifier))
		-- get alias
		if rem:match("^%:") then
			local content = rem:sub(2)
			local alias
			alias, rem = content:match("^("..identifier_pattern..")(.-)$")
			if not alias then return nil, ("expected an identifier in alias in paragraph/function definition line, but got %q; at %s"):format(content, line.source) end
			-- format alias
			local aliasfqm = ("%s%s"):format(namespace, format_identifier(alias))
			-- define alias
			if state.aliases[aliasfqm] ~= nil and state.aliases[aliasfqm] ~= fqm then
				return nil, ("trying to define alias %q for function/paragraph %q, but already exist and refer to %q; at %s"):format(aliasfqm, fqm, state.aliases[aliasfqm], line.source)
			end
			state.aliases[aliasfqm] = fqm
		end
		-- get params
		r.params = {}
		if r.type == "function" and rem:match("^%b()$") then
			local content = rem:gsub("^%(", ""):gsub("%)$", "")
			for param in content:gmatch("[^%,]+") do
				-- get identifier
				local param_identifier, param_rem = param:match("^("..identifier_pattern..")(.-)$")
				if not identifier then return nil, ("no valid identifier in function parameter %q; at %s"):format(param, line.source) end
				-- format identifier
				local param_fqm = ("%s.%s"):format(fqm, format_identifier(param_identifier))
				-- get alias
				if param_rem:match("^%:") then
					local param_content = param_rem:sub(2)
					local alias
					alias, param_rem = param_content:match("^("..identifier_pattern..")(.-)$")
					if not alias then return nil, ("expected an identifier in alias in parameter, but got %q; at %s"):format(param_content, line.source) end
					-- format alias
					local aliasfqm = ("%s.%s"):format(fqm, format_identifier(alias))
					-- define alias
					if state.aliases[aliasfqm] ~= nil and state.aliases[aliasfqm] ~= param_fqm then
						return nil, ("trying to define alias %q for parameter %q, but already exist and refer to %q; at %s"):format(aliasfqm, param_fqm, state.aliases[aliasfqm], line.source)
					end
					state.aliases[aliasfqm] = param_fqm
				end
				if param_rem:match("[^%s]") then
					return nil, ("unexpected characters after parameter %q: %q; at %s"):format(param_fqm, param_rem, line.source)
				end
				-- add parameter
				table.insert(r.params, param_fqm)
			end
		elseif rem:match("[^%s]") then
			return nil, ("expected end-of-line at end of paragraph/function definition line, but got %q; at %s"):format(rem, line.source)
		end
		local arity, vararg = #r.params, nil
		if arity > 0 and r.params[arity]:match("%.%.%.$") then -- varargs
			r.params[arity] = r.params[arity]:match("^(.*)%.%.%.$")
			vararg = arity
			arity = { arity-1, math.huge }
		end
		-- store parent function and run paragraph when line is read
		if r.type == "paragraph" then
			r.paragraph = true
			r.parent_function = true
		end
		-- don't keep function node in block AST
		if r.type == "function" then
			r.remove_from_block_ast = true
		end
		-- define function and variables
		r.namespace = fqm.."."
		r.name = fqm
		if state.variables[fqm] then return nil, ("trying to define %s %s, but a variable with the same name exists; at %s"):format(r.type, fqm, line.source) end
		r.variant = {
			arity = arity,
			types = {},
			vararg = vararg,
			value = r
		}
		-- new function (no overloading yet)
		if not state.functions[fqm] then
			state.functions[fqm] = { r.variant }
			-- define 👁️ variable
			if not state.variables[fqm..".👁️"] then
				state.variables[fqm..".👁️"] = {
					type = "number",
					value = 0
				}
			end
			-- define alias for 👁️
			local seen_alias = state.builtin_aliases["👁️"]
			if seen_alias then
				local alias = ("%s.%s"):format(fqm, seen_alias)
				if state.aliases[alias] ~= nil and state.aliases[alias] then
					return nil, ("trying to define alias %q for variable %q, but already exist and refer to different variable %q; at %s"):format(alias, fqm..".👁️", state.aliases[alias], line.source)
				end
				state.aliases[alias] = fqm..".👁️"
			end
			if r.type == "function" then
				-- define 🏁 variable
				if not state.variables[fqm..".🏁"] then
					state.variables[fqm..".🏁"] = {
						type = "string",
						value = ""
					}
				end
				-- define alias for 🏁
				local checkpoint_alias = state.builtin_aliases["🏁"]
				if checkpoint_alias then
					local alias = ("%s.%s"):format(fqm, checkpoint_alias)
					if state.aliases[alias] ~= nil and state.aliases[alias] then
						return nil, ("trying to define alias %q for variable %q, but already exist and refer to different variable %q; at %s"):format(alias, fqm..".🏁", state.aliases[alias], line.source)
					end
					state.aliases[alias] = fqm..".🏁"
				end
			end
		-- overloading
		else
			-- check for arity conflict
			for _, variant in ipairs(state.functions[fqm]) do
				local vmin, vmax = 0, math.huge
				if type(variant.arity) == "table" then
					vmin, vmax = variant.arity[1], variant.arity[2]
				elseif variant.arity then
					vmin, vmax = variant.arity, variant.arity
				end
				local min, max = 0, math.huge
				if type(r.variant.arity) == "table" then
					min, max = r.variant.arity[1], r.variant.arity[2]
				elseif r.variant.arity then
					min, max = variant.arity, r.variant.arity
				end
				if min == vmin and max == vmax then
					return nil, ("trying to define %s %s with arity [%s;%s], but another function with the same name and arity exist; at %s"):format(r.type, fqm, min, max, line.source)
				end
			end
			-- add
			table.insert(state.functions[fqm], r.variant)
		end
		-- define args and set type check information
		for i, param in ipairs(r.params) do
			if not state.variables[param] then
				state.variables[param] = {
					type = "undefined argument",
					value = { r.variant, i }
				}
			elseif state.variables[param].type ~= "undefined argument" then
				r.variant.types[i] = state.variables[param].type
			end
		end
	-- definition
	elseif l:match("^:") then
		r.type = "definition"
		r.remove_from_block_ast = true
		-- get expression
		local exp, rem = expression(l:match("^:(.*)$"), state, namespace) -- expression parsing is done directly to get type information
		if not exp then return nil, ("%s; at %s"):format(rem, line.source) end
		-- get identifier
		local identifier, rem2 = rem:match("^("..identifier_pattern..")(.-)$")
		if not identifier then return nil, ("no valid identifier after expression in definition line %q; at %s"):format(rem, line.source) end
		-- format identifier
		local fqm = ("%s%s"):format(namespace, format_identifier(identifier))
		-- get alias
		if rem2:match("^%:") then
			local content = rem2:sub(2)
			local alias, rem3 = content:match("^("..identifier_pattern..")(.-)$")
			if not alias then return nil, ("expected an identifier in alias in definition line, but got %q; at %s"):format(content, line.source) end
			if rem3:match("[^%s]") then return nil, ("expected end-of-line after identifier in alias in definition line, but got %q; at %s"):format(rem3, line.source) end
			-- format alias
			local aliasfqm = ("%s%s"):format(namespace, format_identifier(alias))
			-- define alias
			if state.aliases[aliasfqm] ~= nil and state.aliases[aliasfqm] ~= fqm then
				return nil, ("trying to define alias %s for variable %s, but already exist and refer to different variable %s; at %s"):format(aliasfqm, fqm, state.aliases[aliasfqm], line.source)
			end
			state.aliases[aliasfqm] = fqm
		elseif rem2:match("[^%s]") then
			return nil, ("expected end-of-line after identifier in definition line, but got %q; at %s"):format(rem2, line.source)
		end
		-- define identifier
		if state.functions[fqm] then return nil, ("trying to define variable %s, but a function with the same name exists; at %s"):format(fqm, line.source) end
		if not state.variables[fqm] or state.variables[fqm].type == "undefined argument" then
			local v, e = eval(state, exp)
			if not v then return v, e end
			-- update function typecheck information
			if state.variables[fqm] and state.variables[fqm].type == "undefined argument" then
				local und = state.variables[fqm].value
				und[1].types[und[2]] = v.type
			end
			state.variables[fqm] = v
		elseif state.variables[fqm].type ~= exp.type then
			return nil, ("trying to define variable %s of type %s but it is already defined with type %s; at %s"):format(fqm, exp.type, state.variables[fqm].type, line.source)
		end
	-- tag
	elseif l:match("^%#") then
		r.type = "tag"
		r.child = true
		local expr = l:match("^%#(.*)$")
		if expr:match("[^%s]") then
			r.expression = expr
		else
			r.expression = nil
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
	local lastLine -- last line AST
	for i, l in ipairs(indented) do
		-- parsable line
		if l.content then
			local ast, err = parse_line(l, state, namespace)
			if err then return nil, err end
			lastLine = ast
			-- store parent function
			if ast.parent_function then ast.parent_function = parent_function end
			-- add to block AST
			if not ast.remove_from_block_ast then
				ast.parent_block = block
				-- add ast node
				ast.parent_position = #block+1
				if ast.replace_with then
					if indented[i+1].content then
						table.insert(indented, i+1, { content = ast.replace_with, source = l.source })
					else
						table.insert(indented, i+2, { content = ast.replace_with, source = l.source }) -- if line has children
					end
				else
					table.insert(block, ast)
				end
			end
			-- add child
			if ast.child then ast.child = { type = "block", parent_line = ast } end
			-- queue in expression evalution
			table.insert(state.queued_lines, { namespace = ast.namespace or namespace, line = ast })
		-- indented (ignore block comments)
		elseif lastLine.type ~= "comment" then
			if not lastLine.child then
				return nil, ("line %s (%s) can't have children"):format(lastLine.source, lastLine.type)
			else
				local r, e = parse_block(l, state, lastLine.namespace or namespace, lastLine.type == "function" and lastLine or parent_function)
				if not r then return r, e end
				r.parent_line = lastLine
				lastLine.child = r
			end
		end
	end
	return block
end

--- returns the nested list of lines {content="", line=1}, grouped by indentation
-- multiple empty lines are merged
-- * list, last line
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
				local t
				t, i, insert_empty_line = parse_indent(lines, source, i, #indent, insert_empty_line)
				table.insert(indented, t)
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
-- * state: in case of success
-- * nil, err: in case of error
local function parse(state, s, name, source)
	-- parse lines
	local lines = parse_lines(s)
	local indented = parse_indent(lines, source or name)
	-- wrap in named function if neccessary
	if name ~= "" then
		if not name:match("^"..identifier_pattern.."$") then
			return nil, ("invalid function name %q"):format(name)
		end
		indented = {
			{ content = "$ "..name, source = ("%s:%s"):format(source or name, 0) },
			indented
		}
	end
	-- parse
	local root, err = parse_block(indented, state, "")
	if not root then return nil, err end
	return state
end

package.loaded[...] = parse
expression = require((...):gsub("preparser$", "expression"))
local common = require((...):gsub("preparser$", "common"))
format_identifier, identifier_pattern = common.format_identifier, common.identifier_pattern
eval = require((...):gsub("parser%.preparser$", "interpreter.expression"))

return parse
