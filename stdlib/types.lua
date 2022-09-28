local format, to_lua, from_lua, events, anselme, escape, hash, update_hashes, get_variable, find_function_variant_from_fqm, post_process_text, traverse

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
		traverse = function() return true end,
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
		traverse = function() return true end,
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
		traverse = function() return true end,
	},
	pair = {
		format = function(val)
			local k, ke = format(val[1])
			if not k then return k, ke end
			local v, ve = format(val[2])
			if not v then return v, ve end
			return ("%s=%s"):format(k, v)
		end,
		to_lua = function(val, state)
			local k, ke = to_lua(val[1], state)
			if ke then return nil, ke end
			local v, ve = to_lua(val[2], state)
			if ve then return nil, ve end
			return { [k] = v }
		end,
		hash = function(val)
			local k, ke = hash(val[1])
			if not k then return k, ke end
			local v, ve = hash(val[2])
			if not v then return v, ve end
			return ("p(%s=%s)"):format(k, v)
		end,
		traverse = function(val, callback, pertype_callback)
			local k, ke = traverse(val[1], callback, pertype_callback)
			if not k then return k, ke end
			local v, ve = traverse(val[2], callback, pertype_callback)
			if not v then return v, ve end
			return true
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
		to_lua = function(val, state)
			local k, ke = to_lua(val[1], state)
			if ke then return nil, ke end
			return k
		end,
		hash = function(val)
			local k, ke = hash(val[1])
			if not k then return k, ke end
			local v, ve = hash(val[2])
			if not v then return v, ve end
			return ("a(%s::%s)"):format(k, v)
		end,
		traverse = function(val, callback, pertype_callback)
			local k, ke = traverse(val[1], callback, pertype_callback)
			if not k then return k, ke end
			local v, ve = traverse(val[2], callback, pertype_callback)
			if not v then return v, ve end
			return true
		end,
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
		to_lua = function(val, state)
			local l = {}
			for _, v in ipairs(val) do
				local s, e = to_lua(v, state)
				if e then return nil, e end
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
		traverse = function(val, callback, pertype_callback)
			for _, item in ipairs(val) do
				local s, e = traverse(item, callback, pertype_callback)
				if not s then return s, e end
			end
			return true
		end,
		mark_constant = function(v)
			v.constant = true
		end,
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
		to_lua = function(val, state)
			local l = {}
			for _, v in pairs(val) do
				local kl, ke = to_lua(v[1], state)
				if ke then return nil, ke end
				local xl, xe = to_lua(v[2], state)
				if xe then return nil, xe end
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
		traverse = function(val, callback, pertype_callback)
			for _, v in pairs(val) do
				local ks, ke = traverse(v[1], callback, pertype_callback)
				if not ks then return ks, ke end
				local vs, ve = traverse(v[2], callback, pertype_callback)
				if not vs then return vs, ve end
			end
			return true
		end,
		mark_constant = function(v)
			v.constant = true
			update_hashes(v)
		end,
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
		to_lua = function(val, state)
			local r = {}
			local namespacePattern = "^"..escape(val.class).."%."
			-- set object properties
			for name, v in pairs(val.attributes) do
				local var, err = to_lua(v, state)
				if err then return nil, err end
				r[name:gsub(namespacePattern, "")] = var
			end
			-- set class properties
			local class, err = find_function_variant_from_fqm(val.class, state, nil)
			if not class then return nil, err end
			assert(#class == 1 and class[1].subtype == "class")
			class = class[1]
			for _, prop in ipairs(class.properties) do
				if not val.attributes[prop] then
					local var
					var, err = get_variable(state, prop)
					if not var then return nil, err end
					var, err = to_lua(var, state)
					if err then return nil, err end
					r[prop:gsub(namespacePattern, "")] = var
				end
			end
			return r
		end,
		hash = function(val)
			local attributes = {}
			for name, v in pairs(val.attributes) do
				table.insert(attributes, ("%s=%s"):format(name:gsub("^"..escape(val.class)..".", ""), format(v)))
			end
			table.sort(attributes)
			return ("%%(%s;%s)"):format(val.class, table.concat(attributes, ","))
		end,
		traverse = function(v, callback, pertype_callback)
			for _, attrib in pairs(v.attributes) do
				local s, e = traverse(attrib, callback, pertype_callback)
				if not s then return s, e end
			end
			return true
		end,
		mark_constant = function(v)
			v.constant = true
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
		traverse = function() return true end,
	},
	["variable reference"] = {
		format = function(val)
			return ("&%s"):format(val)
		end,
		to_lua = nil,
		hash = function(val)
			return ("&v(%s)"):format(val)
		end,
		traverse = function() return true end,
	},
	-- event buffer: can only be used outside of Anselme internals for text & flush events (through text buffers)
	["event buffer"] = {
		format = function(val) -- triggered from subtexts
			local v, e = events:write_buffer(anselme.running.state, val)
			if not v then return v, e end
			return ""
		end,
		to_lua = function(val, state)
			local r = {}
			for _, event in ipairs(val) do
				if event.type == "text" then
					table.insert(r, { "text", post_process_text(state, event.value) })
				elseif event.type == "flush" then
					table.insert(r, { "flush" })
				else
					return nil, ("event %q in event buffer can't be converted to a Lua value"):format(event.type)
				end
			end
			return r
		end,
		hash = function(val)
			local l = {}
			for _, event in ipairs(val) do
				if event.type == "text" then
					local text = {}
					for _, t in ipairs(event.value) do
						local str = ("s(%s)"):format(t.text)
						local tags, e = hash(t.tags)
						if not tags then return nil, e end
						table.insert(text, ("%s#%s"):format(str, tags))
					end
					table.insert(l, ("text(%s)"):format(table.concat(text, ",")))
				elseif event.type == "flush" then
					table.insert(l, "flush")
				else
					return nil, ("event %q in event buffer cannot be hashed"):format(event.type)
				end
			end
			return ("eb(%s)"):format(table.concat(l, ","))
		end,
		traverse = function(val, callback, pertype_callback)
			for _, event in ipairs(val) do
				if event.type == "text" then
					for _, t in ipairs(event.value) do
						local s, e = traverse(t.tags, callback, pertype_callback)
						if not s then return s, e end
					end
				elseif event.type ~= "flush" then
					return nil, ("event %q in event buffer cannot be traversed"):format(event.type)
				end
			end
			return true
		end,
	},
}

package.loaded[...] = types
local common = require((...):gsub("stdlib%.types$", "interpreter.common"))
format, to_lua, from_lua, events, hash, update_hashes, get_variable, post_process_text, traverse = common.format, common.to_lua, common.from_lua, common.events, common.hash, common.update_hashes, common.get_variable, common.post_process_text, common.traverse
anselme = require((...):gsub("stdlib%.types$", "anselme"))
local pcommon = require((...):gsub("stdlib%.types$", "parser.common"))
escape, find_function_variant_from_fqm = pcommon.escape, pcommon.find_function_variant_from_fqm

return types
