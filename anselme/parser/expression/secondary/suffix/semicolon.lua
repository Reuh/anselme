local suffix = require("anselme.parser.expression.secondary.suffix.suffix")
local operator_priority = require("anselme.common").operator_priority

local ast = require("anselme.ast")
local Block, Nil = ast.Block, ast.Nil

return suffix {
	operator = ";",
	identifier = "_;",
	priority = operator_priority["_;"],

	build_ast = function(self, left)
		if Block:is(left) then
			left:add(Nil:new())
		else
			return Block:new(left, Nil:new())
		end
	end
}
