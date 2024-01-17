local infix_or_suffix = require("anselme.parser.expression.secondary.infix.infix_or_suffix")
local operator_priority = require("anselme.common").operator_priority

local ast = require("anselme.ast")
local Block = ast.Block

return infix_or_suffix {
	operator = ";",
	identifier = "_;_",
	priority = operator_priority["_;_"],

	build_ast = function(self, left, right)
		if Block:is(left) then
			left:add(right)
		else
			return Block:new(left, right)
		end
	end
}
