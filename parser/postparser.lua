local expression
local parse_text

-- * true: if success
-- * nil, error: in case of error
local function parse(state)
	-- expression parsing
	for i=#state.queued_lines, 1, -1 do
		local l = state.queued_lines[i]
		local line, namespace = l.line, l.namespace
		-- default arguments and type constraints
		if line.type == "function" then
			for _, param in ipairs(line.params) do
				-- get type constraints
				if param.type_constraint then
					local type_exp, rem = expression(param.type_constraint, state, namespace, line.source)
					if not type_exp then return nil, ("in type constraint, %s; at %s"):format(rem, line.source) end
					if rem:match("[^%s]") then
						return nil, ("unexpected characters after parameter %q: %q; at %s"):format(param.full_name, rem, line.source)
					end
					state.variable_metadata[param.full_name].constraint = { pending = type_exp }
				end
				-- get default value
				if param.default then
					local default_exp, rem = expression(param.default, state, namespace, line.source)
					if not default_exp then return nil, ("in default value, %s; at %s"):format(rem, line.source) end
					if rem:match("[^%s]") then
						return nil, ("unexpected characters after parameter %q: %q; at %s"):format(param.full_name, rem, line.source)
					end
					param.default = default_exp
					-- extract type constraint from default value
					if default_exp.type == "function call" and default_exp.called_name == "_::_" then
						state.variable_metadata[param.full_name].constraint = { pending = default_exp.argument.expression.right }
					end
				end
			end
			-- assignment argument
			if line.assignment and line.assignment.type_constraint then
				local type_exp, rem = expression(line.assignment.type_constraint, state, namespace, line.source)
				if not type_exp then return nil, ("in type constraint, %s; at %s"):format(rem, line.source) end
				if rem:match("[^%s]") then
					return nil, ("unexpected characters after parameter %q: %q; at %s"):format(line.assignment.full_name, rem, line.source)
				end
				state.variable_metadata[line.assignment.full_name].constraint = { pending = type_exp }
			end
			-- get list of scoped variables
			-- (note includes every variables in the namespace of subnamespace, so subfunctions are scoped alongside this function)
			if line.scoped then
				line.scoped = {}
				for name in pairs(state.variables) do
					if name:sub(1, #namespace) == namespace then
						if state.variable_metadata[name].persistent then return nil, ("variable %q can not be persistent as it is in a scoped function"):format(name) end
						table.insert(line.scoped, name)
					end
				end
			end
			-- get list of properties
			-- (unlike scoped, does not includes subnamespaces)
			if line.properties then
				line.properties = {}
				for name in pairs(state.variables) do
					if name:sub(1, #namespace) == namespace and not name:sub(#namespace+1):match("%.") then
						table.insert(line.properties, name)
					end
				end
			end
		end
		-- expressions
		if line.expression and type(line.expression) == "string" then
			local exp, rem = expression(line.expression, state, namespace, line.source)
			if not exp then return nil, ("%s; at %s"):format(rem, line.source) end
			if rem:match("[^%s]") then return nil, ("expected end of expression before %q; at %s"):format(rem, line.source) end
			line.expression = exp
			-- variable pending definition: expression will be evaluated when variable is needed
			if line.type == "definition" then
				state.variables[line.name].value.expression = line.expression
				-- parse constraints
				if line.constraint then
					local type_exp, rem2 = expression(line.constraint, state, namespace, line.source)
					if not type_exp then return nil, ("in type constraint, %s; at %s"):format(rem2, line.source) end
					if rem2:match("[^%s]") then
						return nil, ("unexpected characters after variable %q: %q; at %s"):format(line.name, rem2, line.source)
					end
					state.variable_metadata[line.name].constraint = { pending = type_exp }
				end
			end
		end
		-- text (text & choice lines)
		if line.text then
			local txt, err = parse_text(line.text, state, namespace, "text", "#~", true)
			if not txt then return nil, ("%s; at %s"):format(err, line.source) end
			if err:match("[^%s]") then return nil, ("expected end of expression in end-of-text expression before %q"):format(err) end
			line.text = txt
		end
		table.remove(state.queued_lines, i)
	end
	if #state.queued_lines > 0 then -- lines were added during post-parsing, process these
		return parse(state)
	else
		return true
	end
end

package.loaded[...] = parse
expression = require((...):gsub("postparser$", "expression"))
local common = require((...):gsub("postparser$", "common"))
parse_text = common.parse_text

--- postparse shit: parse expressions and do variable existence and type checking
return parse
