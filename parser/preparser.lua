local expression
local format_identifier, identifier_pattern
local eval

-- * ast: if success
-- * nil, error: in case of error
local function parse_line(line, state, namespace)
	local l = line.content
	local r = {
		line = line.line
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
			local name
			l, name = l:match("^(.-)%s*§(.-)$")
			local fqm = ("%s%s"):format(namespace, format_identifier(name, state))
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
		local fqm = ("%s%s"):format(namespace, format_identifier(l:match("^%$(.*)$") or l:match("^§(.*)$"), state))
		-- get params
		r.params = {}
		if r.type == "function" and fqm:match("%b()$") then
			local content
			fqm, content = fqm:match("^(.-)(%b())$")
			content = content:gsub("^%(", ""):gsub("%)$", "")
			for param in content:gmatch("[^%,]+") do
				table.insert(r.params, format_identifier(("%s.%s"):format(fqm, param), state))
			end
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
			if not state.variables[fqm..".🏁"] then
				state.variables[fqm..".🏁"] = {
					type = "string",
					value = ""
				}
			end
		end
		-- define function and variables
		r.namespace = fqm.."."
		r.name = fqm
		if state.variables[fqm] then return nil, ("trying to define %s %s, but a variable with the same name exists; at line %s"):format(r.type, fqm, line.line) end
		r.variant = {
			arity = arity,
			types = {},
			vararg = vararg,
			value = r
		}
		if not state.functions[fqm] then
			state.functions[fqm] = { r.variant }
			if not state.variables[fqm..".👁️"] then
				state.variables[fqm..".👁️"] = {
					type = "number",
					value = 0
				}
			end
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
					return nil, ("trying to define %s %s with arity [%s;%s], but another function with the arity exist; at line %s"):format(r.type, fqm, min, max, line.line)
				end
			end
			-- add
			table.insert(state.functions[fqm], r.variant)
		end
		-- set type check information
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
		local exp, rem = expression(l:match("^:(.*)$"), state, namespace) -- expression parsing is done directly to get type information
		if not exp then return nil, ("%s; at line %s"):format(rem, line.line) end
		local fqm = ("%s%s"):format(namespace, format_identifier(rem, state))
		if state.functions[fqm] then return nil, ("trying to define variable %s, but a function with the same name exists; at line %s"):format(fqm, line.line) end
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
			return nil, ("trying to define variable %s of type %s but a it is already defined with type %s; at line %s"):format(fqm, exp.type, state.variables[fqm].type, line.line)
		end
	-- tag
	elseif l:match("^%#") then
		r.type = "tag"
		r.child = true
		r.expression = l:match("^%#(.*)$")
	-- return
	elseif l:match("^%@") then
		r.type = "return"
		r.parent_function = true
		r.expression = l:match("^%@(.*)$")
	-- text
	elseif l:match("[^%s]") then
		r.type = "text"
		r.push_event = "text"
		r.text = l
	-- flush events
	else
		r.type = "flush_events"
	end
	if not r.type then return nil, ("unknown line %s type"):format(line.line) end
	return r
end

-- * block: in case of success
-- * nil, err: in case of error
local function parse_block(indented, state, namespace, parent_function, last_event)
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
				-- insert flush on event type change
				if ast.type == "flush" then last_event = nil end
				if ast.push_event then
					if last_event and ast.push_event ~= last_event then
						table.insert(block, { line = l.line, type = "flush_events" })
					end
					last_event = ast.push_event
				end
				-- add ast node
				ast.parent_position = #block+1
				if ast.replace_with then
					if indented[i+1].content then
						table.insert(indented, i+1, { content = ast.replace_with, line = l.line })
					else
						table.insert(indented, i+2, { content = ast.replace_with, line = l.line }) -- if line has children
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
				return nil, ("line %s (%s) can't have children"):format(lastLine.line, lastLine.type)
			else
				local r, e = parse_block(l, state, lastLine.namespace or namespace, lastLine.type == "function" and lastLine or parent_function, last_event)
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
local function parse_indent(lines, i, indentLevel, insert_empty_line)
	i = i or 1
	indentLevel = indentLevel or 0
	local indented = {}
	while i <= #lines do
		if lines[i]:match("[^%s]") then
			local indent, line = lines[i]:match("^(%s*)(.*)$")
			if #indent == indentLevel then
				if insert_empty_line then
					table.insert(indented, { content = "", line = insert_empty_line })
					insert_empty_line = false
				end
				table.insert(indented, { content = line, line = i })
			elseif #indent > indentLevel then
				local t
				t, i = parse_indent(lines, i, #indent, insert_empty_line)
				table.insert(indented, t)
			else
				return indented, i-1
			end
		elseif not insert_empty_line then
			insert_empty_line = i
		end
		i = i + 1
	end
	return indented, i-1
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
local function parse(state, s, name)
	-- parse lines
	local lines = parse_lines(s)
	local indented = parse_indent(lines)
	-- wrap in named function if neccessary
	if name ~= "" then
		if not name:match("^"..identifier_pattern.."$") then
			return nil, ("invalid function name %q"):format(name)
		end
		indented = {
			{ content = "$ "..name, line = 0 },
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
