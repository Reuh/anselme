local truthy, eval, find_function_variant, anselme

local function rewrite_assignement(fqm, state, arg, explicit_call)
	local op, e = find_function_variant(fqm:match("^(.*)%=$"), state, arg, true)
	if not op then return op, e end
	local ass, err = find_function_variant(":=", state, { type = "list", left = arg.left, right = op }, explicit_call)
	if not ass then return ass, err end
	return ass
end

local function compare(a, b)
	if a.type ~= b.type then
		return false
	end
	if a.type == "pair" then
		return compare(a.value[1], b.value[1]) and compare(a.value[2], b.value[2])
	elseif a.type == "list" then
		if #a.value ~= #b.value then
			return false
		end
		for i, v in ipairs(a.value) do
			if not compare(v, b.value[i]) then
				return false
			end
		end
		return true
	else
		return a.value == b.value
	end
end

local functions
functions = {
	-- discard left
	[";"] = {
		{
			arity = 2, mode = "raw",
			value = function(a, b) return b end
		}
	},
	-- assignement
	[":="] = {
		{
			arity = 2, mode = "custom",
			check = function(state, args)
				local left, right = args[1], args[2]
				if left.type ~= "variable" then
					return nil, ("assignement expected a variable as a left argument but received a %s"):format(left.type)
				end
				if left.return_type and right.return_type and left.return_type ~= right.return_type then
					return nil, ("trying to assign a %s value to a %s variable"):format(right.return_type, left.return_type)
				end
				return right.return_type or true
			end,
			value = function(state, exp)
				local arg = exp.argument
				local name = arg.left.name
				local right, righte = eval(state, arg.right)
				if not right then return right, righte end
				state.variables[name] = right
				return right
			end
		}
	},
	["+="] = {
		{ rewrite = rewrite_assignement }
	},
	["-="] = {
		{ rewrite = rewrite_assignement }
	},
	["*="] = {
		{ rewrite = rewrite_assignement }
	},
	["/="] = {
		{ rewrite = rewrite_assignement }
	},
	["//="] = {
		{ rewrite = rewrite_assignement }
	},
	["%="] = {
		{ rewrite = rewrite_assignement }
	},
	["^="] = {
		{ rewrite = rewrite_assignement }
	},
	-- comparaison
	["="] = {
		{
			arity = 2, return_type = "number", mode = "raw",
			value = function(a, b)
				return {
					type = "number",
					value = compare(a, b) and 1 or 0
				}
			end
		}
	},
	["!="] = {
		{
			arity = 2, return_type = "number", mode = "raw",
			value = function(a, b)
				return {
					type = "number",
					value = compare(a, b) and 0 or 1
				}
			end
		}
	},
	[">"] = {
		{
			arity = 2, types = { "number", "number" }, return_type = "number",
			value = function(a, b) return a > b end
		}
	},
	["<"] = {
		{
			arity = 2, types = { "number", "number" }, return_type = "number",
			value = function(a, b) return a < b end
		}
	},
	[">="] = {
		{
			arity = 2, types = { "number", "number" }, return_type = "number",
			value = function(a, b) return a >= b end
		}
	},
	["<="] = {
		{
			arity = 2, types = { "number", "number" }, return_type = "number",
			value = function(a, b) return a <= b end
		}
	},
	-- arithmetic
	["+"] = {
		{
			arity = 2,
			value = function(a, b)
				if type(a) == "string" then
					return a .. b
				else
					return a + b
				end
			end
		}
	},
	["-"] = {
		{
			arity = 2, types = { "number", "number" }, return_type = "number",
			value = function(a, b) return a - b end
		},
		{
			arity = 1, types = { "number" }, return_type = "number",
			value = function(a) return -a end
		}
	},
	["*"] = {
		{
			arity = 2, types = { "number", "number" }, return_type = "number",
			value = function(a, b) return a * b end
		}
	},
	["/"] = {
		{
			arity = 2, types = { "number", "number" }, return_type = "number",
			value = function(a, b) return a / b end
		}
	},
	["//"] = {
		{
			arity = 2, types = { "number", "number" }, return_type = "number",
			value = function(a, b) return math.floor(a / b) end
		}
	},
	["^"] = {
		{
			arity = 2, types = { "number", "number" }, return_type = "number",
			value = function(a, b) return a ^ b end
		}
	},
	-- boolean
	["!"] = {
		{
			arity = 1, return_type = "number", mode = "raw",
			value = function(a)
				return {
					type = "number",
					value = truthy(a) and 0 or 1
				}
			end
		}
	},
	["&"] = {
		{
			arity = 2, return_type = "number", mode = "custom",
			value = function(state, exp)
				local arg = exp.argument
				local left, lefte = eval(state, arg.left)
				if not left then return left, lefte end
				if truthy(left) then
					local right, righte = eval(state, arg.right)
					if not right then return right, righte end
					if truthy(right) then
						return {
							type = "number",
							value = 1
						}
					end
				end
				return {
					type = "number",
					value = 0
				}
			end
		}
	},
	["|"] = {
		{
			arity = 2, return_type = "number", mode = "custom",
			value = function(state, exp)
				local arg = exp.argument
				local left, lefte = eval(state, arg.left)
				if not left then return left, lefte end
				if truthy(left) then
					return {
						type = "number",
						value = 1
					}
				end
				local right, righte = eval(state, arg.right)
				if not right then return right, righte end
				return {
					type = "number",
					value = truthy(right) and 1 or 0
				}
			end
		}
	},
	-- pair
	[":"] = {
		{
			arity = 2, return_type = "pair", mode = "raw",
			value = function(a, b)
				return {
					type = "pair",
					value = { a, b }
				}
			end
		}
	},
	-- index
	["("] = {
		{
			arity = 2, types = { "list", "number" }, mode = "raw",
			value = function(a, b)
				return a.value[b.value] or { type = "nil", value = nil }
			end
		}
	},
	-- list methods
	len = {
		{
			arity = 1, types = { "list" }, return_type = "number", mode = "raw", -- raw to count pairs in the list
			value = function(a)
				return {
					type = "number",
					value = #a.value
				}
			end
		}
	},
	insert = {
		{
			arity = 2, types = { "list" }, return_type = "list", mode = "raw",
			value = function(a, v)
				table.insert(a.value, v)
				return a
			end
		},
		{
			arity = 3, types = { "list", "number" }, return_type = "list", mode = "raw",
			value = function(a, k, v)
				table.insert(a.value, k.value, v)
				return a
			end
		}
	},
	remove = {
		{
			arity = 1, types = { "list" }, return_type = "list", mode = "raw",
			value = function(a)
				table.remove(a.value)
				return a
			end
		},
		{
			arity = 2, types = { "list", "number" }, return_type = "list", mode = "raw",
			value = function(a, k)
				table.remove(a.value, k.value)
				return a
			end
		}
	},
	find = {
		{
			arity = 2, types = { "list" }, return_type = "number", mode = "raw",
			value = function(a, v)
				for i, x in ipairs(v.value) do
					if compare(v, x) then
						return i
					end
				end
				return 0
			end
		},
	},
	-- other methods
	rand = {
		{
			arity = 0, return_type = "number",
			value = function()
				return math.random()
			end
		},
		{
			arity = 1, types = { "number" }, return_type = "number",
			value = function(a)
				return math.random(a)
			end
		},
		{
			arity = 2, types = { "number", "number" }, return_type = "number",
			value = function(a, b)
				return math.random(a, b)
			end
		}
	},
	cycle = function(...)
		local l = {...}
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
	random = function(...)
		local l = {...}
		return anselme.running:run(l[math.random(1, #l)], anselme.running:current_namespace())
	end,
	next = function(...)
		local l = {...}
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
truthy = require((...):gsub("stdlib%.functions$", "interpreter.common")).truthy
eval = require((...):gsub("stdlib%.functions$", "interpreter.expression"))
find_function_variant = require((...):gsub("stdlib%.functions$", "parser.common")).find_function_variant
anselme = require((...):gsub("stdlib%.functions$", "anselme"))

return functions
