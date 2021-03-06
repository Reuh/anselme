local identifier_pattern, format_identifier, find, escape, find_function_variant, parse_text, string_escapes

--- binop priority
local binops_prio = {
	[1] = { ";" },
	[2] = { ":=", "+=", "-=", "//=", "/=", "*=", "%=", "^=" },
	[3] = { "," },
	[4] = { "|", "&" },
	[5] = { "!=", "==", ">=", "<=", "<", ">" },
	[6] = { "+", "-" },
	[7] = { "*", "//", "/", "%" },
	[8] = { "::", ":" },
	[9] = {}, -- unary operators
	[10] = { "^" },
	[11] = { "." }
}
-- unop priority
local unops_prio = {
	[1] = {},
	[2] = {},
	[3] = {},
	[4] = {},
	[5] = {},
	[6] = {},
	[7] = {},
	[8] = {},
	[9] = { "-", "!" },
	[10] = {},
	[11] = {},
}

--- parse an expression
-- return expr, remaining if success
-- returns nil, err if error
local function expression(s, state, namespace, currentPriority, operatingOn)
	s = s:match("^%s*(.*)$")
	currentPriority = currentPriority or 0
	if not operatingOn then
		-- number
		if s:match("^%d*%.%d+") or s:match("^%d+") then
			local d, r = s:match("^(%d*%.%d+)(.*)$")
			if not d then
				d, r = s:match("^(%d+)(.*)$")
			end
			return expression(r, state, namespace, currentPriority, {
				type = "number",
				value = tonumber(d)
			})
		-- string
		elseif s:match("^%\"") then
			local d, r
			-- find end of string
			local i = 2
			while true do
				local skip
				skip = s:match("^[^%\\\"]-%b{}()", i) -- skip interpolated expressions
				if skip then i = skip end
				skip = s:match("^[^%\\\"]-\\.()", i) -- skip escape codes (need to skip every escape code in order to correctly parse \\": the " is not escaped)
				if skip then i = skip end
				if not skip then -- nothing skipped
					local end_pos = s:match("^[^%\"]-\"()", i) -- search final double quote
					if end_pos then
						d, r = s:sub(2, end_pos-2), s:sub(end_pos)
						break
					else
						return nil, ("expected \" to finish string near %q"):format(s:sub(i))
					end
				end
			end
			-- parse interpolated expressions
			local l, e = parse_text(d, state, namespace)
			if not l then return l, e end
			-- escape the string parts
			for j, ls in ipairs(l) do
				if type(ls) == "string" then
					l[j] = ls:gsub("\\.", string_escapes)
				end
			end
			return expression(r, state, namespace, currentPriority, {
				type = "string",
				value = l
			})
		-- paranthesis
		elseif s:match("^%b()") then
			local content, r = s:match("^(%b())(.*)$")
			content = content:gsub("^%(", ""):gsub("%)$", "")
			local exp
			if content:match("[^%s]") then
				local r_paren
				exp, r_paren = expression(content, state, namespace)
				if not exp then return nil, "invalid expression inside parentheses: "..r_paren end
				if r_paren:match("[^%s]") then return nil, ("unexpected %q at end of parenthesis expression"):format(r_paren) end
			else
				exp = { type = "nil", value = nil }
			end
			return expression(r, state, namespace, currentPriority, {
				type = "parentheses",
				expression = exp
			})
		-- list parenthesis
		elseif s:match("^%b[]") then
			local content, r = s:match("^(%b[])(.*)$")
			content = content:gsub("^%[", ""):gsub("%]$", "")
			local exp
			if content:match("[^%s]") then
				local r_paren
				exp, r_paren = expression(content, state, namespace)
				if not exp then return nil, "invalid expression inside list parentheses: "..r_paren end
				if r_paren:match("[^%s]") then return nil, ("unexpected %q at end of list parenthesis expression"):format(r_paren) end
			end
			return expression(r, state, namespace, currentPriority, {
				type = "list_brackets",
				expression = exp
			})
		-- identifier
		elseif s:match("^"..identifier_pattern) then
			local name, r = s:match("^("..identifier_pattern..")(.-)$")
			name = format_identifier(name)
			-- string:value pair shorthand using =
			if r:match("^=[^=]") then
				local val
				val, r = expression(r:match("^=(.*)$"), state, namespace, 9)
				if not val then return val, r end
				local args = {
					type = "list",
					left = {
						type = "string",
						value = { name }
					},
					right = val
				}
				-- find compatible variant
				local variant, err = find_function_variant(state, namespace, ":", args, true)
				if not variant then return variant, err end
				return expression(r, state, namespace, currentPriority, variant)
			end
			-- variables
			local var, vfqm = find(state.aliases, state.variables, namespace, name)
			if var then
				return expression(r, state, namespace, currentPriority, {
					type = "variable",
					name = vfqm
				})
			end
			-- suffix call: detect if prefix is valid variable, suffix call is handled in the binop section below
			local sname, suffix = name:match("^(.*)(%."..identifier_pattern..")$")
			if sname then
				local svar, svfqm = find(state.aliases, state.variables, namespace, sname)
				if svar then
					return expression(suffix..r, state, namespace, currentPriority, {
						type = "variable",
						name = svfqm
					})
				end
			end
			-- function call
			local args, explicit_call
			if r:match("^%b()") then
				explicit_call = true
				local content, rem = r:match("^(%b())(.*)$")
				content = content:gsub("^%(", ""):gsub("%)$", "")
				r = rem
				-- get arguments
				if content:match("[^%s]") then
					local err
					args, err = expression(content, state, namespace)
					if not args then return args, err end
					if err:match("[^%s]") then return nil, ("unexpected %q at end of argument list"):format(err) end
				end
			end
			-- find compatible variant
			local variant, err = find_function_variant(state, namespace, name, args, explicit_call)
			if not variant then return variant, err end
			return expression(r, state, namespace, currentPriority, variant)
		end
		-- unops
		for prio, oplist in ipairs(unops_prio) do
			for _, op in ipairs(oplist) do
				local escaped = escape(op)
				if s:match("^"..escaped) then
					local right, r = expression(s:match("^"..escaped.."(.*)$"), state, namespace, prio)
					if not right then return nil, ("invalid expression after unop %q: %s"):format(op, r) end
					-- find variant
					local variant, err = find_function_variant(state, namespace, op, right, true)
					if not variant then return variant, err end
					return expression(r, state, namespace, currentPriority, variant)
				end
			end
		end
		return nil, ("no valid expression before %q"):format(s)
	else
		-- binop
		for prio, oplist in ipairs(binops_prio) do
			if prio >= currentPriority then
				for _, op in ipairs(oplist) do
					local escaped = escape(op)
					if s:match("^"..escaped) then
						local sright = s:match("^"..escaped.."(.*)$")
						-- suffix call
						if op == "." and sright:match("^"..identifier_pattern) then
							local name, r = sright:match("^("..identifier_pattern..")(.-)$")
							name = format_identifier(name)
							local args, explicit_call
							if r:match("^%b()") then
								explicit_call = true
								local content, rem = r:match("^(%b())(.*)$")
								content = content:gsub("^%(", ""):gsub("%)$", "")
								r = rem
								-- get arguments
								if content:match("[^%s]") then
									local err
									args, err = expression(content, state, namespace)
									if not args then return args, err end
									if err:match("[^%s]") then return nil, ("unexpected %q at end of argument list"):format(err) end
								end
							end
							-- add first argument
							if not args then
								args = operatingOn
							else
								args = {
									type = "list",
									left = operatingOn,
									right = args
								}
							end
							-- find compatible variant
							local variant, err = find_function_variant(state, namespace, name, args, explicit_call)
							if not variant then return variant, err end
							return expression(r, state, namespace, currentPriority, variant)
						-- other binops
						else
							local right, r = expression(sright, state, namespace, prio)
							if not right then return nil, ("invalid expression after binop %q: %s"):format(op, r) end
							-- list constructor
							if op == "," then
								return expression(r, state, namespace, currentPriority, {
									type = "list",
									left = operatingOn,
									right = right
								})
							-- special binops
							elseif op == ":=" or op == "+=" or op == "-=" or op == "//=" or op == "/=" or op == "*=" or op == "%=" or op == "^=" then
								-- rewrite assignment + arithmetic operators into a normal assignment
								if op ~= ":=" then
									local args = {
										type = "list",
										left = operatingOn,
										right = right
									}
									local variant, err = find_function_variant(state, namespace, op:match("^(.*)%=$"), args, true)
									if not variant then return variant, err end
									right = variant
								end
								-- assign to a function
								if operatingOn.type == "function" then
									-- remove non-assignment functions
									for i=#operatingOn.variants, 1, -1 do
										if not operatingOn.variants[i].assignment then
											table.remove(operatingOn.variants, i)
										end
									end
									if #operatingOn.variants == 0 then
										return nil, ("trying to perform assignment on function %s with no compatible assignment variant"):format(operatingOn.called_name)
									end
									-- rewrite function to perform assignment
									operatingOn.assignment = right
									return expression(r, state, namespace, currentPriority, operatingOn)
								elseif operatingOn.type ~= "variable" then
									return nil, ("trying to perform assignment on a %s expression"):format(operatingOn.type)
								end
								-- assign to a variable
								return expression(r, state, namespace, currentPriority, {
									type = ":=",
									left = operatingOn,
									right = right
								})
							elseif op == "&" or op == "|" then
								return expression(r, state, namespace, currentPriority, {
									type = op,
									left = operatingOn,
									right = right
								})
							-- normal binop
							else
								-- find variant
								local args = {
									type = "list",
									left = operatingOn,
									-- wrap in parentheses to avoid appending to argument list if right is a list
									right = { type = "parentheses", expression = right }
								}
								local variant, err = find_function_variant(state, namespace, op, args, true)
								if not variant then return variant, err end
								return expression(r, state, namespace, currentPriority, variant)
							end
						end
					end
				end
			end
		end
		-- index
		if s:match("^%b()") then
			local content, r = s:match("^(%b())(.*)$")
			-- get arguments (parentheses are kept)
			local right, r_paren = expression(content, state, namespace)
			if not right then return right, r_paren end
			if r_paren:match("[^%s]") then return nil, ("unexpected %q at end of index expression"):format(r_paren) end
			local args = { type = "list", left = operatingOn, right = right }
			local variant, err = find_function_variant(state, namespace, "()", args, true)
			if not variant then return variant, err end
			return expression(r, state, namespace, currentPriority, variant)
		end
		-- nothing to operate
		return operatingOn, s
	end
end

package.loaded[...] = expression
local common = require((...):gsub("expression$", "common"))
identifier_pattern, format_identifier, find, escape, find_function_variant, parse_text, string_escapes = common.identifier_pattern, common.format_identifier, common.find, common.escape, common.find_function_variant, common.parse_text, common.string_escapes

return expression
