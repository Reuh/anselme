local prefix_maybe_nil_right = require("parser.expression.primary.prefix.prefix_maybe_nil_right")

local ast = require("ast")
local Return = ast.Return

local operator_priority = require("common").operator_priority

return prefix_maybe_nil_right {
	operator = "@",
	priority = operator_priority["@_"],

	build_ast = function(self, right)
		return Return:new(right)
	end
}
