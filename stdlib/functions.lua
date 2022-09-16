local truthy, anselme, compare, is_of_type, identifier_pattern, format_identifier, find, get_variable, mark_as_modified, set_variable, check_mutable, copy, mark_constant, hash

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
	["_%_(a::number, b::number)"] = function(a, b) return a % b end,
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
	["_=_(a, b)"] = {
		mode = "raw",
		value = function(a, b)
			return {
				type = "pair",
				value = { a, b }
			}
		end
	},
	["_:_(a, b)"] = {
		mode = "raw",
		value = function(a, b)
			return {
				type = "pair",
				value = { a, b }
			}
		end
	},
	-- annotate
	["_::_(a, b)"] = {
		mode = "raw",
		value = function(a, b)
			return {
				type = "annotated",
				value = { a, b }
			}
		end
	},
	-- namespace
	["_._(r::function reference, name::string)"] = {
		mode = "unannotated raw",
		value = function(r, n)
			local state = anselme.running.state
			local rval = r.value
			local name = n.value
			for _, ffqm in ipairs(rval) do
				local var, vfqm = find(state.aliases, state.interpreter.global_state.variables, "", ffqm.."."..name)
				if var then
					return get_variable(state, vfqm)
				end
			end
			for _, ffqm in ipairs(rval) do
				local fn, fnfqm = find(state.aliases, state.functions, "", ffqm.."."..name)
				if fn then
					return {
						type = "function reference",
						value = { fnfqm }
					}
				end
			end
			return nil, ("can't find variable %q in function reference (searched in namespaces: %s)"):format(name, table.concat(rval, ", "))
		end
	},
	["_._(r::function reference, name::string) := v"] = {
		mode = "unannotated raw",
		value = function(r, n, v)
			local state = anselme.running.state
			local rval = r.value
			local name = n.value
			for _, ffqm in ipairs(rval) do
				local var, vfqm = find(state.aliases, state.interpreter.global_state.variables, "", ffqm.."."..name)
				if var then
					local s, e = set_variable(state, vfqm, v)
					if not s then return nil, e end
					return v
				end
			end
			return nil, ("can't find variable %q in function reference (searched in namespaces: %s)"):format(name, table.concat(rval, ", "))
		end
	},
	["_._(r::object, name::string)"] = {
		mode = "unannotated raw",
		value = function(r, n)
			local state = anselme.running.state
			local obj = r.value
			local name = n.value
			-- attribute already present in object
			local var = find(state.aliases, obj.attributes, "", obj.class.."."..name)
			if var then return var end
			-- search for attribute in base class
			local cvar, cvfqm = find(state.aliases, state.interpreter.global_state.variables, "", obj.class.."."..name)
			if cvar then return get_variable(state, cvfqm) end
			-- search for method in base class
			local fn, fnfqm = find(state.aliases, state.functions, "", obj.class.."."..name)
			if fn then
				return {
					type = "function reference",
					value = { fnfqm }
				}
			end
			return nil, ("can't find attribute %q in object"):format(name)
		end
	},
	["_._(r::object, name::string) := v"] = {
		mode = "unannotated raw",
		value = function(r, n, v)
			local state = anselme.running.state
			local obj = r.value
			local name = n.value
			-- check constant state
			if r.constant then
				return nil, "can't change the value of an attribute of a constant object"
			end
			if not check_mutable(state, obj.class.."."..name) then
				return nil, "can't change the value of a constant attribute"
			end
			-- attribute already present in object
			local var, vfqm = find(state.aliases, obj.attributes, "", obj.class.."."..name)
			if var then
				obj.attributes[vfqm] = v
				mark_as_modified(anselme.running.state, obj.attributes)
				return v
			end
			-- search for attribute in base class
			local cvar, cvfqm = find(state.aliases, state.interpreter.global_state.variables, "", obj.class.."."..name)
			if cvar then
				obj.attributes[cvfqm] = v
				mark_as_modified(anselme.running.state, obj.attributes)
				return v
			end
			return nil, ("can't find attribute %q in object"):format(name)
		end
	},
	-- index
	["()(l::list, i::number)"] = {
		mode = "unannotated raw",
		value = function(l, i)
			local index = i.value
			if index < 0 then index = #l.value + 1 + index end
			if index > #l.value or index == 0 then return nil, "list index out of bounds" end
			return l.value[index] or { type = "nil", value = nil }
		end
	},
	["()(l::map, k)"] = {
		mode = "raw",
		value = function(l, i)
			local lv = l.type == "annotated" and l.value[1] or l
			local h, err = hash(i)
			if not h then return nil, err end
			local v = lv.value[h]
			if v then
				return v[2]
			else
				return { type = "nil", value = nil }
			end
		end
	},
	-- index assignment
	["()(l::list, i::number) := v"] = {
		mode = "raw",
		value = function(l, i, v)
			local lv = l.type == "annotated" and l.value[1] or l
			local iv = i.type == "annotated" and i.value[1] or i
			if lv.constant then return nil, "can't change the contents of a constant list" end
			local index = iv.value
			if index < 0 then index = #lv.value + 1 + index end
			if index > #lv.value + 1 or index == 0 then return nil, "list assignment index out of bounds" end
			lv.value[index] = v
			mark_as_modified(anselme.running.state, lv.value)
			return v
		end
	},
	["()(l::map, k) := v::nil"] = {
		mode = "raw",
		value = function(l, k, v)
			local lv = l.type == "annotated" and l.value[1] or l
			if lv.constant then return nil, "can't change the contents of a constant map" end
			local h, err = hash(k)
			if not h then return nil, err end
			lv.value[h] = nil
			mark_as_modified(anselme.running.state, lv.value)
			return v
		end
	},
	["()(l::map, k) := v"] = {
		mode = "raw",
		value = function(l, k, v)
			local lv = l.type == "annotated" and l.value[1] or l
			if lv.constant then return nil, "can't change the contents of a constant map" end
			local h, err = hash(k)
			if not h then return nil, err end
			lv.value[h] = { k, v }
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
		mode = "unannotated raw",
		value = function(v)
			return get_variable(anselme.running.state, v.value)
		end
	},
	["&_(v::variable reference)"] = {
		mode = "unannotated raw",
		value = function(v) return v end
	},
	["&_(fn::function reference)"] = {
		mode = "unannotated raw",
		value = function(v) return v end
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
		mode = "unannotated raw",
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
		mode = "unannotated raw",
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
		mode = "unannotated raw",
		value = function(a)
			return a.value[1]
		end
	},
	["value(p::pair)"] = {
		mode = "unannotated raw",
		value = function(a)
			return a.value[2]
		end
	},
	-- list methods
	["len(l::list)"] = {
		mode = "unannotated raw", -- raw to count pairs in the list
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
			local lv = l.type == "annotated" and l.value[1] or l
			if lv.constant then return nil, "can't insert values into a constant list" end
			table.insert(lv.value, v)
			mark_as_modified(anselme.running.state, lv.value)
			return l
		end
	},
	["insert(l::list, i::number, v)"] = {
		mode = "raw",
		value = function(l, i, v)
			local lv = l.type == "annotated" and l.value[1] or l
			local iv = i.type == "annotated" and i.value[1] or i
			if lv.constant then return nil, "can't insert values into a constant list" end
			table.insert(lv.value, iv.value, v)
			mark_as_modified(anselme.running.state, lv.value)
			return l
		end
	},
	["remove(l::list)"] = {
		mode = "unannotated raw",
		value = function(l)
			if l.constant then return nil, "can't remove values from a constant list" end
			mark_as_modified(anselme.running.state, l.value)
			return table.remove(l.value)
		end
	},
	["remove(l::list, i::number)"] = {
		mode = "unannotated raw",
		value = function(l, i)
			if l.constant then return nil, "can't remove values from a constant list" end
			mark_as_modified(anselme.running.state, l.value)
			return table.remove(l.value, i.value)
		end
	},
	["find(l::list, v)"] = {
		mode = "raw",
		value = function(l, v)
			local lv = l.type == "annotated" and l.value[1] or l
			for i, x in ipairs(lv.value) do
				if compare(x, v) then
					return i
				end
			end
			return { type = "number", value = 0 }
		end
	},
	-- string
	["len(s::string)"] = function(s)
		return require("utf8").len(s)
	end,
	-- other methods
	["error(m::string)"] = function(m) error(m, 0) end,
	["rand()"] = function() return math.random() end,
	["rand(a::number)"] = function(a) return math.random(a) end,
	["rand(a::number, b::number)"] = function(a, b) return math.random(a, b) end,
	["unannotated(v)"] = {
		mode = "raw",
		value = function(v)
			if v.type == "annotated" then
				return v.value[1]
			else
				return v
			end
		end
	},
	["type(v)"] = {
		mode = "unannotated raw",
		value = function(v)
			return {
				type = "string",
				value = v.type
			}
		end
	},
	["annotation(v::annotated)"] = {
		mode = "raw",
		value = function(v)
			return v.value[2]
		end
	},
	["is a(v, t)"] = {
		mode = "raw",
		value = function(v, t)
			return {
				type = "number",
				value = is_of_type(v, t) or 0
			}
		end
	},
	["constant(v)"] = {
		mode = "raw",
		value = function(v)
			local c = copy(v)
			mark_constant(c)
			return c
		end
	}
}

local anselme_functions = [[
:$ random(l...)
	~ l(rand(1, l!len))!

:$ next(l...)
	:j = 0
	~? j += 1; j < len(l) & l(j).👁️ != 0
	~ l(j)!

:$ cycle(l...)
	:f = l(1)
	:j = 1
	~? j += 1; j <= len(l) & !((f := l(j); 1) ~ l(j).👁️ < f.👁️)
	~ f!

:$ concat(l::list, separator=""::string)
	:r = ""
	:j = 0
	~? j += 1; j <= len(l)
		~ r += "{l(j)}"
		~ j < len(l)
			~ r += separator
	@r
]]

local functions = {
	lua = lua_functions,
	anselme = anselme_functions
}

package.loaded[...] = functions
local icommon = require((...):gsub("stdlib%.functions$", "interpreter.common"))
truthy, compare, is_of_type, get_variable, mark_as_modified, set_variable, check_mutable, mark_constant, hash = icommon.truthy, icommon.compare, icommon.is_of_type, icommon.get_variable, icommon.mark_as_modified, icommon.set_variable, icommon.check_mutable, icommon.mark_constant, icommon.hash
local pcommon = require((...):gsub("stdlib%.functions$", "parser.common"))
identifier_pattern, format_identifier, find = pcommon.identifier_pattern, pcommon.format_identifier, pcommon.find
anselme = require((...):gsub("stdlib%.functions$", "anselme"))
copy = require((...):gsub("stdlib%.functions$", "common")).copy

return functions
