local identifier_pattern, format_identifier, find, escape, find_function, parse_text, find_all, split, find_function_from_list

--- binop priority
local binops_prio = {
	[1] = { ";" },
	[2] = { ":=", "+=", "-=", "//=", "/=", "*=", "%=", "^=" },
	[3] = { "," },
	[4] = { "~?", "~", "#" },
	[5] = { "=", ":" },
	[6] = { "|", "&" },
	[7] = { "!=", "==", ">=", "<=", "<", ">" },
	[8] = { "+", "-" },
	[9] = { "*", "//", "/", "%" },
	[10] = { "::" },
	[11] = {}, -- unary operators
	[12] = { "^" },
	[13] = { "!" },
	[14] = {},
	[15] = { "." }
}
local call_priority = 13 -- note: higher priority operators will have to deal with potential functions expressions
local implicit_call_priority = 12.5 -- just below call priority so explicit calls automatically take precedence
local pair_priority = 5
local implicit_multiply_priority = 9.5 -- just above / so 1/2x gives 1/(2x)
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
	[9] = {},
	[10] = {},
	[11] = { "-", "!" },
	[12] = {},
	[13] = {},
	[14] = { "&" },
	[15] = {}
}
local suffix_unops_prio = {
	[1] = { ";" },
	[2] = {},
	[3] = {},
	[4] = {},
	[5] = {},
	[6] = {},
	[7] = {},
	[8] = {},
	[9] = {},
	[10] = {},
	[11] = {},
	[12] = {},
	[13] = { "!" },
	[14] = {},
	[15] = {}
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
		-- map parenthesis
		elseif s:match("^%b{}") then
			local content, r = s:match("^(%b{})(.*)$")
			content = content:gsub("^%{", ""):gsub("%}$", "")
			local exp
			if content:match("[^%s]") then
				local r_paren
				exp, r_paren = expression(content, state, namespace)
				if not exp then return nil, "invalid expression inside map parentheses: "..r_paren end
				if r_paren:match("[^%s]") then return nil, ("unexpected %q at end of map parenthesis expression"):format(r_paren) end
			end
			return expression(r, state, namespace, current_priority, {
				type = "map_brackets",
				expression = exp
			})
		-- identifier
		elseif s:match("^"..identifier_pattern) then
			local name, r = s:match("^("..identifier_pattern..")(.-)$")
			name = format_identifier(name)
			-- string:value pair shorthand using =
			if r:match("^=[^=]") and pair_priority > current_priority then
				local val
				val, r = expression(r:match("^=(.*)$"), state, namespace, pair_priority)
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
				local variant, err = find_function(state, namespace, "_=_", args, true)
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
			-- functions. This is a temporary expression that will either be transformed into a reference by the &_ operator, or an (implicit) function call otherwise.
			for i=#nl, 1, -1 do
				local name_prefix = table.concat(nl, ".", 1, i)
				local lfnqm = find_all(state.aliases, state.functions, namespace, name_prefix)
				if #lfnqm > 0 then
					if i < #nl then
						r = "."..table.concat(nl, ".", i+1, #nl)..r
					end
					return expression(r, state, namespace, current_priority, {
						type = "potential function",
						called_name = name,
						names = lfnqm
					})
				end
			end
			return nil, ("can't find function or variable named %q"):format(name)
		end
		-- prefix unops
		for prio, oplist in ipairs(prefix_unops_prio) do
			for _, op in ipairs(oplist) do
				local escaped = escape(op)
				if s:match("^"..escaped) then
					local sright = s:match("^"..escaped.."(.*)$")
					-- function and variable reference
					if op == "&" then
						local right, r = expression(sright, state, namespace, prio)
						if not right then return nil, ("invalid expression after unop %q: %s"):format(op, r) end
						if right.type == "potential function" then
							return expression(r, state, namespace, current_priority, {
								type = "function reference",
								names = right.names
							})
						elseif right.type == "variable" then
							return expression(r, state, namespace, current_priority, {
								type = "variable reference",
								name = right.name,
								expression = right
							})
						else
							-- find variant
							local variant, err = find_function(state, namespace, op.."_", right, true)
							if not variant then return variant, err end
							return expression(r, state, namespace, current_priority, variant)
						end
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
		-- transform potential function/variable calls into actual calls automatically
		-- need to do this before every other operator, since once the code finds the next operator it won't go back to check if this applied and assume it
		-- didn't skip anything since it didn't see any other operator before, even if it's actually higher priority...
		-- the problems of an implicit operator I guess
		if implicit_call_priority > current_priority then
			-- implicit call of a function. Unlike for variables, can't be cancelled since there's not any other value this could return, we don't
			-- have first class functions here...
			if operating_on.type == "potential function" then
				local args, paren_call, implicit_call
				local r = s
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
				local variant, err = find_function_from_list(state, namespace, operating_on.called_name, operating_on.names, args, paren_call, implicit_call)
				if not variant then return variant, err end
				return expression(r, state, namespace, current_priority, variant)
			-- implicit call on variable reference. Might be canceled afterwards due to finding a higher priority operator.
			elseif operating_on.type == "variable" or (operating_on.type == "function call" and operating_on.called_name == "_._") then
				local implicit_call_variant, err = find_function(state, namespace, "_!", { type = "value passthrough" }, false, true)
				if not implicit_call_variant then return implicit_call_variant, err end
				return expression(s, state, namespace, current_priority, {
					type = "implicit call if reference",
					variant = implicit_call_variant,
					expression = operating_on
				})
			end
		end
		-- binop
		for prio, oplist in ipairs(binops_prio) do
			if prio > current_priority then
				-- cancel implicit call operator if we are handling a binop of higher priority
				-- see comment a bit above on why the priority handling is stupid for implicit operators
				local operating_on = operating_on
				if prio > implicit_call_priority and operating_on.type == "implicit call if reference" then
					operating_on = operating_on.expression
				end
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
									if err:match("[^%s]") then return nil, ("unexpected %q at end of argument map"):format(err) end
								end
							end
							-- add first argument
							if not args then
								args = operating_on
							else
								if args.type == "list" then -- insert as first element
									local first_list = args
									while first_list.left.type == "list" do
										first_list = first_list.left
									end
									first_list.left = {
										type = "list",
										left = operating_on,
										right = first_list.left
									}
								else
									args = {
										type = "list",
										left = operating_on,
										right = args
									}
								end
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
									-- cancel implicit call on right variable
									if operating_on.type == "implicit call if reference" then
										operating_on = operating_on.expression
									end
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
								elseif op == "&" or op == "|" or op == "~?" or op == "~" or op == "#" then
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
				-- cancel implit call operator if we are handling an operator of higher priority
				-- see comment a bit above on why the priority handling is stupid for implicit operators
				local operating_on = operating_on
				if prio > implicit_call_priority and operating_on.type == "implicit call if reference" then
					operating_on = operating_on.expression
				end
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
		if call_priority > current_priority and s:match("^%b()") then
			if operating_on.type == "implicit call if reference" then
				operating_on = operating_on.expression -- replaced with current call
			end
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
		-- implicit multiplication
		if implicit_multiply_priority > current_priority then
			if s:match("^"..identifier_pattern) then
				local right, r = expression(s, state, namespace, implicit_multiply_priority)
				if right then
					local args = {
						type = "list",
						left = operating_on,
						right = right
					}
					local variant, err = find_function(state, namespace, "_*_", args, true)
					if not variant then return variant, err end
					return expression(r, state, namespace, current_priority, variant)
				end
			end
		end
		-- nothing to operate
		return operating_on, s
	end
end

package.loaded[...] = expression
local common = require((...):gsub("expression$", "common"))
identifier_pattern, format_identifier, find, escape, find_function, parse_text, find_all, split, find_function_from_list = common.identifier_pattern, common.format_identifier, common.find, common.escape, common.find_function, common.parse_text, common.find_all, common.split, common.find_function_from_list

return expression
