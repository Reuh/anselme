local ast = require("anselme.ast")

local Anchor
Anchor = ast.abstract.ResumeTarget {
	type = "anchor",

	name = nil,

	init = function(self, name)
		self.name = name
	end,

	_hash = function(self)
		return ("anchor<%q>"):format(self.name)
	end,

	_format = function(self, ...)
		return "#"..self.name
	end,
}

package.loaded[...] = Anchor

return Anchor
