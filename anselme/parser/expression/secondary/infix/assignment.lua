local infix_quote_left = require("anselme.parser.expression.secondary.infix.infix_quote_left")
local escape = require("anselme.common").escape

local operator_priority = require("anselme.common").operator_priority

return infix_quote_left {
	operator = "=",
	identifier = "_=_",
	priority = operator_priority["_=_"],

	-- return bool
	match = function(self, str, current_priority, primary)
		local escaped = escape(self.operator)
		return self.priority > current_priority and str:match("^"..escaped)
	end,
}
