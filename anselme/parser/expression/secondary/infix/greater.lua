local infix = require("anselme.parser.expression.secondary.infix.infix")

local operator_priority = require("anselme.common").operator_priority

return infix {
	operator = ">",
	identifier = "_>_",
	priority = operator_priority["_>_"]
}
