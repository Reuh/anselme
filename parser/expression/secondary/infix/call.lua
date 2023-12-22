local infix = require("parser.expression.secondary.infix.infix")
local escape = require("common").escape
local identifier = require("parser.expression.primary.identifier")

local operator_priority = require("common").operator_priority

local ast = require("ast")
local Call, ArgumentTuple = ast.Call, ast.ArgumentTuple

return infix {
	operator = "!",
	identifier = "_!_",
	priority = operator_priority["_!_"],

	match = function(self, str, current_priority, primary)
		local escaped = escape(self.operator)
		return self.priority > current_priority and str:match("^"..escaped) and identifier:match(str:match("^"..escaped.."%s*(.-)$"))
	end,

	build_ast = function(self, left, right)
		if Call:is(right) then
			return Call:new(right.func, right.arguments:with_first_argument(left))
		else
			return Call:new(right, ArgumentTuple:new(left))
		end
	end
}
