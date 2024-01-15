local primary = require("anselme.parser.expression.primary.primary")

local ast = require("anselme.ast")
local Identifier, Call, ArgumentTuple = ast.Identifier, ast.Call, ast.ArgumentTuple

return primary {
	match = function(self, str)
		return str:match("^\n")
	end,

	parse = function(self, source, options, str)
		-- implicit _, do not consume the newline
		local r = Call:new(Identifier:new("_"), ArgumentTuple:new()):set_source(source)
		r.explicit = false
		return r, str
	end
}
