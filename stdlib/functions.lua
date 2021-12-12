local truthy, anselme, compare, is_of_type, identifier_pattern, format_identifier, find, get_variable, mark_as_modified

local lua_functions
lua_functions = {
	-- discard left
	["_;_(a, b)"] = {
		mode = "raw",
		value = function(a, b) return b end
	},
	["_;(a)"] = {
		mode = "raw",
		value = function(a) return { type = "nil", value = nil } end
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
				local var, vfqm = find(state.aliases, state.interpreter.global_state.variables, ffqm..".", name)
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
			local lv = l.type == "type" and l.value[1] or l
			local iv = i.type == "type" and i.value[1] or i
			lv.value[iv.value] = v
			mark_as_modified(anselme.running.state, lv.value)
			return v
		end
	},
	["()(l::list, k::string) := v"] = {
		mode = "raw",
		value = function(l, k, v)
			local lv = l.type == "type" and l.value[1] or l
			local kv = k.type == "type" and k.value[1] or k
			-- update index
			for _, x in ipairs(lv.value) do
				if x.type == "pair" and compare(x.value[1], kv) then
					x.value[2] = v
					mark_as_modified(anselme.running.state, x.value)
					return v
				end
			end
			-- new index
			table.insert(lv.value, {
				type = "pair",
				value = { kv, v }
			})
			mark_as_modified(anselme.running.state, lv.value)
			return v
		end
	},
	["()(fn::function reference, l...)"] = {
		-- bypassed, this case is manually handled in the expression interpreter
	},
	["_!(fn::function reference)"] = {
		-- bypassed, this case is manually handled in the expression interpreter
	},
	["_!(fn::variable reference)"] = {
		mode = "untyped raw",
		value = function(v)
			return get_variable(anselme.running.state, v.value)
		end
	},
	-- format
	["{}(v)"] = {
		mode = "raw",
		value = function(v)
			return v
		end
	},
	-- alias
	["alias(ref::function reference, alias::string)"] = {
		mode = "untyped raw",
		value = function(ref, alias)
			-- check identifiers
			alias = alias.value
			local aliasfqm = alias:match("^"..identifier_pattern.."$")
			if not aliasfqm then error(("%q is not a valid identifier for an alias"):format(alias)) end
			aliasfqm = format_identifier(aliasfqm)
			-- define alias
			for _, fnfqm in ipairs(ref.value) do
				local aliases = anselme.running.state.aliases
				if aliases[aliasfqm] ~= nil and aliases[aliasfqm] ~= fnfqm then
					error(("trying to define alias %q for %q, but already exist and refer to %q"):format(aliasfqm, fnfqm, aliases[alias]))
				end
				aliases[aliasfqm] = fnfqm
			end
			return { type = "nil" }
		end
	},
	["alias(ref::variable reference, alias::string)"] = {
		mode = "untyped raw",
		value = function(ref, alias)
			-- check identifiers
			alias = alias.value
			local aliasfqm = alias:match("^"..identifier_pattern.."$")
			if not aliasfqm then error(("%q is not a valid identifier for an alias"):format(alias)) end
			aliasfqm = format_identifier(aliasfqm)
			-- define alias
			local aliases = anselme.running.state.aliases
			if aliases[aliasfqm] ~= nil and aliases[aliasfqm] ~= ref.value then
				error(("trying to define alias %q for %q, but already exist and refer to %q"):format(aliasfqm, ref.value, aliases[alias]))
			end
			aliases[aliasfqm] = ref.value
			return { type = "nil" }
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
			local lv = l.type == "type" and l.value[1] or l
			table.insert(lv.value, v)
			mark_as_modified(anselme.running.state, lv.value)
			return l
		end
	},
	["insert(l::list, i::number, v)"] = {
		mode = "raw",
		value = function(l, i, v)
			local lv = l.type == "type" and l.value[1] or l
			local iv = i.type == "type" and i.value[1] or i
			table.insert(lv.value, iv.value, v)
			mark_as_modified(anselme.running.state, lv.value)
			return l
		end
	},
	["remove(l::list)"] = {
		mode = "untyped raw",
		value = function(l)
			mark_as_modified(anselme.running.state, l.value)
			return table.remove(l.value)
		end
	},
	["remove(l::list, i::number)"] = {
		mode = "untyped raw",
		value = function(l, i)
			mark_as_modified(anselme.running.state, l.value)
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
	}
}

local anselme_functions = [[
$ random(l...)
	~ l(rand(1, l!len))!

$ next(l...)
	:f = l(len(l))
	$ find first not seen(j)
		~ l(j).👁️ == 0
			~ f := l(j)
		~~ j < len(l)
			~ find first not seen(j+1)
	~ find first not seen(1)
	~ f!

$ cycle(l...)
	:f = l(1)
	$ find first smaller(j)
		~ l(j).👁️ < f.👁️
			~ f := l(j)
		~~ j < len(l)
			~ find first smaller(j+1)
	~ len(l) > 1
		~ find first smaller(2)
	~ f!
]]

local functions = {
	lua = lua_functions,
	anselme = anselme_functions
}

package.loaded[...] = functions
local icommon = require((...):gsub("stdlib%.functions$", "interpreter.common"))
truthy, compare, is_of_type, get_variable, mark_as_modified = icommon.truthy, icommon.compare, icommon.is_of_type, icommon.get_variable, icommon.mark_as_modified
local pcommon = require((...):gsub("stdlib%.functions$", "parser.common"))
identifier_pattern, format_identifier, find = pcommon.identifier_pattern, pcommon.format_identifier, pcommon.find
anselme = require((...):gsub("stdlib%.functions$", "anselme"))

return functions
