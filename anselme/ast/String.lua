local ast = require("anselme.ast")
local Identifier, Symbol

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
		return ("\"%s\""):format(self.string:gsub("[\n\t\"]", { ["\n"] = "\\n", ["\t"] = "\\t", ["\""] = "\\\"" }))
	end,

	to_lua = function(self, state)
		return self.string
	end,

	to_identifier = function(self)
		return Identifier:new(self.string)
	end,
	to_symbol = function(self)
		return Symbol:new(self.string)
	end
}

package.loaded[...] = String
Identifier, Symbol = ast.Identifier, ast.Symbol

return String
