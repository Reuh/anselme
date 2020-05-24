local expression
local parse_text

-- * true: if success
-- * nil, error: in case of error
local function parse(state)
	for _, l in ipairs(state.queued_lines) do
		local line, namespace = l.line, l.namespace
		-- decorators
		if line.condition then
			if line.condition:match("[^%s]") then
				local exp, rem = expression(line.condition, state, namespace)
				if not exp then return nil, ("%s; at line %s"):format(rem, line.line) end
				if rem:match("[^%s]") then return nil, ("expected end of expression before %q in condition decorator; at line %s"):format(rem, line.line) end
				line.condition = exp
			else
				line.condition = nil
			end
		end
		if line.tag then
			if line.tag:match("[^%s]") then
				local exp, rem = expression(line.tag, state, namespace)
				if not exp then return nil, ("%s; at line %s"):format(rem, line.line) end
				if rem:match("[^%s]") then return nil, ("expected end of expression before %q in condition decorator; at line %s"):format(rem, line.line) end
				line.tag = exp
			else
				line.tag = nil
			end
		end
		-- expressions
		if line.expression then
			if line.expression:match("[^%s]") then
				local exp, rem = expression(line.expression, state, namespace)
				if not exp then return nil, ("%s; at line %s"):format(rem, line.line) end
				if rem:match("[^%s]") then return nil, ("expected end of expression before %q; at line %s"):format(rem, line.line) end
				line.expression = exp
			else
				line.expression = nil
			end
			-- function return type information
			if line.type == "return" then
				local variant = line.parent_function.variant
				local return_type = line.expression.return_type
				if return_type then
					if not variant.return_type then
						variant.return_type = return_type
					elseif variant.return_type ~= return_type then
						return nil, ("trying to return a %s in a function that returns a %s; at line %s"):format(return_type, variant.return_type, line.line)
					end
				end
			end
		end
		-- text
		if line.text then
			local txt, err = parse_text(line.text, state, namespace)
			if err then return nil, ("%s; at line %s"):format(err, line.line) end
			line.text = txt
		end
	end
	state.queued_lines = {}
	return true
end

package.loaded[...] = parse
expression = require((...):gsub("postparser$", "expression"))
local common = require((...):gsub("postparser$", "common"))
parse_text = common.parse_text

--- postparse shit: parse expressions and do variable existence and type checking
return parse
