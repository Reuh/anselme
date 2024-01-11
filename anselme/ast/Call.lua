local ast = require("anselme.ast")
local Identifier, Quote, ArgumentTuple

local regular_operators = require("anselme.common").regular_operators
local operator_priority = require("anselme.common").operator_priority

local function reverse(t, fmt)
	for _, v in ipairs(t) do t[fmt:format(v[1])] = v[2] end
	return t
end
local infix = reverse(regular_operators.infixes, "_%s_")
local prefix = reverse(regular_operators.prefixes, "%s_")
local suffix = reverse(regular_operators.suffixes, "_%s")

local Call

Call = ast.abstract.Node {
	type = "call",

	func = nil,
	arguments = nil, -- ArgumentTuple

	init = function(self, func, arguments)
		self.func = func
		self.arguments = arguments
	end,
	from_operator = function(self, operator, left, right)
		return Call:new(Identifier:new(operator), ArgumentTuple:new(left, right))
	end,

	_format = function(self, ...)
		if self.arguments.arity == 0 then
			if Identifier:is(self.func) and self.func.name == "_" then
				return "_" -- the _ identifier is automatically re-wrapped in a Call when it appears
			end
			local func = self.func:format(...)
			return func.."!"
		else
			if Identifier:is(self.func) then
				local name, arity = self.func.name, self.arguments.arity
				if infix[name] and arity == 2 then
					local left = self.arguments.positional[1]:format(...)
					local right = self.arguments.positional[2]:format_right(...)
					return ("%s %s %s"):format(left, name:match("^_(.*)_$"), right)
				elseif prefix[name] and arity == 1 then
					local right = self.arguments.positional[1]:format_right(...)
					return ("%s%s"):format(name:match("^(.*)_$"), right)
				elseif suffix[name] and arity == 1 then
					local left = self.arguments.positional[1]:format(...)
					return ("%s%s"):format(left, name:match("^_(.*)$"))
				end
			end
			return self.func:format(...)..self.arguments:format(...) -- no need for format_right, we already handle the assignment priority here
		end
	end,
	_format_priority = function(self)
		if Identifier:is(self.func) then
			local name, arity = self.func.name, self.arguments.arity
			if infix[name] and arity == 2 then
				return infix[name]
			elseif prefix[name] and arity == 1 then
				return prefix[name]
			elseif suffix[name] and arity == 1 then
				return suffix[name]
			end
		end
		if self.arguments.assignment then
			return operator_priority["_=_"]
		end
		return operator_priority["_!"]
	end,

	is_infix = function(self, operator)
		return Identifier:is(self.func) and self.func.name == operator
			and self.arguments.arity == 2 and #self.arguments.positional == 2
	end,
	is_simple_assignment = function(self)
		return self:is_infix("_=_") and Quote:is(self.arguments.positional[1]) and Identifier:is(self.arguments.positional[1].expression)
	end,

	traverse = function(self, fn, ...)
		fn(self.func, ...)
		fn(self.arguments, ...)
	end,

	_eval = function(self, state)
		local func = self.func:eval(state)
		local arguments = self.arguments:eval(state)

		return func:call(state, arguments)
	end
}

package.loaded[...] = Call
Identifier, Quote, ArgumentTuple = ast.Identifier, ast.Quote, ast.ArgumentTuple

return Call
