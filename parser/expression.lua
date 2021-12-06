local identifier_pattern, format_identifier, find, escape, find_function, parse_text, find_all, split

--- binop priority
local binops_prio = {
	[1] = { ";" },
	[2] = { ":=", "+=", "-=", "//=", "/=", "*=", "%=", "^=" },
	[3] = { "," },
	[4] = { "|", "&", "~", "#" },
	[5] = { "!=", "==", ">=", "<=", "<", ">" },
	[6] = { "+", "-" },
	[7] = { "*", "//", "/", "%" },
	[8] = { "::", ":" },
	[9] = {}, -- unary operators
	[10] = { "^" },
	[11] = { ".", "!" },
	[12] = {}
}
-- unop priority
local prefix_unops_prio = {
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
	[12] = { "&" }
}
local suffix_unops_prio = {
	[1] = {},
	[2] = {},
	[3] = {},
	[4] = {},
	[5] = {},
	[6] = {},
	[7] = {},
	[8] = {},
	[9] = {},
	[10] = {},
	[11] = { "!" },
	[12] = {}
}

local function get_text_in_litteral(s, start_pos)
	local d, r
	-- find end of string
	start_pos = start_pos or 2
	local i = start_pos
	while true do
		local skip
		skip = s:match("^[^%\\\"]-%b{}()", i) -- skip interpolated expressions
		if skip then i = skip end
		skip = s:match("^[^%\\\"]-\\.()", i) -- skip escape codes (need to skip every escape code in order to correctly parse \\": the " is not escaped)
		if skip then i = skip end
		if not skip then -- nothing skipped
			local end_pos = s:match("^[^%\"]-\"()", i) -- search final double quote
			if end_pos then
				d, r = s:sub(start_pos, end_pos-2), s:sub(end_pos)
				break
			else
				return nil, ("expected \" to finish string near %q"):format(s:sub(i))
			end
		end
	end
	return d, r
end

--- parse an expression
-- return expr, remaining if success
-- returns nil, err if error
local function expression(s, state, namespace, current_priority, operating_on)
	s = s:match("^%s*(.*)$")
	current_priority = current_priority or 0
	if not operating_on then
		-- number
		if s:match("^%d*%.%d+") or s:match("^%d+") then
			local d, r = s:match("^(%d*%.%d+)(.*)$")
			if not d then
				d, r = s:match("^(%d+)(.*)$")
			end
			return expression(r, state, namespace, current_priority, {
				type = "number",
				value = tonumber(d)
			})
		-- string
		elseif s:match("^%\"") then
			local d, r = get_text_in_litteral(s)
			local l, e = parse_text(d, state, namespace, "string") -- parse interpolated expressions
			if not l then return l, e end
			return expression(r, state, namespace, current_priority, l)
		-- text
		elseif s:match("^t%\"") then
			local d, r = get_text_in_litteral(s, 3)
			local l, e = parse_text(d, state, namespace, "text", nil, true) -- parse interpolated expressions and subtext
			if not l then return l, e end
			return expression(r, state, namespace, current_priority, l)
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
			return expression(r, state, namespace, current_priority, {
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
			return expression(r, state, namespace, current_priority, {
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
						text = { name }
					},
					right = val
				}
				-- find compatible variant
				local variant, err = find_function(state, namespace, "_:_", args, true)
				if not variant then return variant, err end
				return expression(r, state, namespace, current_priority, variant)
			end
			-- variables
			-- if name isn't a valid variable, suffix call: detect if a prefix is valid variable, suffix _._ call is handled in the binop section below
			local nl = split(name)
			for i=#nl, 1, -1 do
				local name_prefix = table.concat(nl, ".", 1, i)
				local var, vfqm = find(state.aliases, state.variables, namespace, name_prefix)
				if var then
					if i < #nl then
						r = "."..table.concat(nl, ".", i+1, #nl)..r
					end
					return expression(r, state, namespace, current_priority, {
						type = "variable",
						name = vfqm
					})
				end
			end
			-- function call
			local args, paren_call, implicit_call
			if r:match("^%b()") then
				paren_call = true
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
			else -- implicit call; will be changed if there happens to be a ! after in the suffix operator code
				implicit_call = true
			end
			-- find compatible variant
			local variant, err = find_function(state, namespace, name, args, paren_call, implicit_call)
			if not variant then return variant, err end
			return expression(r, state, namespace, current_priority, variant)
		end
		-- prefix unops
		for prio, oplist in ipairs(prefix_unops_prio) do
			for _, op in ipairs(oplist) do
				local escaped = escape(op)
				if s:match("^"..escaped) then
					local sright = s:match("^"..escaped.."(.*)$")
					-- function reference
					if op == "&" and sright:match("^"..identifier_pattern) then
						local name, r = sright:match("^("..identifier_pattern..")(.-)$")
						name = format_identifier(name)
						-- get all functions this name can reference
						-- try prefixes until we find a valid function name
						local nl = split(name)
						for i=#nl, 1, -1 do
							local name_prefix = table.concat(nl, ".", 1, i)
							local lfnqm = find_all(state.aliases, state.functions, namespace, name_prefix)
							if #lfnqm > 0 then
								if i < #nl then
									r = "."..table.concat(nl, ".", i+1, #nl)..r
								end
								return expression(r, state, namespace, current_priority, {
									type = "function reference",
									names = lfnqm
								})
							end
						end
						return nil, ("can't find function %q to reference"):format(name)
					-- normal prefix unop
					else
						local right, r = expression(sright, state, namespace, prio)
						if not right then return nil, ("invalid expression after unop %q: %s"):format(op, r) end
						-- find variant
						local variant, err = find_function(state, namespace, op.."_", right, true)
						if not variant then return variant, err end
						return expression(r, state, namespace, current_priority, variant)
					end
				end
			end
		end
		return nil, ("no valid expression before %q"):format(s)
	else
		-- binop
		for prio, oplist in ipairs(binops_prio) do
			if prio > current_priority then
				for _, op in ipairs(oplist) do
					local escaped = escape(op)
					if s:match("^"..escaped) then
						local sright = s:match("^"..escaped.."(.*)$")
						-- suffix call
						if op == "!" and sright:match("^"..identifier_pattern) then
							local name, r = sright:match("^("..identifier_pattern..")(.-)$")
							name = format_identifier(name)
							local args, paren_call
							if r:match("^%b()") then
								paren_call = true
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
								args = operating_on
							else
								args = {
									type = "list",
									left = operating_on,
									right = args
								}
							end
							-- find compatible variant
							local variant, err = find_function(state, namespace, name, args, paren_call)
							if not variant then return variant, err end
							return expression(r, state, namespace, current_priority, variant)
						-- namespace
						elseif op == "." and sright:match("^"..identifier_pattern) then
							local name, r = sright:match("^("..identifier_pattern..")(.-)$")
							name = format_identifier(name)
							-- find variant
							local args = {
								type = "list",
								left = operating_on,
								right = { type = "string", text = { name } }
							}
							local variant, err = find_function(state, namespace, "_._", args, true)
							if not variant then return variant, err end
							return expression(r, state, namespace, current_priority, variant)
						-- other binops
						else
							local right, r = expression(sright, state, namespace, prio)
							if right then
								-- list constructor (can't do this through a function call since we need to build a list for its arguments)
								if op == "," then
									return expression(r, state, namespace, current_priority, {
										type = "list",
										left = operating_on,
										right = right
									})
								-- special binops
								elseif op == ":=" or op == "+=" or op == "-=" or op == "//=" or op == "/=" or op == "*=" or op == "%=" or op == "^=" then
									-- rewrite assignment + arithmetic operators into a normal assignment
									if op ~= ":=" then
										local args = {
											type = "list",
											left = operating_on,
											right = right
										}
										local variant, err = find_function(state, namespace, "_"..op:match("^(.*)%=$").."_", args, true)
										if not variant then return variant, err end
										right = variant
									end
									-- assign to a function
									if operating_on.type == "function call" then
										-- remove non-assignment functions
										for i=#operating_on.variants, 1, -1 do
											if not operating_on.variants[i].assignment then
												table.remove(operating_on.variants, i)
											end
										end
										if #operating_on.variants == 0 then
											return nil, ("trying to perform assignment on function %s with no compatible assignment variant"):format(operating_on.called_name)
										end
										-- rewrite function to perform assignment
										operating_on.assignment = right
										return expression(r, state, namespace, current_priority, operating_on)
									elseif operating_on.type ~= "variable" then
										return nil, ("trying to perform assignment on a %s expression"):format(operating_on.type)
									end
									-- assign to a variable
									return expression(r, state, namespace, current_priority, {
										type = ":=",
										left = operating_on,
										right = right
									})
								elseif op == "&" or op == "|" or op == "~" or op == "#" then
									return expression(r, state, namespace, current_priority, {
										type = op,
										left = operating_on,
										right = right
									})
								-- normal binop
								else
									-- find variant
									local args = {
										type = "list",
										left = operating_on,
										right = right
									}
									local variant, err = find_function(state, namespace, "_"..op.."_", args, true)
									if not variant then return variant, err end
									return expression(r, state, namespace, current_priority, variant)
								end
							end
						end
					end
				end
			end
		end
		-- suffix unop
		for prio, oplist in ipairs(suffix_unops_prio) do
			if prio > current_priority then
				for _, op in ipairs(oplist) do
					local escaped = escape(op)
					if s:match("^"..escaped) then
						local r = s:match("^"..escaped.."(.*)$")
						-- remove ! after a previously-assumed implicit function call
						if op == "!" and operating_on.type == "function call" and operating_on.implicit_call then
							operating_on.implicit_call = false
							return expression(r, state, namespace, current_priority, operating_on)
						-- normal suffix unop
						else
							local variant, err = find_function(state, namespace, "_"..op, operating_on, true)
							if not variant then return variant, err end
							return expression(r, state, namespace, current_priority, variant)
						end
					end
				end
			end
		end
		-- index / call
		if s:match("^%b()") then
			local args = operating_on
			local content, r = s:match("^(%b())(.*)$")
			content = content:gsub("^%(", ""):gsub("%)$", "")
			-- get arguments
			if content:match("[^%s]") then
				local right, r_paren = expression(content, state, namespace)
				if not right then return right, r_paren end
				if r_paren:match("[^%s]") then return nil, ("unexpected %q at end of index/call expression"):format(r_paren) end
				args = { type = "list", left = args, right = right }
			end
			local variant, err = find_function(state, namespace, "()", args, true)
			if not variant then return variant, err end
			return expression(r, state, namespace, current_priority, variant)
		end
		-- nothing to operate
		return operating_on, s
	end
end

package.loaded[...] = expression
local common = require((...):gsub("expression$", "common"))
identifier_pattern, format_identifier, find, escape, find_function, parse_text, find_all, split = common.identifier_pattern, common.format_identifier, common.find, common.escape, common.find_function, common.parse_text, common.find_all, common.split

return expression
