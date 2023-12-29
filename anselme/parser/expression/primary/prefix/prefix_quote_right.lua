local prefix = require("anselme.parser.expression.primary.prefix.prefix")

local ast = require("anselme.ast")
local Call, Identifier, ArgumentTuple, Quote = ast.Call, ast.Identifier, ast.ArgumentTuple, ast.Quote

return prefix {
	build_ast = function(self, right)
		right = Quote:new(right)
		return Call:new(Identifier:new(self.identifier), ArgumentTuple:new(right))
	end
}
