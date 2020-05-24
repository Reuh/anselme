local atypes, ltypes
local eval

local common
common = {
	-- flush interpreter state to global state
	flush_state = function(state)
		local global_vars = state.interpreter.global_state.variables
		for var, value in pairs(state.variables) do
			global_vars[var] = value
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
	-- str: if success
	-- * nil, err: if error
	format = function(val)
		if atypes[val.type] and atypes[val.type].format then
			return atypes[val.type].format(val.value)
		else
			return nil, ("no formatter for type %q"):format(val.type)
		end
	end,
	-- lua value: if success
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
	end
}

package.loaded[...] = common
local types = require((...):gsub("interpreter%.common$", "stdlib.types"))
atypes, ltypes = types.anselme, types.lua
eval = require((...):gsub("common$", "expression"))

return common
