local atypes, ltypes
local eval

local common
common = {
	-- flush interpreter state to global state
	merge_state = function(state)
		local global_vars = state.interpreter.global_state.variables
		for var, value in pairs(state.variables) do
			global_vars[var] = value
			state.variables[var] = nil
		end
	end,
	-- returns a variable's value, evaluating a pending expression if neccessary
	-- if you're sure the variable has already been evaluated, use state.variables[fqm] directly
	-- return var
	-- return nil, err
	get_variable = function(state, fqm)
		local var = state.variables[fqm]
		if var.type == "pending definition" then
			local v, e = eval(state, var.value.expression)
			if not v then
				return nil, ("%s; while evaluating default value for variable %q defined at %s"):format(e, fqm, var.value.source)
			end
			state.variables[fqm] = v
			return v
		else
			return var
		end
	end,
	-- check truthyness of an anselme value
	truthy = function(val)
		if val.type == "number" then
			return val.value ~= 0
		elseif val.type == "nil" then
			return false
		else
			return true
		end
	end,
	-- compare two anselme value for equality
	compare = function(a, b)
		if a.type ~= b.type then
			return false
		end
		if a.type == "pair" or a.type == "type" then
			return common.compare(a.value[1], b.value[1]) and common.compare(a.value[2], b.value[2])
		elseif a.type == "list" then
			if #a.value ~= #b.value then
				return false
			end
			for i, v in ipairs(a.value) do
				if not common.compare(v, b.value[i]) then
					return false
				end
			end
			return true
		else
			return a.value == b.value
		end
	end,
	-- format a anselme value to something printable
	-- does not call custom {}() functions, only built-in ones, so it should not be able to fail
	-- str: if success
	-- * nil, err: if error
	format = function(val)
		if atypes[val.type] and atypes[val.type].format then
			return atypes[val.type].format(val.value)
		else
			return nil, ("no formatter for type %q"):format(val.type)
		end
	end,
	-- lua value: if success (may be nil!)
	-- * nil, err: if error
	to_lua = function(val)
		if atypes[val.type] and atypes[val.type].to_lua then
			return atypes[val.type].to_lua(val.value)
		else
			return nil, ("no Lua exporter for type %q"):format(val.type)
		end
	end,
	-- anselme value: if success
	-- * nil, err: if error
	from_lua = function(val)
		if ltypes[type(val)] and ltypes[type(val)].to_anselme then
			return ltypes[type(val)].to_anselme(val)
		else
			return nil, ("no Lua importer for type %q"):format(type(val))
		end
	end,
	-- string: if success
	-- * nil, err: if error
	eval_text = function(state, text)
		local s = ""
		for _, item in ipairs(text) do
			if type(item) == "string" then
				s = s .. item
			else
				local v, e = eval(state, item)
				if not v then return v, e end
				v, e = common.format(v)
				if not v then return v, e end
				s = s .. v
			end
		end
		return s
	end,
	-- specificity(number): if var is of type type
	-- false: if not
	is_of_type = function(var, type)
		local depth = 1
		-- var has a custom type
		if var.type == "type" then
			local var_type = var.value[2]
			while true do
				if common.compare(var_type, type) then -- same type
					return depth
				elseif var_type.type == "type" then -- compare parent type
					depth = depth + 1
					var_type = var_type.value[2]
				else -- no parent, fall back on base type
					depth = depth + 1
					var = var.value[1]
					break
				end
			end
		end
		-- var has a base type
		return type.type == "string" and type.value == var.type and depth
	end,
	-- return a pretty printable type value for var
	pretty_type = function(var)
		if var.type == "type" then
			return common.format(var.value[2])
		else
			return var.type
		end
	end
}

package.loaded[...] = common
local types = require((...):gsub("interpreter%.common$", "stdlib.types"))
atypes, ltypes = types.anselme, types.lua
eval = require((...):gsub("common$", "expression"))

return common
