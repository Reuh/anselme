local prefix = require("anselme.parser.expression.primary.prefix.prefix")

local operator_priority = require("anselme.common").operator_priority

return prefix {
	operator = ";",
	identifier = ";_",
	priority = operator_priority[";_"],

	build_ast = function(self, right)
		return right
	end
}
