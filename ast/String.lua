local ast = require("ast")
local Identifier

local String = ast.abstract.Node {
	type = "string",
	_evaluated = true, -- no evaluation needed

	string = nil,

	init = function(self, str)
		self.string = str
	end,

	_hash = function(self)
		return ("string<%q>"):format(self.string)
	end,

	_format = function(self)
		return ("%q"):format(self.string)
	end,

	to_lua = function(self, state)
		return self.string
	end,

	to_identifier = function(self)
		return Identifier:new(self.string)
	end
}

package.loaded[...] = String
Identifier = ast.Identifier

return String
