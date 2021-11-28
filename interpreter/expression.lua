local expression
local to_lua, from_lua, eval_text, is_of_type, truthy, format, pretty_type, get_variable, tags, eval_text_callback, events, flatten_list

local run

local unpack = table.unpack or unpack

--- evaluate an expression
-- returns evaluated value if success
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
		local t, e = eval_text(state, exp.value)
		if not t then return t, e end
		return {
			type = "string",
			value = t
		}
	-- parentheses
	elseif exp.type == "parentheses" then
		return eval(state, exp.expression)
	-- list parentheses
	elseif exp.type == "list_brackets" then
		if exp.expression then
			local v, e = eval(state, exp.expression)
			if not v then return v, e end
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
	-- list
	elseif exp.type == "list" then
		local flat = flatten_list(exp)
		local l = {}
		for _, ast in ipairs(flat) do
			local v, e = eval(state, ast)
			if not v then return v, e end
			table.insert(l, v)
		end
		return {
			type = "list",
			value = l
		}
	-- text: only triggered from choice/text lines
	elseif exp.type == "text" then
		local currentTags = tags:current(state)
		local v, e = eval_text_callback(state, exp.text, function(text)
			local v2, e2 = events:append(state, "text", { text = text, tags = currentTags })
			if not v2 then return v2, e2 end
		end)
		if not v then return v, e end
		return {
			type = "nil",
			value = nil
		}
	-- assignment
	elseif exp.type == ":=" then
		if exp.left.type == "variable" then
			local name = exp.left.name
			local val, vale = eval(state, exp.right)
			if not val then return val, vale end
			state.variables[name] = val
			return val
		else
			return nil, ("don't know how to perform assignment on %s expression"):format(exp.left.type)
		end
	-- lazy boolean operators
	elseif exp.type == "&" then
		local left, lefte = eval(state, exp.left)
		if not left then return left, lefte end
		if truthy(left) then
			local right, righte = eval(state, exp.right)
			if not right then return right, righte end
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
		if not left then return left, lefte end
		if truthy(left) then
			return {
				type = "number",
				value = 1
			}
		end
		local right, righte = eval(state, exp.right)
		if not right then return right, righte end
		return {
			type = "number",
			value = truthy(right) and 1 or 0
		}
	-- conditional
	elseif exp.type == "~" then
		local right, righte = eval(state, exp.right)
		if not right then return right, righte end
		if truthy(right) then
			local left, lefte = eval(state, exp.left)
			if not left then return left, lefte end
			return left
		end
		return {
			type = "nil",
			value = nil
		}
	-- tag
	elseif exp.type == "#" then
		local right, righte = eval(state, exp.right)
		if not right then return right, righte end
		local i = tags:push(state, right)
		local left, lefte = eval(state, exp.left)
		tags:trim(state, i-1)
		if not left then return left, lefte end
		return left
	-- variable
	elseif exp.type == "variable" then
		return get_variable(state, exp.name)
	-- function
	elseif exp.type == "function" then
		-- eval args: list_brackets
		local args = {}
		if exp.argument then
			local arg, arge = eval(state, exp.argument)
			if not arg then return arg, arge end
			args = arg.value
		end
		-- map named arguments
		local named_args = {}
		for i, arg in ipairs(args) do
			if arg.type == "pair" and arg.value[1].type == "string" then
				named_args[arg.value[1].value] = { i, arg.value[2] }
			end
		end
		-- eval assignment arg
		local assignment
		if exp.assignment then
			local arge
			assignment, arge = eval(state, exp.assignment)
			if not assignment then return assignment, arge end
		end
		-- try to select a function
		local tried_function_error_messages = {}
		local selected_variant = { depths = { assignment = nil }, variant = nil }
		for _, fn in ipairs(exp.variants) do
			-- checkpoint: no args, nothing to select on
			if fn.type == "checkpoint" then
				if not selected_variant.variant then
					selected_variant.depths = {}
					selected_variant.variant = fn
				else
					return nil, ("checkpoint call %q is ambigous; may be at least either:\n\t%s\n\t%s"):format(exp.called_name, fn.pretty_signature, selected_variant.variant.pretty_signature)
				end
			-- function
			elseif fn.type == "function" then
				if not fn.assignment or exp.assignment then
					local ok = true
					-- get and set args
					local used_args = {}
					local depths = { assignment = nil }
					for j, param in ipairs(fn.params) do
						local val
						-- named
						if param.alias and named_args[param.alias] then
							val = named_args[param.alias][2]
							used_args[named_args[param.alias][1]] = true
						elseif named_args[param.name] then
							val = named_args[param.name][2]
							used_args[named_args[param.name][1]] = true
						-- vararg
						elseif param.vararg then
							val = { type = "list", value = {} }
							for k=j, #args do
								table.insert(val.value, args[k])
								used_args[k] = true
							end
						-- positional
						elseif args[j] and args[j].type ~= "pair" then
							val = args[j]
							used_args[j] = true
						end
						if val then
							-- check type annotation
							if param.type_annotation then
								local v, e = eval(state, param.type_annotation)
								if not v then return v, e end
								local depth = is_of_type(val, v)
								if not depth then
									ok = false
									table.insert(tried_function_error_messages, ("%s: argument %s is not of expected type %s"):format(fn.pretty_signature, param.name, format(v) or v))
									break
								end
								depths[j] = depth
							else
								depths[j] = math.huge
							end
							-- set
							state.variables[param.full_name] = val
						-- default: evaluate once function is selected
						-- there's no need to type check because the type annotation is already the default value's type, because of syntax
						elseif param.default then
							state.variables[param.full_name] = { type = "pending definition", value = { expression = param.default, source = fn.source } }
						else
							ok = false
							table.insert(tried_function_error_messages, ("%s: missing mandatory argument %q in function %q call"):format(fn.pretty_signature, param.name, fn.name))
							break
						end
					end
					-- check for unused arguments
					if ok then
						for i, arg in ipairs(args) do
							if not used_args[i] then
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
						-- check type annotation
						local param = fn.assignment
						if param.type_annotation then
							local v, e = eval(state, param.type_annotation)
							if not v then return v, e end
							local depth = is_of_type(assignment, v)
							if not depth then
								ok = false
								table.insert(tried_function_error_messages, ("%s: argument %s is not of expected type %s"):format(fn.pretty_signature, param.name, format(v) or v))
							else
								depths.assignment = depth
							end
						else
							depths.assignment = math.huge
						end
						-- set
						state.variables[param.full_name] = assignment
					end
					if ok then
						if not selected_variant.variant then
							selected_variant.depths = depths
							selected_variant.variant = fn
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
							elseif lower == nil then -- equal, ambigous dispatch
								return nil, ("function call %q is ambigous; may be at least either:\n\t%s\n\t%s"):format(exp.called_name, fn.pretty_signature, selected_variant.variant.pretty_signature)
							end
						end
					end
				end
			else
				return nil, ("unknown function type %q"):format(fn.type)
			end
		end
		-- function successfully selected
		if selected_variant.variant then
			local fn = selected_variant.variant
			if fn.type == "checkpoint" then
				local r, e = run(state, fn.child, not exp.explicit_call)
				if not r then return r, e end
				return r
			elseif fn.type == "function" then
				local ret
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
						if not v then return v, e end
						final_args[j] = v
					end
					if fn.assignment then
						local v, e = get_variable(state, fn.assignment.full_name)
						if not v then return v, e end
						final_args[#final_args+1] = v
					end
					-- execute function
					-- raw mode: pass raw anselme values to the Lua function
					if lua_fn.mode == "raw" then
						ret = lua_fn.value(unpack(final_args))
					-- untyped raw mode: same as raw, but strips custom types from the arguments
					elseif lua_fn.mode == "untyped raw" then
						-- extract value from custom types
						for i, arg in ipairs(final_args) do
							if arg.type == "type" then
								final_args[i] = arg.value[1]
							end
						end
						ret = lua_fn.value(unpack(final_args))
					-- normal mode: convert args to Lua and convert back Lua value to Anselme
					elseif lua_fn.mode == nil then
						local l_lua = {}
						for _, v in ipairs(final_args) do
							table.insert(l_lua, to_lua(v))
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
					if exp.explicit_call or checkpoint.value == "" then
						ret, e = run(state, fn.child)
					-- resume at last checkpoint
					else
						local expr, err = expression(checkpoint.value, state, fn.namespace)
						if not expr then return expr, err end
						ret, e = eval(state, expr)
					end
					if not ret then return ret, e end
				end
				-- update function vars
				state.variables[fn.namespace.."👁️"] = {
					type = "number",
					value = seen.value + 1
				}
				-- return value
				if not ret then return nil, ("function %q didn't return a value"):format(exp.called_name) end
				return ret
			end
		end
		-- no matching function found
		local args_txt = {}
		for _, arg in ipairs(args) do
			local s = ""
			if arg.type == "pair" and arg.value[1].type == "string" then
				s = s .. ("%s="):format(arg.value[1].value)
				arg = arg.value[2]
			end
			s = s .. pretty_type(arg)
			table.insert(args_txt, s)
		end
		local called_name = ("%s(%s)"):format(exp.called_name, table.concat(args_txt, ", "))
		if assignment then
			called_name = called_name .. " := " .. pretty_type(assignment)
		end
		return nil, ("no compatible function found for call to %s; potential candidates were:\n\t%s"):format(called_name, table.concat(tried_function_error_messages, "\n\t"))
	else
		return nil, ("unknown expression %q"):format(tostring(exp.type))
	end
end

package.loaded[...] = eval
run = require((...):gsub("expression$", "interpreter")).run
expression = require((...):gsub("interpreter%.expression$", "parser.expression"))
flatten_list = require((...):gsub("interpreter%.expression$", "parser.common")).flatten_list
local common = require((...):gsub("expression$", "common"))
to_lua, from_lua, eval_text, is_of_type, truthy, format, pretty_type, get_variable, tags, eval_text_callback, events = common.to_lua, common.from_lua, common.eval_text, common.is_of_type, common.truthy, common.format, common.pretty_type, common.get_variable, common.tags, common.eval_text_callback, common.events

return eval
