local primary = require("anselme.parser.expression.primary.primary")
local tuple = require("anselme.parser.expression.primary.tuple")

local ast = require("anselme.ast")
local Struct = ast.Struct

return primary {
	match = function(self, str)
		return str:match("^%{")
	end,

	parse = function(self, source, str)
		local l, rem = tuple:parse_tuple(source, str, "{", '}')

		return Struct:from_tuple(l), rem
	end
}
