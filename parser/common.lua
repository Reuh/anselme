local expression

local escapeCache = {}

local common

--- rewrite name to use defined aliases (under namespace only)
-- namespace should not contain aliases
-- returns the final fqm
local replace_aliases = function(aliases, namespace, name)
	local name_list = common.split(name)
	local prefix = namespace
	for i=1, #name_list, 1 do -- search alias for each part of the fqm
		local n = ("%s%s%s"):format(prefix, prefix == "" and "" or ".", name_list[i])
		if aliases[n] then
			prefix = aliases[n]
		else
			prefix = n
		end
	end
	return prefix
end

local disallowed_set = ("~`^+-=<>/[]*{}|\\_!?,;:()\"@&$#%"):gsub("[^%w]", "%%%1")

common = {
	--- valid identifier pattern
	identifier_pattern = "%s*[^0-9%s"..disallowed_set.."][^"..disallowed_set.."]*",
	-- names allowed for a function that aren't valid identifiers, mainly for overloading operators
	special_functions_names = {
		-- operators not included here and why:
		-- * assignment operators (:=, +=, -=, //=, /=, *=, %=, ^=): handled with its own syntax (function assignment)
		-- * list operator (,): is used when calling every functions, sounds like more trouble than it's worth
		-- * |, &, ~? and ~ operators: are lazy and don't behave like regular functions
		-- * # operator: need to set tag state _before_ evaluating the left arg

		-- prefix unop
		"-_", "!_",
		"&_",
		-- binop
		"_;_",
		"_!=_", "_==_", "_>=_", "_<=_", "_<_", "_>_",
		"_+_", "_-_",
		"_*_", "_//_", "_/_", "_%_",
		"_::_", "_=_",
		"_^_",
		"_._", "_!_",
		-- suffix unop
		"_;",
		"_!",
		-- special
		"()",
		"{}"
	},
	-- escapement code and their value in strings
	-- I don't think there's a point in supporting form feed, carriage return, and other printer and terminal related codes
	string_escapes = {
		-- usual escape codes
		["\\\\"] = "\\",
		["\\\""] = "\"",
		["\\n"] = "\n",
		["\\t"] = "\t",
		-- string interpolation
		["\\{"] = "{",
		-- subtext
		["\\["] = "[",
		-- end of text line expressions
		["\\~"] = "~",
		["\\#"] = "#",
		-- decorators
		["\\$"] = "$"
	},
	-- list of possible injections and their associated name in vm.state.inject
	injections = {
		["function start"] = "function_start", ["function end"] = "function_end", ["function return"] = "function_return",
		["scoped function start"] = "scoped_function_start", ["scoped function end"] = "scoped_function_end", ["scoped function return"] = "scoped_function_return",
		["checkpoint start"] = "checkpoint_start", ["checkpoint end"] = "checkpoint_end"
	},
	--- escape a string to be used as an exact match pattern
	escape = function(str)
		if not escapeCache[str] then
			escapeCache[str] = str:gsub("[^%w]", "%%%1")
		end
		return escapeCache[str]
	end,
	--- trim a string by removing whitespace at the start and end
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
			local fqm = replace_aliases(aliases, current_namespace, name)
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
			local fqm = replace_aliases(aliases, current_namespace, name)
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
			table.insert(t, 1, list.right)
			common.flatten_list(list.left, t)
		else
			table.insert(t, 1, list)
		end
		return t
	end,
	-- parse interpolated expressions in a text
	-- type sets the type of the returned expression (text is in text field)
	-- allow_subtext (bool) to enable or not [subtext] support
	-- if allow_binops is given, if one of the caracters of allow_binops appear unescaped in the text, it will interpreter a binary operator expression
	-- * returns an expression with given type (string by default) and as a value a list of strings and expressions (text elements)
	-- * if allow_binops is given, also returns remaining string (if the right expression stop before the end of the text)
	-- * nil, err: in case of error
	parse_text = function(text, state, namespace, type, allow_binops, allow_subtext, in_subtext)
		local l = {}
		local text_exp = { type = type, text = l }
		local delimiters = ""
		if allow_binops then
			delimiters = allow_binops
		end
		if allow_subtext then
			delimiters = delimiters .. "%["
		end
		if in_subtext then
			delimiters = delimiters .. "%]"
		end
		while text:match(("[^{%s]+"):format(delimiters)) do
			local t, r = text:match(("^([^{%s]*)(.-)$"):format(delimiters))
			-- text
			if t ~= "" then
				-- handle \{ and binop escape: skip to next { until it's not escaped
				while t:match("\\$") and r:match(("^[{%s]"):format(delimiters)) do
					local t2, r2 = r:match(("^([{%s][^{%s]*)(.-)$"):format(delimiters, delimiters))
					t = t .. t2 -- don't need to remove \ as it will be stripped with other escapes codes 3 lines later
					r = r2
				end
				-- replace escape codes
				local escaped = t:gsub("\\.", common.string_escapes)
				table.insert(l, escaped)
			end
			-- expr
			if r:match("^{") then
				local exp, rem = expression(r:gsub("^{", ""), state, namespace)
				if not exp then return nil, rem end
				if not rem:match("^%s*}") then return nil, ("expected closing } at end of expression before %q"):format(rem) end
				-- wrap in format() call
				local variant, err = common.find_function(state, namespace, "{}", { type = "parentheses", expression = exp }, true)
				if not variant then return variant, err end
				-- add to text
				table.insert(l, variant)
				text = rem:match("^%s*}(.*)$")
			-- start subtext
			elseif allow_subtext and r:match("^%[") then
				local exp, rem = common.parse_text(r:gsub("^%[", ""), state, namespace, "text", allow_binops, allow_subtext, true)
				if not exp then return nil, rem end
				if not rem:match("^%]") then return nil, ("expected closing ] at end of subtext before %q"):format(rem) end
				-- add to text
				table.insert(l, exp)
				text = rem:match("^%](.*)$")
			-- end subtext
			elseif in_subtext and r:match("^%]") then
				if allow_binops then
					return text_exp, r
				else
					return text_exp
				end
			-- binop expression at the end of the text
			elseif allow_binops and r:match(("^[%s]"):format(allow_binops)) then
				local exp, rem = expression(r, state, namespace, nil, text_exp)
				if not exp then return nil, rem end
				return exp, rem
			elseif r == "" then
				break
			else
				error(("unexpected %q at end of text or string"):format(r))
			end
		end
		if allow_binops then
			return text_exp, ""
		else
			return text_exp
		end
	end,
	-- find a list of compatible function variants from a fully qualified name
	-- this functions does not guarantee that the returned variants are fully compatible with the given arguments and only performs a pre-selection without the ones which definitely aren't
	-- * list of compatible variants: if success
	-- * nil, err: if error
	find_function_variant_from_fqm = function(fqm, state, arg)
		local err = ("compatible function %q variant not found"):format(fqm)
		local func = state.functions[fqm]
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
	find_function = function(state, namespace, name, arg, paren_call, implicit_call)
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
				type = "function call",
				called_name = name, -- name of the called function
				paren_call = paren_call, -- was call with parantheses?
				implicit_call = implicit_call, -- was call implicitely (no ! or parentheses)?
				variants = variants, -- list of potential variants
				argument = { -- wrap everything in a list literal to simplify later things (otherwise may be nil, single value, list constructor)
					type = "map_brackets",
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
			if p.type_constraint then
				sig = sig .. "::" .. p.type_constraint
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
