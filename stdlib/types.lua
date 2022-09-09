local format, to_lua, from_lua, events, anselme, escape, hash, mark_constant, update_hashes

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
			local is_map = false
			local l = {}
			local m = {}
			for _, v in ipairs(val) do
				local r, e = from_lua(v)
				if not r then return r, e end
				table.insert(l, r)
			end
			for k, v in pairs(val) do
				if not l[k] then
					is_map = true
					local kv, ke = from_lua(k)
					if not k then return k, ke end
					local vv, ve = from_lua(v)
					if not v then return v, ve end
					local h, err = hash(kv)
					if not h then return nil, err end
					m[h] = { kv, vv }
				end
			end
			if is_map then
				for i, v in ipairs(l) do
					local key = { type = "number", value = i }
					local h, err = hash(key)
					if not h then return nil, err end
					m[h] = { key, v }
				end
				return {
					type = "map",
					value = m
				}
			else
				return {
					type = "list",
					value = l
				}
			end
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
		end,
		hash = function()
			return "nil()"
		end,
		mark_constant = function() end,
	},
	number = {
		format = function(val)
			return tostring(val)
		end,
		to_lua = function(val)
			return val
		end,
		hash = function(val)
			return ("n(%s)"):format(val)
		end,
		mark_constant = function() end,
	},
	string = {
		format = function(val)
			return tostring(val)
		end,
		to_lua = function(val)
			return val
		end,
		hash = function(val)
			return ("s(%s)"):format(val)
		end,
		mark_constant = function() end,
	},
	list = {
		mutable = true,
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
			for _, v in ipairs(val) do
				local s, e = to_lua(v)
				if not s and e then return s, e end
				table.insert(l, s)
			end
			return l
		end,
		hash = function(val)
			local l = {}
			for _, v in ipairs(val) do
				local s, e = hash(v)
				if not s then return s, e end
				table.insert(l, s)
			end
			return ("l(%s)"):format(table.concat(l, ","))
		end,
		mark_constant = function(v)
			v.constant = true
			for _, item in ipairs(v.value) do
				mark_constant(item)
			end
		end
	},
	map = {
		mutable = true,
		format = function(val)
			local l = {}
			for _, v in pairs(val) do
				local ks, ke = format(v[1])
				if not ks then return ks, ke end
				local vs, ve = format(v[2])
				if not vs then return vs, ve end
				table.insert(l, ("%s=%s"):format(ks, vs))
			end
			table.sort(l)
			return ("{%s}"):format(table.concat(l, ", "))
		end,
		to_lua = function(val)
			local l = {}
			for _, v in pairs(val) do
				local kl, ke = to_lua(v[1])
				if not kl and ke then return kl, ke end
				local xl, xe = to_lua(v[2])
				if not xl and xe then return xl, xe end
				l[kl] = xl
			end
			return l
		end,
		hash = function(val)
			local l = {}
			for _, v in pairs(val) do
				local ks, ke = hash(v[1])
				if not ks then return ks, ke end
				local vs, ve = hash(v[2])
				if not vs then return vs, ve end
				table.insert(l, ("%s=%s"):format(ks, vs))
			end
			table.sort(l)
			return ("m(%s)"):format(table.concat(l, ","))
		end,
		mark_constant = function(v)
			v.constant = true
			for _, val in pairs(v.value) do
				mark_constant(val[1])
				mark_constant(val[2])
			end
			update_hashes(v)
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
		end,
		hash = function(val)
			local k, ke = hash(val[1])
			if not k then return k, ke end
			local v, ve = hash(val[2])
			if not v then return v, ve end
			return ("p(%s=%s)"):format(k, v)
		end,
		mark_constant = function(v)
			mark_constant(v.value[1])
			mark_constant(v.value[2])
		end,
	},
	annotated = {
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
		end,
		hash = function(val)
			local k, ke = hash(val[1])
			if not k then return k, ke end
			local v, ve = hash(val[2])
			if not v then return v, ve end
			return ("a(%s::%s)"):format(k, v)
		end,
		mark_constant = function(v)
			mark_constant(v.value[1])
			mark_constant(v.value[2])
		end,
	},
	["function reference"] = {
		format = function(val)
			if #val > 1 then
				return ("&(%s)"):format(table.concat(val, ", "))
			else
				return ("&%s"):format(table.concat(val, ", "))
			end
		end,
		to_lua = nil,
		hash = function(val)
			return ("&f(%s)"):format(table.concat(val, ", "))
		end,
		mark_constant = function() end,

	},
	["variable reference"] = {
		format = function(val)
			return ("&%s"):format(val)
		end,
		to_lua = nil,
		hash = function(val)
			return ("&v(%s)"):format(val)
		end,
		mark_constant = function() end,
	},
	object = {
		mutable = true,
		format = function(val)
			local attributes = {}
			for name, v in pairs(val.attributes) do
				table.insert(attributes, ("%s=%s"):format(name:gsub("^"..escape(val.class)..".", ""), format(v)))
			end
			if #attributes > 0 then
				table.sort(attributes)
				return ("%%%s(%s)"):format(val.class, table.concat(attributes, ", "))
			else
				return ("%%%s"):format(val.class)
			end
		end,
		to_lua = nil,
		hash = function(val)
			local attributes = {}
			for name, v in pairs(val.attributes) do
				table.insert(attributes, ("%s=%s"):format(name:gsub("^"..escape(val.class)..".", ""), format(v)))
			end
			table.sort(attributes)
			return ("%%(%s;%s)"):format(val.class, table.concat(attributes, ","))
		end,
		mark_constant = function(v)
			v.constant = true
		end,
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
format, to_lua, from_lua, events, hash, mark_constant, update_hashes = common.format, common.to_lua, common.from_lua, common.events, common.hash, common.mark_constant, common.update_hashes
anselme = require((...):gsub("stdlib%.types$", "anselme"))
escape = require((...):gsub("stdlib%.types$", "parser.common")).escape

return types
