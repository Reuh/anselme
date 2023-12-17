local ast = require("ast")

local Number
Number = ast.abstract.Node {
	type = "number",
	_evaluated = true, -- no evaluation needed

	number = nil,

	init = function(self, number)
		self.number = number
	end,

	_hash = function(self)
		return ("number<%s>"):format(self.number)
	end,

	_format = function(self)
		return tostring(self.number)
	end,

	to_lua = function(self, state) return self.number end,
}

return Number
