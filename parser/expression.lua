local identifier_pattern, format_identifier, find, escape, find_function_variant, parse_text

--- binop priority
local binops_prio = {
	[1] = { ";" },
	[2] = { ":=", "+=", "-=", "//=", "/=", "*=", "%=", "^=" },
	[3] = { "," },
	[4] = { "|", "&" },
	[5] = { "!=", "=", ">=", "<=", "<", ">" },
	[6] = { "+", "-" },
	[7] = { "*", "//", "/", "%" },
	[8] = {}, -- unary operators
	[9] = { "^", ":" },
	[10] = { "." }
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
	[8] = { "-", "!" },
	[9] = {}
}

--- parse an expression
-- return expr, remaining if success
-- returns nil, err if error
local function expression(s, state, namespace, currentPriority, operatingOn)
	s = s:match("^%s*(.*)$")
	currentPriority = currentPriority or 0
	if not operatingOn then
		-- number
		if s:match("^%d+%.%d*") or s:match("^%d*%.%d+") or s:match("^%d+") then
			local d, r = s:match("^(%d*%.%d*)(.*)$")
			if not d then
				d, r = s:match("^(%d+)(.*)$")
			end
			return expression(r, state, namespace, currentPriority, {
				type = "number",
				return_type = "number",
				value = tonumber(d)
			})
		-- string
		elseif s:match("^%\"[^\"]*%\"") then
			local d, r = s:match("^%\"([^\"]*)%\"(.*)$")
			while d:match("\\$") and not d:match("\\\\$") do
				local nd, nr = r:match("([^\"]*)%\"(.*)$")
				if not nd then return nil, ("unfinished string near %q"):format(r) end
				d, r = d:sub(1, -2) .. "\"" .. nd, nr
			end
			local l, e = parse_text(tostring(d), state, namespace)
			if not l then return l, e end
			return expression(r, state, namespace, currentPriority, {
				type = "string",
				return_type = "string",
				value = l
			})
		-- paranthesis
		elseif s:match("^%b()") then
			local content, r = s:match("^(%b())(.*)$")
			content = content:gsub("^%(", ""):gsub("%)$", "")
			local exp, r_paren = expression(content, state, namespace)
			if not exp then return nil, "invalid expression inside parentheses: "..r_paren end
			if r_paren:match("[^%s]") then return nil, ("unexpected %q at end of parenthesis expression"):format(r_paren) end
			return expression(r, state, namespace, currentPriority, {
				type = "parentheses",
				return_type = exp.return_type,
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
				type = "list_parentheses",
				return_type = "list",
				expression = exp
			})
		-- identifier
		elseif s:match("^"..identifier_pattern) then
			local name, r = s:match("^("..identifier_pattern..")(.-)$")
			name = format_identifier(name, state)
			-- variables
			local var, vfqm = find(state.variables, namespace, name)
			if var then
				return expression(r, state, namespace, currentPriority, {
					type = "variable",
					return_type = var.type ~= "undefined argument" and var.type or nil,
					name = vfqm
				})
			end
			-- suffix call: detect if prefix is valid variable, suffix call is handled in the binop section below
			local sname, suffix = name:match("^(.*)(%."..identifier_pattern..")$")
			if sname then
				local svar, svfqm = find(state.variables, namespace, sname)
				if svar then
					return expression(suffix..r, state, namespace, currentPriority, {
						type = "variable",
						return_type = svar.type ~= "undefined argument" and svar.type or nil,
						name = svfqm
					})
				end
			end
			-- functions
			local funcs, ffqm = find(state.functions, namespace, name)
			if funcs then
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
					end
				end
				-- find compatible variant
				local variant, err = find_function_variant(ffqm, state, args, explicit_call)
				if not variant then return variant, err end
				return expression(r, state, namespace, currentPriority, variant)
			end
			return nil, ("unknown identifier %q"):format(name)
		end
		-- unops
		for prio, oplist in ipairs(unops_prio) do
			for _, op in ipairs(oplist) do
				local escaped = escape(op)
				if s:match("^"..escaped) then
					local right, r = expression(s:match("^"..escaped.."(.*)$"), state, namespace, prio)
					if not right then return nil, ("invalid expression after unop %q: %s"):format(op, r) end
					-- find variant
					local variant, err = find_function_variant(op, state, right, true)
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
							name = format_identifier(name, state)
							local funcs, ffqm = find(state.functions, namespace, name)
							if funcs then
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
									end
								end
								-- add first argument
								if not args then
									args = operatingOn
								else
									args = {
										type = "list",
										return_type = "list",
										left = operatingOn,
										right = args
									}
								end
								-- find compatible variant
								local variant, err = find_function_variant(ffqm, state, args, explicit_call)
								if not variant then return variant, err end
								return expression(r, state, namespace, currentPriority, variant)
							end
						else
							local right, r = expression(sright, state, namespace, prio)
							if not right then return nil, ("invalid expression after binop %q: %s"):format(op, r) end
							-- list constructor
							if op == "," then
								return expression(r, state, namespace, currentPriority, {
									type = "list",
									return_type = "list",
									left = operatingOn,
									right = right
								})
							-- normal binop
							else
								-- find variant
								local args = {
									type = "list",
									return_type = "list",
									left = operatingOn,
									-- wrap in parentheses to avoid appending to argument list if right is a list
									right = { type = "parentheses", return_type = right.return_type, expression = right }
								}
								local variant, err = find_function_variant(op, state, args, true)
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
			local variant, err = find_function_variant("(", state, args, true)
			if not variant then return variant, err end
			return expression(r, state, namespace, currentPriority, variant)
		end
		-- nothing to operate
		return operatingOn, s
	end
end

package.loaded[...] = expression
local common = require((...):gsub("expression$", "common"))
identifier_pattern, format_identifier, find, escape, find_function_variant, parse_text = common.identifier_pattern, common.format_identifier, common.find, common.escape, common.find_function_variant, common.parse_text

return expression
