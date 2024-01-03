local ast = require("anselme.ast")

return ast.abstract.Runtime {
	type = "undefined",

	init = function(self) end,

	_format = function(self)
		return "<undefined>"
	end,

	truthy = function(self) return false end
}
