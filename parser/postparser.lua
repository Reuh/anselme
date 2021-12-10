local expression
local parse_text

-- * true: if success
-- * nil, error: in case of error
local function parse(state)
	-- expression parsing
	for i=#state.queued_lines, 1, -1 do
		local l = state.queued_lines[i]
		local line, namespace = l.line, l.namespace
		-- default arguments and type annotation
		if line.type == "function" then
			for _, param in ipairs(line.params) do
				-- get type annotation
				if param.type_annotation then
					local type_exp, rem = expression(param.type_annotation, state, namespace)
					if not type_exp then return nil, ("in type annotation, %s; at %s"):format(rem, line.source) end
					if rem:match("[^%s]") then
						return nil, ("unexpected characters after parameter %q: %q; at %s"):format(param.full_name, rem, line.source)
					end
					param.type_annotation = type_exp
				end
				-- get default value
				if param.default then
					local default_exp, rem = expression(param.default, state, namespace)
					if not default_exp then return nil, ("in default value, %s; at %s"):format(rem, line.source) end
					if rem:match("[^%s]") then
						return nil, ("unexpected characters after parameter %q: %q; at %s"):format(param.full_name, rem, line.source)
					end
					param.default = default_exp
					-- extract type annotation from default value
					if default_exp.type == "function call" and default_exp.called_name == "_::_" then
						param.type_annotation = default_exp.argument.expression.right
					end
				end
			end
			-- assignment argument
			if line.assignment and line.assignment.type_annotation then
				local type_exp, rem = expression(line.assignment.type_annotation, state, namespace)
				if not type_exp then return nil, ("in type annotation, %s; at %s"):format(rem, line.source) end
				if rem:match("[^%s]") then
					return nil, ("unexpected characters after parameter %q: %q; at %s"):format(line.assignment.full_name, rem, line.source)
				end
				line.assignment.type_annotation = type_exp
			end
			-- get list of scoped variables
			-- (note includes every variables in the namespace of subnamespace, so subfunctions are scoped alongside this function)
			if line.scoped then
				line.scoped = {}
				for name in pairs(state.variables) do
					if name:sub(1, #namespace) == namespace then
						table.insert(line.scoped, name)
					end
				end
			end
		end
		-- expressions
		if line.expression then
			local exp, rem = expression(line.expression, state, namespace)
			if not exp then return nil, ("%s; at %s"):format(rem, line.source) end
			if rem:match("[^%s]") then return nil, ("expected end of expression before %q; at %s"):format(rem, line.source) end
			line.expression = exp
			-- variable pending definition: expression will be evaluated when variable is needed
			if line.type == "definition" then
				state.variables[line.fqm].value.expression = line.expression
			end
		end
		-- text (text & choice lines)
		if line.text then
			local txt, err = parse_text(line.text, state, namespace, "text", "#~", true)
			if not txt then return nil, ("%s; at %s"):format(err, line.source) end
			if err:match("[^%s]") then return nil, ("expected end of expression in end-of-text expression before %q"):format(err) end
			line.text = txt
		end
		state.queued_lines[i] = nil
	end
	return true
end

package.loaded[...] = parse
expression = require((...):gsub("postparser$", "expression"))
local common = require((...):gsub("postparser$", "common"))
parse_text = common.parse_text

--- postparse shit: parse expressions and do variable existence and type checking
return parse
