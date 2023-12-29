local ast = require("anselme.ast")

return ast.abstract.Node {
	type = "boolean",
	_evaluated = true, -- no evaluation needed

	value = nil,

	init = function(self, val)
		self.value = val
	end,

	_hash = function(self)
		return ("boolean<%q>"):format(self.value)
	end,

	_format = function(self)
		return tostring(self.value)
	end,

	to_lua = function(self, state)
		return self.value
	end,

	truthy = function(self)
		return self.value
	end
}
