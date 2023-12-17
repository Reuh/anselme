local prefix = require("parser.expression.primary.prefix.prefix")

local operator_priority = require("common").operator_priority

return prefix {
	operator = "!",
	identifier = "!_",
	priority = operator_priority["!_"]
}
