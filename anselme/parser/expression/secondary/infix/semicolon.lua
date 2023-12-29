local infix_or_suffix = require("anselme.parser.expression.secondary.infix.infix_or_suffix")

local operator_priority = require("anselme.common").operator_priority

return infix_or_suffix {
	operator = ";",
	identifier = "_;_",
	priority = operator_priority["_;_"]
}
