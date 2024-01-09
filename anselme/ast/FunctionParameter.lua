local ast = require("anselme.ast")
local operator_priority = require("anselme.common").operator_priority

local FunctionParameter
FunctionParameter = ast.abstract.Node {
	type = "function parameter",

	identifier = nil,
	default = nil, -- can be nil
	value_check = nil, -- can be nil

	init = function(self, identifier, default, value_check)
		self.identifier = identifier
		self.default = default
		self.value_check = value_check
	end,

	_format = function(self, state, prio, ...)
		local s = self.identifier:format(state, prio, ...)
		if self.value_check then
			s = s .. "::" .. self.value_check:format_right(state, operator_priority["_::_"], ...)
		end
		if self.default then
			s = s .. "=" .. self.default:format_right(state, operator_priority["_=_"], ...)
		end
		return s
	end,
	_format_priority = function(self)
		if self.default then
			return operator_priority["_=_"]
		elseif self.value_check then -- value_check has higher prio than assignment in any case
			return operator_priority["_::_"]
		else
			return math.huge
		end
	end,

	traverse = function(self, fn, ...)
		fn(self.identifier, ...)
		if self.default then fn(self.default, ...) end
		if self.value_check then fn(self.value_check, ...) end
	end,

	_eval = function(self, state)
		return FunctionParameter:new(self.identifier, self.default, self.value_check and self.value_check:eval(state))
	end
}

return FunctionParameter
