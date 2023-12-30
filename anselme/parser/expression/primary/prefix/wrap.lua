local prefix_quote_right = require("anselme.parser.expression.primary.prefix.prefix_quote_right")

local operator_priority = require("anselme.common").operator_priority

return prefix_quote_right {
	operator = ">",
	identifier = ">_",
	priority = operator_priority[">_"]
}
