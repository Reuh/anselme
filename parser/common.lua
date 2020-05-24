local expression

local escapeCache = {}

local common
common = {
	--- valid identifier pattern
	identifier_pattern = "[^%%%/%*%+%-%(%)%!%&%|%=%$%?%>%<%:%{%}%[%]%,]+",
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
	find = function(list, namespace, name)
		local ns = common.split(namespace)
		for i=#ns, 1, -1 do
			local fqm = ("%s.%s"):format(table.concat(ns, ".", 1, i), name)
			if list[fqm] then
				return list[fqm], fqm
			end
		end
		if list[name] then
			return list[name], name
		end
		return nil, ("can't find %q in namespace %s"):format(name, namespace)
	end,
	--- transform an identifier into a clean version
	format_identifier = function(identifier, state)
		local r = identifier:gsub("[^%.]+", function(str)
			str = common.trim(str)
			return state.aliases[str] or str
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
				table.insert(l, exp)
				text = rem:match("^%s*}(.*)$")
			else
				break
			end
		end
		return l
	end,
	-- find compatible function variant
	-- * variant: if success
	-- * nil, err: if error
	find_function_variant = function(fqm, state, arg, explicit_call)
		local err = ("function %q variant not found"):format(fqm)
		local func = state.functions[fqm] or {}
		local args = arg and common.flatten_list(arg) or {}
		for _, variant in ipairs(func) do
			local ok = true
			local return_type = variant.return_type
			if variant.arity then
				local min, max
				if type(variant.arity) == "table" then
					min, max = variant.arity[1], variant.arity[2]
				else
					min, max = variant.arity, variant.arity
				end
				if #args < min or #args > max then
					if min == max then
						err = ("function %q expected %s arguments but received %s"):format(fqm, min, #args)
					else
						err = ("function %q expected between %s and %s arguments but received %s"):format(fqm, min, max, #args)
					end
					ok = false
				end
			end
			if ok and variant.check then
				local s, e = variant.check(state, args)
				if not s then
					err = e or ("function %q variant failed to check arguments"):format(fqm)
					ok = false
				end
				return_type = s == true and return_type or s
			end
			if ok and variant.types then
				for j, t in pairs(variant.types) do
					if args[j] and args[j].return_type and args[j].return_type ~= t then
						err = ("function %q expected a %s as argument %s but received a %s"):format(fqm, t, j, args[j].return_type)
						ok = false
					end
				end
			end
			if ok then
				if variant.rewrite then
					local r, e = variant.rewrite(fqm, state, arg, explicit_call)
					if not r then
						err = e
						ok = false
					end
					if ok then
						return r
					end
				else
					return {
						type = "function",
						return_type = return_type,
						name = fqm,
						explicit_call = explicit_call,
						variant = variant,
						argument = arg
					}
				end
			end
		end
		return nil, err
	end
}

package.loaded[...] = common
expression = require((...):gsub("common$", "expression"))

return common
