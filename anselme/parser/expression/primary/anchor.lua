local primary = require("anselme.parser.expression.primary.primary")

local identifier = require("anselme.parser.expression.primary.identifier")

local ast = require("anselme.ast")
local Anchor = ast.Anchor

return primary {
	match = function(self, str)
		if str:match("^#") then
			return identifier:match(str:match("^#(.-)$"))
		end
		return false
	end,

	parse = function(self, source, str)
		local start_source = source:clone()
		local rem = source:consume(str:match("^(#)(.-)$"))

		local ident
		ident, rem = identifier:parse(source, rem)

		return Anchor:new(ident.name):set_source(start_source), rem
	end
}
