local prefix = require("parser.expression.primary.prefix.prefix")

local ast = require("ast")
local Return = ast.Return

local operator_priority = require("common").operator_priority

return prefix {
	operator = "@",
	priority = operator_priority["@_"],

	build_ast = function(self, right)
		return Return:new(right)
	end
}
