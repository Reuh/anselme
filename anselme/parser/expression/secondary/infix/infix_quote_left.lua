local infix = require("anselme.parser.expression.secondary.infix.infix")

local ast = require("anselme.ast")
local Call, Identifier, ArgumentTuple, Quote = ast.Call, ast.Identifier, ast.ArgumentTuple, ast.Quote

return infix {
	build_ast = function(self, left, right)
		left = Quote:new(left)
		return Call:new(Identifier:new(self.identifier), ArgumentTuple:new(left, right))
	end
}
