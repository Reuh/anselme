local infix = require("parser.expression.secondary.infix.infix")
local escape = require("common").escape

local operator_priority = require("common").operator_priority

local ast = require("ast")
local Call = ast.Call

return infix {
	operator = "=",
	identifier = "_=_",
	priority = operator_priority["_=_"],

	-- return bool
	match = function(self, str, current_priority, primary)
		local escaped = escape(self.operator)
		return self.priority > current_priority and str:match("^"..escaped) and Call:is(primary)
	end,

	build_ast = function(self, left, right)
		left.arguments:set_assignment(right)
		return Call:new(left.func, left.arguments) -- recreate Call since we modified left.arguments
	end,
}
