local infix_quote_both = require("parser.expression.secondary.infix.infix_quote_both")

local operator_priority = require("common").operator_priority

return infix_quote_both {
	operator = "->",
	identifier = "_->_",
	priority = operator_priority["_->_"]
}
