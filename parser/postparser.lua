local expression
local parse_text

-- * true: if success
-- * nil, error: in case of error
local function parse(state)
	for _, l in ipairs(state.queued_lines) do
		local line, namespace = l.line, l.namespace
		-- default arguments
		if line.type == "function" then
			for i, param in ipairs(line.params) do
				if param.default then
					local exp, rem = expression(param.default, state, namespace)
					if not exp then return nil, ("%s; at %s"):format(rem, line.source) end
					if rem:match("[^%s]") then return nil, ("expected end of expression before %q; at %s"):format(rem, line.source) end
					param.default = exp
					-- complete type information
					if exp.return_type then
						line.variant.types[i] = exp.return_type
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
			-- function return type information
			if line.type == "return" then
				local variant = line.parent_function.variant
				local return_type = line.expression.return_type
				if return_type then
					if not variant.return_type then
						variant.return_type = return_type
					elseif variant.return_type ~= return_type then
						return nil, ("trying to return a %s in a function that returns a %s; at %s"):format(return_type, variant.return_type, line.source)
					end
				end
			end
		end
		-- text
		if line.text then
			local txt, err = parse_text(line.text, state, namespace)
			if err then return nil, ("%s; at %s"):format(err, line.source) end
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
