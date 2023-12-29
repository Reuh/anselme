local infix_quote_both = require("anselme.parser.expression.secondary.infix.infix_quote_both")

local operator_priority = require("anselme.common").operator_priority

return infix_quote_both {
	operator = "~?",
	identifier = "_~?_",
	priority = operator_priority["_~?_"]
}
