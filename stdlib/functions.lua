local truthy, anselme, compare, is_of_type, identifier_pattern, format_identifier, find, get_variable

local functions
functions = {
	-- discard left
	["_;_(a, b)"] = {
		mode = "raw",
		value = function(a, b) return b end
	},
	-- comparaison
	["_==_(a, b)"] = {
		mode = "raw",
		value = function(a, b)
			return {
				type = "number",
				value = compare(a, b) and 1 or 0
			}
		end
	},
	["_!=_(a, b)"] = {
		mode = "raw",
		value = function(a, b)
			return {
				type = "number",
				value = compare(a, b) and 0 or 1
			}
		end
	},
	["_>_(a::number, b::number)"] = function(a, b) return a > b end,
	["_<_(a::number, b::number)"] = function(a, b) return a < b end,
	["_>=_(a::number, b::number)"] = function(a, b) return a >= b end,
	["_<=_(a::number, b::number)"] = function(a, b) return a <= b end,
	-- arithmetic
	["_+_(a::number, b::number)"] = function(a, b) return a + b end,
	["_+_(a::string, b::string)"] = function(a, b) return a .. b end,
	["_-_(a::number, b::number)"] = function(a, b) return a - b end,
	["-_(a::number)"] = function(a) return -a end,
	["_*_(a::number, b::number)"] = function(a, b) return a * b end,
	["_/_(a::number, b::number)"] = function(a, b) return a / b end,
	["_//_(a::number, b::number)"] = function(a, b) return math.floor(a / b) end,
	["_^_(a::number, b::number)"] = function(a, b) return a ^ b end,
	-- boolean
	["!_(a)"] = {
		mode = "raw",
		value = function(a)
			return {
				type = "number",
				value = truthy(a) and 0 or 1
			}
		end
	},
	-- pair
	["_:_(a, b)"] = {
		mode = "raw",
		value = function(a, b)
			return {
				type = "pair",
				value = { a, b }
			}
		end
	},
	-- type
	["_::_(a, b)"] = {
		mode = "raw",
		value = function(a, b)
			return {
				type = "type",
				value = { a, b }
			}
		end
	},
	-- namespace
	["_._(r::function reference, name::string)"] = {
		mode = "raw",
		value = function(r, n)
			local state = anselme.running.state
			local rval = r.value
			local name = n.value
			for _, ffqm in ipairs(rval) do
				local var, vfqm = find(state.aliases, state.variables, ffqm..".", name)
				if var then
					return get_variable(state, vfqm)
				end
			end
			return nil, ("can't find variable %q in function reference (searched in namespaces: %s)"):format(name, table.concat(rval, ", "))
		end
	},
	-- index
	["()(l::list, i::number)"] = {
		mode = "untyped raw",
		value = function(l, i)
			return l.value[i.value] or { type = "nil", value = nil }
		end
	},
	["()(l::list, i::string)"] = {
		mode = "untyped raw",
		value = function(l, i)
			for _, v in ipairs(l.value) do
				if v.type == "pair" and compare(v.value[1], i) then
					return v.value[2]
				end
			end
			return { type = "nil", value = nil }
		end
	},
	-- index assignment
	["()(l::list, i::number) := v"] = {
		mode = "raw",
		value = function(l, i, v)
			l.modified = true
			local lv = l.type == "type" and l.value[1] or l
			local iv = i.type == "type" and i.value[1] or i
			lv.value[iv.value] = v
			return v
		end
	},
	["()(l::list, k::string) := v"] = {
		mode = "raw",
		value = function(l, k, v)
			l.modified = true
			local lv = l.type == "type" and l.value[1] or l
			local kv = k.type == "type" and k.value[1] or k
			-- update index
			for _, x in ipairs(lv.value) do
				if x.type == "pair" and compare(x.value[1], kv) then
					x.value[2] = v
					return v
				end
			end
			-- new index
			table.insert(lv.value, {
				type = "pair",
				value = { kv, v }
			})
			return v
		end
	},
	["()(fn::function reference, l...)"] = {
		-- bypassed, this case is manually handled in the expression interpreter
	},
	["_!(fn::function reference, l...)"] = {
		-- bypassed, this case is manually handled in the expression interpreter
	},
	-- format
	["{}(v)"] = {
		mode = "raw",
		value = function(v)
			return v
		end
	},
	-- alias
	["alias(identifier::string, alias::string)"] = {
		value = function(identifier, alias)
			-- check identifiers
			local fqm = identifier:match("^"..identifier_pattern.."$")
			if not fqm then error(("%q is not a valid identifier"):format(identifier)) end
			fqm = format_identifier(fqm)
			local aliasfqm = alias:match("^"..identifier_pattern.."$")
			if not aliasfqm then error(("%q is not a valid identifier for an alias"):format(alias)) end
			aliasfqm = format_identifier(aliasfqm)
			-- define alias
			local aliases = anselme.running.state.aliases
			if aliases[aliasfqm] ~= nil and aliases[aliasfqm] ~= fqm then
				error(("trying to define alias %q for %q, but already exist and refer to %q"):format(aliasfqm, fqm, aliases[alias]))
			end
			aliases[aliasfqm] = fqm
		end
	},
	-- pair methods
	["name(p::pair)"] = {
		mode = "untyped raw",
		value = function(a)
			return a.value[1]
		end
	},
	["value(p::pair)"] = {
		mode = "untyped raw",
		value = function(a)
			return a.value[2]
		end
	},
	-- list methods
	["len(l::list)"] = {
		mode = "untyped raw", -- raw to count pairs in the list
		value = function(a)
			return {
				type = "number",
				value = #a.value
			}
		end
	},
	["insert(l::list, v)"] = {
		mode = "raw",
		value = function(l, v)
			l.modified = true
			local lv = l.type == "type" and l.value[1] or l
			table.insert(lv.value, v)
			return l
		end
	},
	["insert(l::list, i::number, v)"] = {
		mode = "raw",
		value = function(l, i, v)
			l.modified = true
			local lv = l.type == "type" and l.value[1] or l
			local iv = i.type == "type" and i.value[1] or i
			table.insert(lv.value, iv.value, v)
			return l
		end
	},
	["remove(l::list)"] = {
		mode = "untyped raw",
		value = function(l)
			l.modified = true
			return table.remove(l.value)
		end
	},
	["remove(l::list, i::number)"] = {
		mode = "untyped raw",
		value = function(l, i)
			l.modified = true
			return table.remove(l.value, i.value)
		end
	},
	["find(l::list, v)"] = {
		mode = "raw",
		value = function(l, v)
			local lv = l.type == "type" and l.value[1] or l
			for i, x in ipairs(lv.value) do
				if compare(x, v) then
					return i
				end
			end
			return { type = "number", value = 0 }
		end
	},
	-- other methods
	["error(m::string)"] = function(m) error(m, 0) end,
	["rand()"] = function() return math.random() end,
	["rand(a::number)"] = function(a) return math.random(a) end,
	["rand(a::number, b::number)"] = function(a, b) return math.random(a, b) end,
	["raw(v)"] = {
		mode = "raw",
		value = function(v)
			if v.type == "type" then
				return v.value[1]
			else
				return v
			end
		end
	},
	["type(v)"] = {
		mode = "raw",
		value = function(v)
			if v.type == "type" then
				return v.value[2]
			else
				return {
					type = "string",
					value = v.type
				}
			end
		end
	},
	["is of type(v, t)"] = {
		mode = "raw",
		value = function(v, t)
			return {
				type = "number",
				value = is_of_type(v, t) or 0
			}
		end
	},
	["cycle(l...)"] = function(l)
		local f, fseen = l[1], assert(anselme.running:eval(l[1]..".👁️", anselme.running:current_namespace()))
		for j=2, #l do
			local seen = assert(anselme.running:eval(l[j]..".👁️", anselme.running:current_namespace()))
			if seen < fseen then
				f = l[j]
				break
			end
		end
		return anselme.running:run(f, anselme.running:current_namespace())
	end,
	["random(l...)"] = function(l)
		return anselme.running:run(l[math.random(1, #l)], anselme.running:current_namespace())
	end,
	["next(l...)"] = function(l)
		local f = l[#l]
		for j=1, #l-1 do
			local seen = assert(anselme.running:eval(l[j]..".👁️", anselme.running:current_namespace()))
			if seen == 0 then
				f = l[j]
				break
			end
		end
		return anselme.running:run(f, anselme.running:current_namespace())
	end
}

package.loaded[...] = functions
local icommon = require((...):gsub("stdlib%.functions$", "interpreter.common"))
truthy, compare, is_of_type, get_variable = icommon.truthy, icommon.compare, icommon.is_of_type, icommon.get_variable
local pcommon = require((...):gsub("stdlib%.functions$", "parser.common"))
identifier_pattern, format_identifier, find = pcommon.identifier_pattern, pcommon.format_identifier, pcommon.find
anselme = require((...):gsub("stdlib%.functions$", "anselme"))
