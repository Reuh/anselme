local expression
local to_lua, from_lua, eval_text

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
	-- variable
	elseif exp.type == "variable" then
		return state.variables[exp.name]
	-- list
	elseif exp.type == "list" then
		local l = {}
		local ast = exp
		while ast.type == "list" do
			local left, lefte = eval(state, ast.left)
			if not left then return left, lefte end
			table.insert(l, left)
			ast = ast.right
		end
		local right, righte = eval(state, ast)
		if not right then return right, righte end
		table.insert(l, right)
		return {
			type = "list",
			value = l
		}
	-- function
	elseif exp.type == "function" then
		local fn = exp.variant
		-- custom lua functions
		if fn.mode == "custom" then
			return fn.value(state, exp)
		else
			-- eval args: list_brackets
			local args = {}
			if exp.argument then
				local arg, arge = eval(state, exp.argument)
				if not arg then return arg, arge end
				args = arg.value
			end
			-- anselme function
			if type(fn.value) == "table"  then
				-- checkpoint
				if fn.value.type == "checkpoint" then
					local r, e = run(state, fn.value.child, not exp.explicit_call)
					if not r then return r, e end
					return r
				-- function
				elseif fn.value.type == "function" then
					-- map named arguments
					for _, arg in ipairs(args) do
						if arg.type == "pair" and arg.value[1].type == "string" then
							args[arg.value[1].value] = arg.value[2]
						end
					end
					-- get and set args
					for j, param in ipairs(fn.value.params) do
						local val
						-- named
						if param.alias and args[param.alias] then
							val = args[param.alias]
						elseif args[param.name] then
							val = args[param.name]
						-- vararg
						elseif param.vararg then
							val = { type = "list", value = {} }
							for k=j, #args do
								table.insert(val.value, args[k])
							end
						-- positional
						elseif args[j] and args[j].type ~= "pair" then
							val = args[j]
						-- default
						elseif param.default then
							local v, e = eval(state, param.default)
							if not v then return v, e end
							val = v
						end
						if val then
							state.variables[param.full_name] = val
						else
							return nil, ("missing mandatory argument %q in function %q call"):format(param.name, fn.value.name)
						end
					end
					-- eval function
					local r, e
					if exp.explicit_call or state.variables[fn.value.namespace.."🔖"].value == "" then
						r, e = run(state, fn.value.child)
					-- resume at last checkpoint
					else
						local expr, err = expression(state.variables[fn.value.namespace.."🔖"].value, state, "")
						if not expr then return expr, err end
						r, e = eval(state, expr)
					end
					if not r then return r, e end
					state.variables[fn.value.namespace.."👁️"] = {
						type = "number",
						value = state.variables[fn.value.namespace.."👁️"].value + 1
					}
					return r
				else
					return nil, ("unknown function type %q"):format(fn.value.type)
				end
			-- lua functions
			-- TODO: handle named and default arguments
			else
				if fn.mode == "raw" then
					return fn.value(unpack(args))
				else
					local l_lua = {}
					for _, v in ipairs(args) do
						table.insert(l_lua, to_lua(v))
					end
					local r, e
					if _VERSION == "Lua 5.1" and not jit then -- PUC Lua 5.1 doesn't allow yield from a pcall
						r, e = true, fn.value(unpack(l_lua))
					else
						r, e = pcall(fn.value, unpack(l_lua)) -- pcall to produce a more informative error message (instead of full coroutine crash)
					end
					if r then
						return from_lua(e)
					else
						return nil, ("%s; in Lua function %q"):format(e, exp.name)
					end
				end
			end
		end
	else
		return nil, ("unknown expression %q"):format(tostring(exp.type))
	end
end

package.loaded[...] = eval
run = require((...):gsub("expression$", "interpreter")).run
expression = require((...):gsub("interpreter%.expression$", "parser.expression"))
local common = require((...):gsub("expression$", "common"))
to_lua, from_lua, eval_text = common.to_lua, common.from_lua, common.eval_text

return eval
