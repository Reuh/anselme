local primary = require("parser.expression.primary.primary")
local tuple = require("parser.expression.primary.tuple")

local ast = require("ast")
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
