-- called automatically when returned by one of the expression in a block

local ast = require("anselme.ast")

return ast.abstract.Node {
	type = "auto call",
	init = false
}