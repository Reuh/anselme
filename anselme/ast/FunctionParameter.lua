local ast = require("anselme.ast")
local operator_priority = require("anselme.common").operator_priority

local FunctionParameter
FunctionParameter = ast.abstract.Node {
	type = "function parameter",

	identifier = nil,
	default = nil, -- can be nil
	type_check = nil, -- can be nil

	init = function(self, identifier, default, type_check)
		self.identifier = identifier
		self.default = default
		self.type_check = type_check
		if default then
			self.format_priority = operator_priority["_=_"]
		elseif type_check then -- type_check has higher prio than assignment in any case
			self.format_priority = operator_priority["_::_"]
		end
	end,

	_format = function(self, state, prio, ...)
		local s = self.identifier:format(state, prio, ...)
		if self.type_check then
			s = s .. "::" .. self.type_check:format_right(state, operator_priority["_::_"], ...)
		end
		if self.default then
			s = s .. "=" .. self.default:format_right(state, operator_priority["_=_"], ...)
		end
		return s
	end,

	traverse = function(self, fn, ...)
		fn(self.identifier, ...)
		if self.default then fn(self.default, ...) end
		if self.type_check then fn(self.type_check, ...) end
	end,

	_eval = function(self, state)
		return FunctionParameter:new(self.identifier, self.default, self.type_check and self.type_check:eval(state))
	end
}

return FunctionParameter
