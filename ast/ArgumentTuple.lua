local ast = require("ast")
local Identifier, Number

local operator_priority = require("common").operator_priority

local ArgumentTuple
ArgumentTuple = ast.abstract.Node {
	type = "argument tuple",

	list = nil, -- list of expr
	named = nil, -- { [string] = expr, ... }
	assignment = nil, -- expr
	arity = 0,

	init = function(self, ...)
		self.list = { ... }
		self.named = {}
		self.arity = #self.list
	end,
	insert_positional = function(self, position, val) -- only for construction
		local l = {}
		for k, v in pairs(self.list) do
			if k >= position then l[k+1] = v
			else l[k] = v end
		end
		l[position] = val
		self.list = l
		self.arity = self.arity + 1
	end,
	set_positional = function(self, position, val) -- only for construction
		assert(not self.list[position])
		self.list[position] = val
		self.arity = self.arity + 1
	end,
	set_named = function(self, identifier, val) -- only for construction
		local name = identifier.name
		assert(not self.named[name])
		self.named[name] = val
		self.arity = self.arity + 1
	end,
	set_assignment = function(self, val) -- only for construction
		assert(not self.assignment)
		self.assignment = val
		self.arity = self.arity + 1
		self.format_priority = operator_priority["_=_"]
	end,

	_format = function(self, state, priority, ...)
		local l = {}
		for _, e in pairs(self.list) do
			table.insert(l, e:format(state, operator_priority["_,_"], ...))
		end
		for n, e in pairs(self.named) do
			table.insert(l, n.."="..e:format_right(state, operator_priority["_=_"], ...))
		end
		local s = ("(%s)"):format(table.concat(l, ", "))
		if self.assignment then
			s = s .. (" = %s"):format(self.assignment:format_right(state, operator_priority["_=_"], ...))
		end
		return s
	end,

	traverse = function(self, fn, ...)
		for _, e in pairs(self.list) do
			fn(e, ...)
		end
		for _, e in pairs(self.named) do
			fn(e, ...)
		end
		if self.assignment then
			fn(self.assignment, ...)
		end
	end,

	-- need to redefine hash to include a table.sort as pairs() in :traverse is non-deterministic
	-- as well as doesn't account for named arguments names
	_hash = function(self)
		local t = {}
		for _, e in pairs(self.list) do
			table.insert(t, e:hash())
		end
		for n, e in pairs(self.named) do
			table.insert(t, ("%s=%s"):format(n, e:hash()))
		end
		if self.assignment then
			table.insert(t, self.assignment:hash())
		end
		table.sort(t)
		return ("%s<%s>"):format(self.type, table.concat(t, ";"))
	end,

	_eval = function(self, state)
		local r = ArgumentTuple:new()
		for i, e in pairs(self.list) do
			r:set_positional(i, e:eval(state))
		end
		for n, e in pairs(self.named) do
			r:set_named(Identifier:new(n), e:eval(state))
		end
		if self.assignment then
			r:set_assignment(self.assignment:eval(state))
		end
		return r
	end,

	with_first_argument = function(self, first)
		local r = ArgumentTuple:new()
		r:set_positional(1, first)
		for i, e in pairs(self.list) do
			r:set_positional(i+1, e)
		end
		for n, e in pairs(self.named) do
			r:set_named(Identifier:new(n), e)
		end
		if self.assignment then
			r:set_assignment(self.assignment)
		end
		return r
	end,

	-- return specificity (>=0), secondary specificity (>=0)
	-- return false, failure message
	match_parameter_tuple = function(self, state, params)
		-- basic arity checks
		if self.arity > params.max_arity or self.arity < params.min_arity then
			if params.min_arity == params.max_arity then
				return false, ("expected %s arguments, received %s"):format(params.min_arity, self.arity)
			else
				return false, ("expected between %s and %s arguments, received %s"):format(params.min_arity, params.max_arity, self.arity)
			end
		end
		if params.assignment and not self.assignment then
			return false, "expected an assignment argument"
		end
		-- search for parameter -> argument match
		local specificity = 0
		local used_list = {}
		local used_named = {}
		local used_assignment = false
		for i, param in ipairs(params.list) do
			-- search in args
			local arg
			if self.list[i] then
				used_list[i] = true
				arg = self.list[i]
			elseif self.named[param.identifier.name] then
				used_named[param.identifier.name] = true
				arg = self.named[param.identifier.name]
			elseif i == params.max_arity and params.assignment and self.assignment then
				used_assignment = true
				arg = self.assignment
			elseif param.default then
				arg = param.default
			end
			-- not found
			if not arg then return false, ("missing parameter %s"):format(param.identifier:format(state)) end
			-- type check
			if param.type_check then
				local r = param.type_check:call(state, ArgumentTuple:new(arg))
				if not r:truthy() then return false, ("type check failure for parameter %s in function %s"):format(param.identifier:format(state), params:format(state)) end
				if Number:is(r) then
					specificity = specificity + r.number
				else
					specificity = specificity + 1
				end
			end
		end
		-- check for unused arguments
		for i in pairs(self.list) do
			if not used_list[i] then
				return false, ("%sth positional argument is unused"):format(i)
			end
		end
		for n in pairs(self.named) do
			if not used_named[n] then
				return false, ("named argument %s is unused"):format(n)
			end
		end
		if self.assignment and not used_assignment then
			return false, "assignment argument is unused"
		end
		-- everything is A-ok
		return specificity, params.eval_depth
	end,

	-- assume :match_parameter_tuple was already called and returned true
	bind_parameter_tuple = function(self, state, params)
		for i, arg in ipairs(params.list) do
			if self.list[i] then
				state.scope:define(arg.identifier:to_symbol(), self.list[i])
			elseif self.named[arg.identifier.name] then
				state.scope:define(arg.identifier:to_symbol(), self.named[arg.identifier.name])
			elseif i == params.max_arity and params.assignment then
				state.scope:define(arg.identifier:to_symbol(), self.assignment)
			elseif arg.default then
				state.scope:define(arg.identifier:to_symbol(), arg.default:eval(state))
			else
				error(("no argument matching parameter %q"):format(arg.identifier.name))
			end
		end
	end
}

package.loaded[...] = ArgumentTuple
Identifier, Number = ast.Identifier, ast.Number

return ArgumentTuple
