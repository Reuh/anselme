local format, to_lua, from_lua, events, anselme

local types = {}
types.lua = {
	["nil"] = {
		to_anselme = function(val)
			return {
				type = "nil",
				value = nil
			}
		end
	},
	boolean = {
		to_anselme = function(val)
			return {
				type = "number",
				value = val and 1 or 0
			}
		end
	},
	number = {
		to_anselme = function(val)
			return {
				type = "number",
				value = val
			}
		end
	},
	string = {
		to_anselme = function(val)
			return {
				type = "string",
				value = val
			}
		end
	},
	table = {
		to_anselme = function(val)
			local l = {}
			for _, v in ipairs(val) do
				local r, e = from_lua(v)
				if not r then return r, e end
				table.insert(l, r)
			end
			for k, v in pairs(val) do
				if not l[k] then
					local kv, ke = from_lua(k)
					if not k then return k, ke end
					local vv, ve = from_lua(v)
					if not v then return v, ve end
					table.insert(l, {
						type = "pair",
						value = { kv, vv }
					})
				end
			end
			return {
				type = "list",
				value = l
			}
		end
	}
}

types.anselme = {
	["nil"] = {
		format = function()
			return ""
		end,
		to_lua = function()
			return nil
		end
	},
	number = {
		format = function(val)
			return tostring(val)
		end,
		to_lua = function(val)
			return val
		end
	},
	string = {
		format = function(val)
			return tostring(val)
		end,
		to_lua = function(val)
			return val
		end
	},
	list = {
		format = function(val)
			local l = {}
			for _, v in ipairs(val) do
				local s, e = format(v)
				if not s then return s, e end
				table.insert(l, s)
			end
			return ("[%s]"):format(table.concat(l, ", "))
		end,
		to_lua = function(val)
			local l = {}
			-- handle non-pair before pairs as LuaJIT's table.insert
			-- will always insert after the last element even if there are some nil before unlike PUC
			for _, v in ipairs(val) do
				if v.type ~= "pair" then
					local s, e = to_lua(v)
					if not s and e then return s, e end
					table.insert(l, s)
				end
			end
			for _, v in ipairs(val) do
				if v.type == "pair" then
					local k, ke = to_lua(v.value[1])
					if not k and ke then return k, ke end
					local x, xe = to_lua(v.value[2])
					if not x and xe then return x, xe end
					l[k] = x
				end
			end
			return l
		end,
	},
	pair = {
		format = function(val)
			local k, ke = format(val[1])
			if not k then return k, ke end
			local v, ve = format(val[2])
			if not v then return v, ve end
			return ("%s=%s"):format(k, v)
		end,
		to_lua = function(val)
			local k, ke = to_lua(val[1])
			if not k and ke then return k, ke end
			local v, ve = to_lua(val[2])
			if not v and ve then return v, ve end
			return { [k] = v }
		end
	},
	type = {
		format = function(val)
			local k, ke = format(val[1])
			if not k then return k, ke end
			local v, ve = format(val[2])
			if not v then return v, ve end
			return ("%s::%s"):format(k, v)
		end,
		to_lua = function(val)
			local k, ke = to_lua(val[1])
			if not k and ke then return k, ke end
			return k
		end
	},
	["function reference"] = {
		format = function(val)
			if #val > 1 then
				return ("&(%s)"):format(table.concat(val, ", "))
			else
				return ("&%s"):format(table.concat(val, ", "))
			end
		end,
		to_lua = nil
	},
	["variable reference"] = {
		format = function(val)
			return ("&%s"):format(val)
		end,
		to_lua = nil
	},
	object = {
		format = function(val)
			return ("%%%s"):format(val.class)
		end,
		to_lua = nil
	},
	-- internal types
	["event buffer"] = {
		format = function(val) -- triggered from subtexts
			local v, e = events:write_buffer(anselme.running.state, val)
			if not v then return v, e end
			return ""
		end
	},
}

package.loaded[...] = types
local common = require((...):gsub("stdlib%.types$", "interpreter.common"))
format, to_lua, from_lua, events = common.format, common.to_lua, common.from_lua, common.events
anselme = require((...):gsub("stdlib%.types$", "anselme"))

return types
