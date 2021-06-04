local expression

local escapeCache = {}

local common

--- rewrite name to use defined aliases (under namespace only)
-- namespace should not contain aliases
local replace_aliases = function(aliases, namespace, name)
	namespace = namespace == "" and "" or namespace.."."
	local name_list = common.split(name)
	for i=1, #name_list, 1 do
		local n = ("%s%s"):format(namespace, table.concat(name_list, ".", 1, i))
		if aliases[n] then
			name_list[i] = aliases[n]:match("[^%.]+$")
		end
	end
	return table.concat(name_list, ".")
end

local disallowed_set = ("~`^+-=<>/[]*{}|\\_!?,;:()\"@&$#%"):gsub("[^%w]", "%%%1")

common = {
	--- valid identifier pattern
	identifier_pattern = "%s*[^0-9%s"..disallowed_set.."][^"..disallowed_set.."]*",
	-- names allowed for a function that aren't valide identifiers, mainly for overloading operators
	special_functions_names = {
		-- operators not included here:
		-- * assignment operators (:=, +=, -=, //=, /=, *=, %=, ^=): handled with its own syntax (function assignment)
		-- * list operator (,): is used when calling every functions, sounds like more trouble than it's worth
		-- * | and & oprators: are lazy and don't behave like regular functions
		-- * . operator: don't behave like regular functions either
		";",
		"!=", "==", ">=", "<=", "<", ">",
		"+", "-",
		"*", "//", "/", "%",
		"::", ":",
		"!",
		"^",
		"()", "{}"
	},
	-- escapement code and their value in strings
	-- I don't think there's a point in supporting form feed, carriage return, and other printer and terminal related codes
	string_escapes = {
		["\\\\"] = "\\",
		["\\\""] = "\"",
		["\\n"] = "\n",
		["\\t"] = "\t"
	},
	--- escape a string to be used as an exact match pattern
	escape = function(str)
		if not escapeCache[str] then
			escapeCache[str] = str:gsub("[^%w]", "%%%1")
		end
		return escapeCache[str]
	end,
	--- trim a string
	trim = function(str)
		return str:match("^%s*(.-)%s*$")
	end,
	--- split a string separated by .
	split = function(str)
		local address = {}
		for name in str:gmatch("[^%.]+") do
			table.insert(address, name)
		end
		return address
	end,
	--- find a variable/function in a list, going up through the namespace hierarchy
	-- will apply aliases
	-- returns value, fqm in case of success
	-- returns nil, err in case of error
	find = function(aliases, list, namespace, name)
		local ns = common.split(namespace)
		for i=#ns, 1, -1 do
			local current_namespace = table.concat(ns, ".", 1, i)
			local fqm = ("%s.%s"):format(current_namespace, replace_aliases(aliases, current_namespace, name))
			if list[fqm] then
				return list[fqm], fqm
			end
		end
		-- root namespace
		name = replace_aliases(aliases, "", name)
		if list[name] then
			return list[name], name
		end
		return nil, ("can't find %q in namespace %s"):format(name, namespace)
	end,
	--- same as find, but return a list of every encoutered possibility
	-- returns a list of fqm
	find_all = function(aliases, list, namespace, name)
		local l = {}
		local ns = common.split(namespace)
		for i=#ns, 1, -1 do
			local current_namespace = table.concat(ns, ".", 1, i)
			local fqm = ("%s.%s"):format(current_namespace, replace_aliases(aliases, current_namespace, name))
			if list[fqm] then
				table.insert(l, fqm)
			end
		end
		-- root namespace
		name = replace_aliases(aliases, "", name)
		if list[name] then
			table.insert(l, name)
		end
		return l
	end,
	--- transform an identifier into a clean version (trim each part)
	format_identifier = function(identifier)
		local r = identifier:gsub("[^%.]+", function(str)
			return common.trim(str)
		end)
		return r
	end,
	--- flatten a nested list expression into a list of expressions
	flatten_list = function(list, t)
		t = t or {}
		if list.type == "list" then
			table.insert(t, list.left)
			common.flatten_list(list.right, t)
		else
			table.insert(t, list)
		end
		return t
	end,
	-- parse interpolated expressions in a text
	-- * list of strings and expressions
	-- * nil, err: in case of error
	parse_text = function(text, state, namespace)
		local l = {}
		while text:match("[^%{]+") do
			local t, e = text:match("^([^%{]*)(.-)$")
			-- text
			if t ~= "" then table.insert(l, t) end
			-- expr
			if e:match("^{") then
				local exp, rem = expression(e:gsub("^{", ""), state, namespace)
				if not exp then return nil, rem end
				if not rem:match("^%s*}") then return nil, ("expected closing } at end of expression before %q"):format(rem) end
				-- wrap in format() call
				local variant, err = common.find_function_variant(state, namespace, "{}", exp, true)
				if not variant then return variant, err end
				-- add to text
				table.insert(l, variant)
				text = rem:match("^%s*}(.*)$")
			else
				break
			end
		end
		return l
	end,
	-- find compatible function variants from a fully qualified name
	-- this functions does not guarantee that functions are fully compatible with the given arguments and only performs a pre-selection without the ones which definitely aren't
	-- * list of variants: if success
	-- * nil, err: if error
	find_function_variant_from_fqm = function(fqm, state, arg)
		local err = ("compatible function %q variant not found"):format(fqm)
		local func = state.functions[fqm] or {}
		local args = arg and common.flatten_list(arg) or {}
		local variants = {}
		for _, variant in ipairs(func) do
			local ok = true
			-- arity check
			-- note: because named args can't be predicted in advance (pairs need to be evaluated), this arity check isn't enough to guarantee a compatible arity
			-- (e.g., if there's 3 required args but only provide 3 optional arg in a call, will pass)
			local min, max = variant.arity[1], variant.arity[2]
			if #args < min or #args > max then
				if min == max then
					err = ("function %q expected %s arguments but received %s"):format(fqm, min, #args)
				else
					err = ("function %q expected between %s and %s arguments but received %s"):format(fqm, min, max, #args)
				end
				ok = false
			end
			-- done
			if ok then
				table.insert(variants, variant)
			end
		end
		if #variants > 0 then
			return variants
		else
			return nil, err
		end
	end,
	--- same as find_function_variant_from_fqm, but will search every function from the current namespace and up using find
	-- returns directly a function expression in case of success
	-- return nil, err otherwise
	find_function_variant = function(state, namespace, name, arg, explicit_call)
		local variants = {}
		local err = ("compatible function %q variant not found"):format(name)
		local l = common.find_all(state.aliases, state.functions, namespace, name)
		for _, ffqm in ipairs(l) do
			local found
			found, err = common.find_function_variant_from_fqm(ffqm, state, arg)
			if found then
				for _, v in ipairs(found) do
					table.insert(variants, v)
				end
			end
		end
		if #variants > 0 then
			return {
				type = "function",
				called_name = name,
				explicit_call = explicit_call,
				variants = variants,
				argument = { -- wrap everything in a list literal to simplify later things (otherwise may be nil, single value, list constructor)
					type = "list_brackets",
					expression = arg
				}
			}
		else
			return nil, err -- returns last error
		end
	end,
	-- returns the function's signature text
	signature = function(fn)
		if fn.signature then return fn.signature end
		local signature
		local function make_param_signature(p)
			local sig = p.name
			if p.vararg then
				sig = sig .. "..."
			end
			if p.alias then
				sig = sig .. ":" .. p.alias
			end
			if p.type_annotation then
				sig = sig .. "::" .. p.type_annotation
			end
			if p.default then
				sig = sig .. "=" .. p.default
			end
			return sig
		end
		local arg_sig = {}
		for j, p in ipairs(fn.params) do
			arg_sig[j] = make_param_signature(p)
		end
		if fn.assignment then
			signature = ("%s(%s) := %s"):format(fn.name, table.concat(arg_sig, ", "), make_param_signature(fn.assignment))
		else
			signature = ("%s(%s)"):format(fn.name, table.concat(arg_sig, ", "))
		end
		return signature
	end,
	-- same as signature, format the signature for displaying to the user and add some debug information
	pretty_signature = function(fn)
		return ("%s (at %s)"):format(common.signature(fn), fn.source)
	end,
}

package.loaded[...] = common
expression = require((...):gsub("common$", "expression"))

return common
