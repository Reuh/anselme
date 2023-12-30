local ast = require("anselme.ast")

local operator_priority = require("anselme.common").operator_priority

return ast.abstract.Runtime {
	type = "pair",

	name = nil,
	value = nil,

	init = function(self, name, value)
		self.name = name
		self.value = value
	end,

	traverse = function(self, fn, ...)
		fn(self.name, ...)
		fn(self.value, ...)
	end,

	_format = function(self, ...)
		return ("%s:%s"):format(self.name:format(...), self.value:format(...))
	end,
	_format_priority = function(self)
		return operator_priority["_:_"]
	end,
}
