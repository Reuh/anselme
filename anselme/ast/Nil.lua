local ast = require("anselme.ast")

return ast.abstract.Node {
	type = "nil",
	_evaluated = true, -- no evaluation needed

	init = function(self) end,

	_hash = function(self)
		return "nil"
	end,

	_format = function(self)
		return "()"
	end,

	to_lua = function(self, state) return nil end,

	truthy = function(self) return false end
}
