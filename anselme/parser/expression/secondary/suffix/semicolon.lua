local suffix = require("anselme.parser.expression.secondary.suffix.suffix")

local operator_priority = require("anselme.common").operator_priority

return suffix {
	operator = ";",
	identifier = "_;",
	priority = operator_priority["_;"]
}
