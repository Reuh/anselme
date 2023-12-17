local infix_quote_right = require("parser.expression.secondary.infix.infix_quote_right")

local operator_priority = require("common").operator_priority

return infix_quote_right {
	operator = "~",
	identifier = "_~_",
	priority = operator_priority["_~_"]
}
