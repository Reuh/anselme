local expression
local flush_state, to_lua, from_lua, eval_text

local run, run_block

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
	elseif exp.type == "list_parentheses" then
		if exp.expression then
			local v, e = eval(state, exp.expression)
			if not v then return v, e end
			if v.type == "list" then
				return v
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
			-- eval args: same as list, but only put vararg arguments in a separate list
			local l = {}
			if exp.argument then
				local vararg = fn.vararg or math.huge
				local i, ast = 1, exp.argument
				while ast.type == "list" and i < vararg do
					local left, lefte = eval(state, ast.left)
					if not left then return left, lefte end
					table.insert(l, left)
					ast = ast.right
					i = i + 1
				end
				local right, righte = eval(state, ast)
				if not right then return right, righte end
				table.insert(l, right)
			end
			if fn.vararg and #l < fn.vararg then -- empty list vararg
				table.insert(l, { type = "list", value = {} })
			end
			-- anselme function
			if type(fn.value) == "table"  then
				-- paragraph & paragraph decorator
				if fn.value.type == "paragraph" or fn.value.paragraph then
					local r, e
					if fn.value.type == "paragraph" then
						r, e = run_block(state, fn.value.child)
						if e then return r, e end
						state.variables[fn.value.namespace.."👁️"] = {
							type = "number",
							value = state.variables[fn.value.namespace.."👁️"].value + 1
						}
						state.variables[fn.value.parent_function.namespace.."🏁"] = {
							type = "string",
							value = fn.value.name
						}
						flush_state(state)
						if r then
							return r, e
						-- resume function from paragraph
						elseif not exp.explicit_call then
							r, e = run(state, fn.value.parent_block, true, fn.value.parent_position+1)
						else
							r = { type = "nil", value = nil }
						end
					-- paragraph decorators: run single line or resume from it.
					-- checkpoint & seen variables will be updated from the interpreter usual paragraph-reaching code.
					elseif exp.explicit_call then
						r, e = run(state, fn.value.parent_block, false, fn.value.parent_position, fn.value.parent_position)
					else
						r, e = run(state, fn.value.parent_block, true, fn.value.parent_position)
					end
					if not r then return r, e end
					return r
				-- function
				elseif fn.value.type == "function" then
					-- set args
					for j, param in ipairs(fn.value.params) do
						state.variables[param] = l[j]
					end
					-- eval function
					local r, e
					if exp.explicit_call or state.variables[fn.value.namespace.."🏁"].value == "" then
						r, e = run(state, fn.value.child)
					-- resume at last paragraph
					else
						local expr, err = expression(state.variables[fn.value.namespace.."🏁"].value, state, "")
						if not expr then return expr, err end
						r, e = eval(state, expr)
					end
					if not r then return r, e end
					state.variables[fn.value.namespace.."👁️"] = {
						type = "number",
						value = state.variables[fn.value.namespace.."👁️"].value + 1
					}
					flush_state(state)
					return r
				else
					return nil, ("unknown function type %q"):format(fn.value.type)
				end
			-- lua functions
			else
				if fn.mode == "raw" then
					return fn.value(unpack(l))
				else
					local l_lua = {}
					for _, v in ipairs(l) do
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
run_block = require((...):gsub("expression$", "interpreter")).run_block
expression = require((...):gsub("interpreter%.expression$", "parser.expression"))
local common = require((...):gsub("expression$", "common"))
flush_state, to_lua, from_lua, eval_text = common.flush_state, common.to_lua, common.from_lua, common.eval_text

return eval
