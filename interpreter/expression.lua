local expression
local to_lua, from_lua, eval_text, truthy, format, pretty_type, get_variable, tags, eval_text_callback, events, flatten_list, set_variable, scope, check_constraint, hash

local run

local unpack = table.unpack or unpack

--- evaluate an expression
-- returns evaluated value (table) if success
-- returns nil, error if error
local function eval(state, exp)
	-- nil
	if exp.type == "nil" then
		return {
			type = "nil",
			value = nil
		}
	-- number
	elseif exp.type == "number" then
		return {
			type = "number",
			value = exp.value
		}
	-- string
	elseif exp.type == "string" then
		local t, e = eval_text(state, exp.text)
		if not t then return nil, e end
		return {
			type = "string",
			value = t
		}
	-- text buffer
	elseif exp.type == "text buffer" then
		-- eval text expression
		local v, e = eval(state, exp.text)
		if not v then return v, e end
		local l = v.type == "list" and v.value or { v }
		-- write resulting buffers (plural if loop in text expression) into a single result buffer
		local buffer = {}
		for _, item in ipairs(l) do
			if item.type == "event buffer" then
				for _, event in ipairs(item.value) do
					if event.type ~= "text" and event.type ~= "flush" then
						return nil, ("event %q can't be captured in a text buffer"):format(event.type)
					end
					table.insert(buffer, event)
				end
			end
		end
		return {
			type = "event buffer",
			value = buffer
		}
	-- parentheses
	elseif exp.type == "parentheses" then
		return eval(state, exp.expression)
	-- list defined in brackets
	elseif exp.type == "list brackets" then
		if exp.expression then
			local v, e = eval(state, exp.expression)
			if not v then return nil, e end
			if exp.expression.type == "list" then
				return v
			-- contained a single element, wrap in list manually
			else
				return {
					type = "list",
					value = { v }
				}
			end
		else
			return {
				type = "list",
				value = {}
			}
		end
	-- map defined in brackets
	elseif exp.type == "map brackets" then
		-- get constructing list
		local list, e = eval(state, { type = "list brackets", expression = exp.expression })
		if not list then return nil, e end
		-- make map
		local map = {}
		for i, v in ipairs(list.value) do
			local key, value
			if v.type == "pair" then
				key = v.value[1]
				value = v.value[2]
			else
				key = { type = "number", value = i }
				value = v
			end
			local h, err = hash(key)
			if not h then return nil, err end
			map[h] = { key, value }
		end
		return {
			type = "map",
			value = map
		}
	-- list defined using , operator
	elseif exp.type == "list" then
		local flat = flatten_list(exp)
		local l = {}
		for _, ast in ipairs(flat) do
			local v, e = eval(state, ast)
			if not v then return nil, e end
			table.insert(l, v)
		end
		return {
			type = "list",
			value = l
		}
	-- assignment
	elseif exp.type == ":=" then
		if exp.left.type == "variable" then
			local name = exp.left.name
			local val, vale = eval(state, exp.right)
			if not val then return nil, vale end
			local s, e = set_variable(state, name, val)
			if not s then return nil, e end
			return val
		else
			return nil, ("don't know how to perform assignment on %s expression"):format(exp.left.type)
		end
	-- lazy boolean operators
	elseif exp.type == "&" then
		local left, lefte = eval(state, exp.left)
		if not left then return nil, lefte end
		if truthy(left) then
			local right, righte = eval(state, exp.right)
			if not right then return nil, righte end
			if truthy(right) then
				return {
					type = "number",
					value = 1
				}
			end
		end
		return {
			type = "number",
			value = 0
		}
	elseif exp.type == "|" then
		local left, lefte = eval(state, exp.left)
		if not left then return nil, lefte end
		if truthy(left) then
			return {
				type = "number",
				value = 1
			}
		end
		local right, righte = eval(state, exp.right)
		if not right then return nil, righte end
		return {
			type = "number",
			value = truthy(right) and 1 or 0
		}
	-- conditional
	elseif exp.type == "~" then
		local right, righte = eval(state, exp.right)
		if not right then return nil, righte end
		if truthy(right) then
			local left, lefte = eval(state, exp.left)
			if not left then return nil, lefte end
			return left
		end
		return {
			type = "nil",
			value = nil
		}
	-- while loop
	elseif exp.type == "~?" then
		local right, righte = eval(state, exp.right)
		if not right then return nil, righte end
		local l = {}
		while truthy(right) do
			local left, lefte = eval(state, exp.left)
			if not left then return nil, lefte end
			table.insert(l, left)
			-- next iteration
			right, righte = eval(state, exp.right)
			if not right then return nil, righte end
		end
		return {
			type = "list",
			value = l
		}
	-- tag
	elseif exp.type == "#" then
		local right, righte = eval(state, { type = "map brackets", expression = exp.right })
		if not right then return nil, righte end
		tags:push(state, right)
		local left, lefte = eval(state, exp.left)
		tags:pop(state)
		if not left then return nil, lefte end
		return left
	-- variable
	elseif exp.type == "variable" then
		return get_variable(state, exp.name)
	-- references
	elseif exp.type == "function reference" then
		return {
			type = "function reference",
			value = exp.names
		}
	elseif exp.type == "variable reference" then
		-- check if variable is already a reference
		local v, e = eval(state, exp.expression)
		if not v then return nil, e end
		if v.type == "function reference" or v.type == "variable reference" then
			return v
		else
			return { type = "variable reference", value = exp.name }
		end
	elseif exp.type == "implicit call if reference" then
		local v, e = eval(state, exp.expression)
		if not v then return nil, e end
		if v.type == "function reference" or v.type == "variable reference" then
			exp.variant.argument.expression.value = v
			return eval(state, exp.variant)
		else
			return v
		end
	-- function
	elseif exp.type == "function call" then
		-- eval args: map brackets
		local args = {}
		local last_contiguous_positional = 0
		if exp.argument then
			local arg, arge = eval(state, exp.argument)
			if not arg then return nil, arge end
			-- map into args table
			for _, v in pairs(arg.value) do
				if v[1].type == "string" or v[1].type == "number" then
					args[v[1].value] = v[2]
				else
					return nil, ("unexpected key of type %s in argument map; keys must be string or number"):format(v[1].type)
				end
			end
			-- get length of contiguous positional arguments (#args may not be always be equal depending on implementation...)
			for i, _ in ipairs(args) do
				last_contiguous_positional = i
			end
		end
		-- function reference: call the referenced function
		local variants = exp.variants
		local paren_call = exp.paren_call
		if args[1] and args[1].type == "function reference" and (exp.called_name == "()" or exp.called_name == "_!") then
			-- remove func ref as first arg
			local refv = args[1].value
			table.remove(args, 1)
			-- set paren_call for _!
			if exp.called_name == "_!" then
				paren_call = false
			end
			-- get variants of the referenced function
			variants = {}
			for _, ffqm in ipairs(refv) do
				for _, variant in ipairs(state.functions[ffqm]) do
					table.insert(variants, variant)
				end
			end
		end
		-- eval assignment arg
		local assignment
		if exp.assignment then
			local arge
			assignment, arge = eval(state, exp.assignment)
			if not assignment then return nil, arge end
		end
		-- try to select a function
		local tried_function_error_messages = {}
		local selected_variant = { depths = { assignment = nil }, variant = nil, args_to_set = nil }
		for _, fn in ipairs(variants) do
			if fn.type ~= "function" then
				return nil, ("unknown function type %q"):format(fn.type)
			-- functions
			else
				if not fn.assignment or exp.assignment then
					local ok = true
					-- get and set args
					local variant_args = {}
					local used_args = {}
					local depths = { assignment = nil }
					for j, param in ipairs(fn.params) do
						local val
						-- named
						if param.alias and args[param.alias] then
							val = args[param.alias]
							used_args[param.alias] = true
						elseif args[param.name] then
							val = args[param.name]
							used_args[param.name] = true
						-- vararg
						elseif param.vararg then
							val = { type = "list", value = {} }
							for k=j, last_contiguous_positional do
								table.insert(val.value, args[k])
								used_args[k] = true
							end
						-- positional
						elseif args[j] then
							val = args[j]
							used_args[j] = true
						end
						if val then
							-- check type constraint
							local depth, err = check_constraint(state, param.full_name, val)
							if not depth then
								ok = false
								local v = state.variable_constraints[param.full_name].value
								table.insert(tried_function_error_messages, ("%s: argument %s is not of expected type %s"):format(fn.pretty_signature, param.name, format(v) or v))
								break
							end
							depths[j] = depth
							-- set
							variant_args[param.full_name] = val
						-- default: evaluate once function is selected
						-- there's no need to type check because the type constraint is already the default value's type, because of syntax
						elseif param.default then
							variant_args[param.full_name] = { type = "pending definition", value = { expression = param.default, source = fn.source } }
						else
							ok = false
							table.insert(tried_function_error_messages, ("%s: missing mandatory argument %q in function %q call"):format(fn.pretty_signature, param.name, fn.name))
							break
						end
					end
					-- check for unused arguments
					if ok then
						for key, arg in pairs(args) do
							if not used_args[key] then
								ok = false
								if arg.type == "pair" and arg.value[1].type == "string" then
									table.insert(tried_function_error_messages, ("%s: unexpected %s argument"):format(fn.pretty_signature, arg.value[1].value))
								else
									table.insert(tried_function_error_messages, ("%s: unexpected argument in position %s"):format(fn.pretty_signature, i))
								end
								break
							end
						end
					end
					-- assignment arg
					if ok and exp.assignment then
						-- check type constraint
						local param = fn.assignment
						local depth, err = check_constraint(state, param.full_name, assignment)
						if not depth then
							ok = false
							local v = state.variable_constraints[param.full_name].value
							table.insert(tried_function_error_messages, ("%s: argument %s is not of expected type %s"):format(fn.pretty_signature, param.name, format(v) or v))
						end
						depths.assignment = depth
						-- set
						variant_args[param.full_name] = assignment
					end
					if ok then
						if not selected_variant.variant then
							selected_variant.depths = depths
							selected_variant.variant = fn
							selected_variant.args_to_set = variant_args
						else
							-- check specificity order
							local lower
							for j, d in ipairs(depths) do
								local current_depth = selected_variant.depths[j] or math.huge -- not every arg may be set on every variant (varargs)
								if d < current_depth then -- stricly lower, i.e. more specific function
									lower = true
									break
								elseif d > current_depth then -- stricly greater, i.e. less specific function
									lower = false
									break
								end
							end
							if lower == nil and exp.assignment then -- use assignment if still ambigous
								local current_depth = selected_variant.depths.assignment
								if depths.assignment < current_depth then -- stricly lower, i.e. more specific function
									lower = true
								elseif depths.assignment > current_depth then -- stricly greater, i.e. less specific function
									lower = false
								end
							end
							if lower then
								selected_variant.depths = depths
								selected_variant.variant = fn
								selected_variant.args_to_set = variant_args
							elseif lower == nil then -- equal, ambigous dispatch
								return nil, ("function call %q is ambigous; may be at least either:\n\t%s\n\t%s"):format(exp.called_name, fn.pretty_signature, selected_variant.variant.pretty_signature)
							end
						end
					end
				end
			end
		end
		-- function successfully selected: run
		if selected_variant.variant then
			local fn = selected_variant.variant
			if fn.type ~= "function" then
				return nil, ("unknown function type %q"):format(fn.type)
			-- checkpoint: no args and resume execution
			elseif fn.subtype == "checkpoint" then
				local r, e = run(state, fn.child, not paren_call)
				if not r then return nil, e end
				return r
			-- other functions
			else
				local ret
				-- push scope
				-- NOTE: if error happens between here and scope:pop, will leave the stack a mess
				-- should not be an issue since an interpreter is supposed to be discarded after an error, but should change this if we ever
				-- add some excepetion handling in anselme at some point
				if fn.scoped then
					scope:push(state, fn)
				end
				-- set arguments
				for name, val in pairs(selected_variant.args_to_set) do
					local s, e = set_variable(state, name, val)
					if not s then return nil, e end
				end
				-- get function vars
				local checkpoint, checkpointe = get_variable(state, fn.namespace.."🔖")
				if not checkpoint then return nil, checkpointe end
				local seen, seene = get_variable(state, fn.namespace.."👁️")
				if not seen then return nil, seene end
				-- execute lua functions
				-- I guess we could technically skip getting & updating the seen and checkpoints vars since they can't be used from Anselme
				-- but it's also kinda fun to known how many time a function was ran
				if fn.lua_function then
					local lua_fn = fn.lua_function
					-- get args
					local final_args = {}
					for j, param in ipairs(fn.params) do
						local v, e = get_variable(state, param.full_name)
						if not v then return nil, e end
						final_args[j] = v
					end
					if fn.assignment then
						local v, e = get_variable(state, fn.assignment.full_name)
						if not v then return nil, e end
						final_args[#final_args+1] = v
					end
					-- execute function
					-- raw mode: pass raw anselme values to the Lua function; support return nil, err in case of error
					if lua_fn.mode == "raw" then
						local r, e = lua_fn.value(unpack(final_args))
						if r then
							ret = r
						else
							return nil, ("%s; in Lua function %q"):format(e or "raw function returned nil and no error message", exp.called_name)
						end
					-- unannotated raw mode: same as raw, but strips custom annotations from the arguments
					elseif lua_fn.mode == "unannotated raw" then
						-- extract value from custom types
						for i, arg in ipairs(final_args) do
							if arg.type == "annotated" then
								final_args[i] = arg.value[1]
							end
						end
						local r, e = lua_fn.value(unpack(final_args))
						if r then
							ret = r
						else
							return nil, ("%s; in Lua function %q"):format(e or "unannotated raw function returned nil and no error message", exp.called_name)
						end
					-- normal mode: convert args to Lua and convert back Lua value to Anselme
					elseif lua_fn.mode == nil then
						local l_lua = {}
						for _, v in ipairs(final_args) do
							local lv, e = to_lua(v, state)
							if e then return nil, e end
							table.insert(l_lua, lv)
						end
						local r, e
						if _VERSION == "Lua 5.1" and not jit then -- PUC Lua 5.1 doesn't allow yield from a pcall
							r, e = true, lua_fn.value(unpack(l_lua))
						else
							r, e = pcall(lua_fn.value, unpack(l_lua)) -- pcall to produce a more informative error message (instead of full coroutine crash)
						end
						if r then
							ret = from_lua(e)
						else
							return nil, ("%s; in Lua function %q"):format(e, exp.called_name)
						end
					else
						return nil, ("unknown Lua function mode %q"):format(lua_fn.mode)
					end
				-- execute anselme functions
				else
					local e
					-- eval function from start
					if paren_call or checkpoint.type == "nil" then
						ret, e = run(state, fn.child)
					-- resume at last checkpoint
					else
						local expr, err = expression(checkpoint.value[1], state, fn.namespace)
						if not expr then return nil, err end
						ret, e = eval(state, expr)
					end
					if not ret then return nil, e end
				end
				-- update function vars
				local s, e = set_variable(state, fn.namespace.."👁️", {
					type = "number",
					value = seen.value + 1
				})
				if not s then return nil, e end
				-- for classes: build resulting object
				if fn.subtype == "class" then
					local object = {
						type = "annotated",
						value = {
							{
								type = "object",
								value = {
									class = fn.name,
									attributes = {}
								}
							},
							{
								type = "function reference",
								value = { fn.name }
							}
						}
					}
					if ret and ret.type == "nil" then
						ret = object
					end
				end
				-- pop scope
				if fn.scoped then
					scope:pop(state, fn)
				end
				-- return value
				if not ret then return nil, ("function %q didn't return a value"):format(exp.called_name) end
				return ret
			end
		end
		-- no matching function found
		local args_txt = {}
		for key, arg in pairs(args) do
			local s = ""
			if type(key) == "string" or (type(key) == "number" and key > last_contiguous_positional) then
				s = s .. ("%s="):format(key)
			end
			s = s .. pretty_type(arg)
			table.insert(args_txt, s)
		end
		local called_name = ("%s(%s)"):format(exp.called_name, table.concat(args_txt, ", "))
		if assignment then
			called_name = called_name .. " := " .. pretty_type(assignment)
		end
		return nil, ("no compatible function found for call to %s; potential candidates were:\n\t%s"):format(called_name, table.concat(tried_function_error_messages, "\n\t"))
	-- event buffer (internal type, only issued from a text or choice line)
	elseif exp.type == "text" then
		local l = {}
		events:push_buffer(state, l)
		local current_tags = tags:current(state)
		local v, e = eval_text_callback(state, exp.text, function(text)
			events:append(state, "text", { text = text, tags = current_tags })
		end)
		events:pop_buffer(state)
		if not v then return nil, e end
		return {
			type = "event buffer",
			value = l
		}
	-- pass the value along (internal type, used for variable reference implicit calls)
	elseif exp.type == "value passthrough" then
		return exp.value
	else
		return nil, ("unknown expression %q"):format(tostring(exp.type))
	end
end

package.loaded[...] = eval
run = require((...):gsub("expression$", "interpreter")).run
expression = require((...):gsub("interpreter%.expression$", "parser.expression"))
flatten_list = require((...):gsub("interpreter%.expression$", "parser.common")).flatten_list
local common = require((...):gsub("expression$", "common"))
to_lua, from_lua, eval_text, truthy, format, pretty_type, get_variable, tags, eval_text_callback, events, set_variable, scope, check_constraint, hash = common.to_lua, common.from_lua, common.eval_text, common.truthy, common.format, common.pretty_type, common.get_variable, common.tags, common.eval_text_callback, common.events, common.set_variable, common.scope, common.check_constraint, common.hash

return eval
