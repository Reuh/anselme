local ast = require("anselme.ast")
local Symbol, String

local Identifier
Identifier = ast.abstract.Node {
	type = "identifier",

	name = nil,

	init = function(self, name)
		self.name = name
	end,

	_hash = function(self)
		return ("identifier<%q>"):format(self.name)
	end,

	_format = function(self)
		return self.name
	end,

	_eval = function(self, state)
		return state.scope:get(self)
	end,

	to_string = function(self)
		return String:new(self.name)
	end,
	to_symbol = function(self, modifiers)
		return Symbol:new(self.name, modifiers)
	end,
}

package.loaded[...] = Identifier

Symbol, String = ast.Symbol, ast.String

return Identifier
