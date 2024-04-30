local primary = require("anselme.parser.expression.primary.primary")

local ast = require("anselme.ast")
local Flush = ast.Flush

return primary {
	match = function(self, str)
		return str:match("^%-%-%-")
	end,

	parse = function(self, source, options, str)
		local start_source = source:clone()
		local rem = source:consume(str:match("^(%-%-%-)(.-)$"))
		return Flush:new():set_source(start_source), rem
	end
}
