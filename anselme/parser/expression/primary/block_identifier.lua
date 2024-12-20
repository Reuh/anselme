local primary = require("anselme.parser.expression.primary.primary")

local ast = require("anselme.ast")
local Identifier, Call, ArgumentTuple = ast.Identifier, ast.Call, ast.ArgumentTuple

return primary {
	match = function(self, str)
		return str:match("^_")
	end,

	parse = function(self, source, options, str)
		local source_start = source:clone()
		local rem = source:consume(str:match("^(_)(.-)$"))
		return Call:new(Identifier:new("_"), ArgumentTuple:new()):set_source(source_start), rem
	end
}
