local ast = require("ast")

local operator_priority = require("common").operator_priority

return ast.abstract.Runtime {
	type = "pair",

	name = nil,
	value = nil,
	format_priority = operator_priority["_:_"],

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
}
