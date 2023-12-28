local ast = require("ast")
local Identifier, Number

local operator_priority = require("common").operator_priority

local ArgumentTuple
ArgumentTuple = ast.abstract.Node {
	type = "argument tuple",

	arguments = nil,

	positional = nil, -- list of expr - can be sparse! but for each hole there should be an associated named arg
	named = nil, -- { [string name] = arg1, [pos number] = string name, ... }
	assignment = nil, -- expr; always the last argument if set
	arity = 0, -- number of arguments, i.e. number of positional+named+assignment arguments

	init = function(self, ...)
		self.positional = { ... }
		self.named = {}
		self.arity = #self.positional
	end,
	add_positional = function(self, val) -- only for construction
		assert(not (self.positional[self.arity+1]) or self.assignment)
		self.arity = self.arity + 1
		self.positional[self.arity] = val
	end,
	add_named = function(self, identifier, val) -- only for construction
		local name = identifier.name
		assert(not (self.named[name] or self.assignment))
		self.arity = self.arity + 1
		self.named[name] = val
		self.named[self.arity] = name
	end,
	add_assignment = function(self, val) -- only for construction
		assert(not self.assignment)
		self.arity = self.arity + 1
		self.assignment = val
		self.format_priority = operator_priority["_=_"]
	end,

	_format = function(self, state, priority, ...)
		local l = {}
		for i=1, self.arity do
			if self.positional[i] then
				table.insert(l, self.positional[i]:format(state, operator_priority["_,_"], ...))
			elseif self.named[i] then
				local name = self.named[i]
				table.insert(l, name.."="..self.named[name]:format_right(state, operator_priority["_=_"], ...))
			else
				break
			end
		end
		local s = ("(%s)"):format(table.concat(l, ", "))
		if self.assignment then
			s = s .. (" = %s"):format(self.assignment:format_right(state, operator_priority["_=_"], ...))
		end
		return s
	end,

	traverse = function(self, fn, ...)
		for i=1, self.arity do
			if self.positional[i] then
				fn(self.positional[i], ...)
			elseif self.named[i] then
				fn(self.named[self.named[i]], ...)
			else
				fn(self.assignment, ...)
			end
		end
	end,

	_eval = function(self, state)
		local r = ArgumentTuple:new()
		for i=1, self.arity do
			if self.positional[i] then
				r:add_positional(self.positional[i]:eval(state))
			elseif self.named[i] then
				r:add_named(Identifier:new(self.named[i]), self.named[self.named[i]]:eval(state))
			else
				r:add_assignment(self.assignment:eval(state))
			end
		end
		return r
	end,

	-- recreate new argumenttuple with a first positional argument added
	with_first_argument = function(self, first)
		local r = ArgumentTuple:new()
		r:add_positional(first)
		for i=1, self.arity do
			if self.positional[i] then
				r:add_positional(self.positional[i])
			elseif self.named[i] then
				r:add_named(Identifier:new(self.named[i]), self.named[self.named[i]])
			else
				r:add_assignment(self.assignment)
			end
		end
		return r
	end,
	-- recreate new argumenttuple with an assignment argument added
	with_assignment = function(self, assignment)
		local r = ArgumentTuple:new()
		for i=1, self.arity do
			if self.positional[i] then
				r:add_positional(self.positional[i])
			elseif self.named[i] then
				r:add_named(Identifier:new(self.named[i]), self.named[self.named[i]])
			else
				r:add_assignment(self.assignment) -- welp it'll error below anyway
			end
		end
		r:add_assignment(assignment)
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
			if self.positional[i] then
				used_list[i] = true
				arg = self.positional[i]
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
			-- type check (assume ok for default values)
			if param.type_check and arg ~= param.default then
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
		for i=1, self.arity do
			if self.positional[i] then
				if not used_list[i] then
					return false, ("%sth positional argument is unused"):format(i)
				end
			elseif self.named[i] then
				if not used_named[self.named[i]] then
					return false, ("named argument %s is unused"):format(self.named[i])
				end
			else
				break
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
			if self.positional[i] then
				state.scope:define(arg.identifier:to_symbol(), self.positional[i])
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
