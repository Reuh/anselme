local infix = require("parser.expression.secondary.infix.infix")

local operator_priority = require("common").operator_priority

return infix {
	operator = "::",
	identifier = "_::_",
	priority = operator_priority["_::_"]
}
