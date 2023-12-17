local suffix = require("parser.expression.secondary.suffix.suffix")

local operator_priority = require("common").operator_priority

return suffix {
	operator = ";",
	identifier = "_;",
	priority = operator_priority["_;"]
}
